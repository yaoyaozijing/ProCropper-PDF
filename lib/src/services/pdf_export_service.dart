import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../l10n/app_localizations.dart';
import '../models/crop_rect.dart';
import '../models/pdf_project.dart';
import 'cache_service.dart';

class PdfExportService {
  static const MethodChannel _documentsChannel =
      MethodChannel('procropper_pdf/android_documents');
  final CacheService _cacheService = CacheService();

  Future<String> export({
    required PdfProject project,
    required Map<int, List<CropRect>> pageCropMap,
    String? destinationPath,
    String? destinationUri,
    void Function(double progress, String message)? onProgress,
  }) async {
    final cleanupTemporaryOutput = destinationUri != null;
    final effectiveOutputPath = destinationUri == null
        ? (destinationPath ?? _defaultOutputPath(project.filePath))
        : await createTemporaryExportPath(project.filePath);
    final outputPath = effectiveOutputPath;
    final receivePort = ReceivePort();
    final request = <String, Object?>{
      'replyPort': receivePort.sendPort,
      'sourcePath': project.filePath,
      'outputPath': outputPath,
      'pageCropMap': _serializePageCropMap(pageCropMap),
    };

    final completer = Completer<String>();
    late final StreamSubscription<dynamic> subscription;
    subscription = receivePort.listen((message) {
      if (message is! Map) {
        return;
      }
      final type = message['type'];
      if (type == 'progress') {
        onProgress?.call(
          (message['progress'] as num).toDouble(),
          message['message'] as String,
        );
        return;
      }
      if (type == 'done') {
        completer.complete(message['outputPath'] as String);
        return;
      }
      if (type == 'error') {
        completer.completeError(
          Exception(message['error'] as String),
          StackTrace.fromString(message['stackTrace'] as String),
        );
      }
    });

    try {
      await Isolate.spawn(_runExportInIsolate, request);
      final generatedPath = await completer.future;
      if (destinationUri != null) {
        onProgress?.call(0.995, AppLocalizations.current.writingSelectedLocation);
        await _writeFileToUri(destinationUri, generatedPath);
        return destinationUri;
      }
      return generatedPath;
    } finally {
      if (cleanupTemporaryOutput) {
        try {
          await deleteTemporaryExport(outputPath);
        } catch (_) {
          // Ignore temp file cleanup failure.
        }
      }
      await subscription.cancel();
      receivePort.close();
    }
  }

  Future<String?> createDocumentUri({
    required String fileName,
    String mimeType = 'application/pdf',
  }) async {
    if (!Platform.isAndroid) {
      return null;
    }
    final uri = await _documentsChannel.invokeMethod<String>(
      'createDocument',
      <String, Object?>{
        'fileName': fileName,
        'mimeType': mimeType,
      },
    );
    return uri;
  }

  String _defaultOutputPath(String inputPath) {
    final dir = p.dirname(inputPath);
    final ext = p.extension(inputPath);
    final base = p.basenameWithoutExtension(inputPath);
    return p.join(dir, '${base}_cropped$ext');
  }

  Future<String> createTemporaryExportPath(String inputPath) async {
    final exportDir = await _cacheService.getExportCacheDirectory();
    return p.join(
      exportDir.path,
      '${p.basenameWithoutExtension(inputPath)}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  Future<void> deleteTemporaryExport(String path) {
    return _cacheService.deleteTemporaryFile(path);
  }

  List<Map<String, Object>> _serializePageCropMap(Map<int, List<CropRect>> pageCropMap) {
    final entries = <Map<String, Object>>[];
    final sortedPages = pageCropMap.keys.toList()..sort();
    for (final pageNumber in sortedPages) {
      final rects = pageCropMap[pageNumber] ?? const <CropRect>[];
      entries.add({
        'pageNumber': pageNumber,
        'rects': rects
            .map(
              (rect) => <double>[
                rect.left,
                rect.top,
                rect.right,
                rect.bottom,
              ],
            )
            .toList(growable: false),
      });
    }
    return entries;
  }

  Future<void> _writeFileToUri(String destinationUri, String sourcePath) async {
    await _documentsChannel.invokeMethod<void>(
      'writeDocumentFromPath',
      <String, Object?>{
        'uri': destinationUri,
        'sourcePath': sourcePath,
      },
    );
  }
}

Future<void> _runExportInIsolate(Map<String, Object?> request) async {
  final replyPort = request['replyPort']! as SendPort;
  final sourcePath = request['sourcePath']! as String;
  final outputPath = request['outputPath']! as String;
  final rawEntries = request['pageCropMap']! as List<dynamic>;
  final pageCropMap = <int, List<CropRect>>{};

  for (final entry in rawEntries) {
    final item = entry as Map<dynamic, dynamic>;
    final pageNumber = item['pageNumber'] as int;
    final rects = (item['rects'] as List<dynamic>).map((rawRect) {
      final values = (rawRect as List<dynamic>).cast<num>();
      return CropRect(
        left: values[0].toDouble(),
        top: values[1].toDouble(),
        right: values[2].toDouble(),
        bottom: values[3].toDouble(),
      ).normalized();
    }).toList(growable: false);
    pageCropMap[pageNumber] = rects;
  }

  replyPort.send({
    'type': 'progress',
    'progress': 0.0,
    'message': AppLocalizations.current.readingSourceFile,
  });

  final sourceBytes = await File(sourcePath).readAsBytes();
  final sourceDocument = PdfDocument(inputBytes: sourceBytes);
  final outputDocument = PdfDocument();

  try {
    outputDocument.pageSettings.margins.all = 0;
    final pageCount = sourceDocument.pages.count;
    for (var index = 0; index < pageCount; index++) {
      final sourcePage = sourceDocument.pages[index];
      final cropRects = pageCropMap[index + 1] ?? const <CropRect>[CropRect.full];
      final template = sourcePage.createTemplate();
      final baseSize = sourcePage.size;

      for (final cropRect in cropRects.where((rect) => rect.isValid)) {
        final cropBox = _cropToSourceRectInIsolate(cropRect, baseSize);
        final section = outputDocument.sections!.add();
        section.pageSettings = PdfPageSettings(
          Size(cropBox.width, cropBox.height),
          cropBox.width >= cropBox.height
              ? PdfPageOrientation.landscape
              : PdfPageOrientation.portrait,
        );
        section.pageSettings.margins.all = 0;
        final newPage = section.pages.add();
        newPage.graphics.drawPdfTemplate(
          template,
          Offset(-cropBox.left, -cropBox.top),
          Size(baseSize.width, baseSize.height),
        );
      }

      replyPort.send({
        'type': 'progress',
        'progress': ((index + 1) / pageCount) * 0.92,
        'message': AppLocalizations.current.processingPage(index + 1, pageCount),
      });
    }

    replyPort.send({
      'type': 'progress',
      'progress': 0.96,
      'message': AppLocalizations.current.generatingExportFile,
    });
    final bytes = await outputDocument.save();
    replyPort.send({
      'type': 'progress',
      'progress': 0.99,
      'message': AppLocalizations.current.writingToDisk,
    });
    await File(outputPath).writeAsBytes(bytes, flush: true);
    replyPort.send({
      'type': 'done',
      'outputPath': outputPath,
    });
  } catch (error, stackTrace) {
    replyPort.send({
      'type': 'error',
      'error': error.toString(),
      'stackTrace': stackTrace.toString(),
    });
  } finally {
    sourceDocument.dispose();
    outputDocument.dispose();
  }
}

Rect _cropToSourceRectInIsolate(CropRect rect, Size pageSize) {
  final left = rect.left * pageSize.width;
  final top = rect.top * pageSize.height;
  final right = rect.right * pageSize.width;
  final bottom = rect.bottom * pageSize.height;
  return Rect.fromLTRB(
    math.min(left, right),
    math.min(top, bottom),
    math.max(left, right),
    math.max(top, bottom),
  );
}

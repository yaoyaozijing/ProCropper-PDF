import 'dart:io';

import 'package:flutter/services.dart';

class AndroidTreePdfFile {
  const AndroidTreePdfFile({
    required this.uri,
    required this.fileName,
    required this.relativeDirectory,
  });

  final String uri;
  final String fileName;
  final String relativeDirectory;
}

class AndroidDocumentTreeService {
  static const MethodChannel _channel =
      MethodChannel('procropper_pdf/android_documents');

  bool get isSupported => Platform.isAndroid;

  Future<String?> pickDirectoryTree() async {
    if (!isSupported) {
      return null;
    }
    return _channel.invokeMethod<String>('pickDirectoryTree');
  }

  Future<List<AndroidTreePdfFile>> listPdfFilesInTree({
    required String treeUri,
    required bool recursive,
  }) async {
    if (!isSupported) {
      return const <AndroidTreePdfFile>[];
    }

    final rawFiles =
        await _channel.invokeListMethod<Object?>(
          'listPdfFilesInTree',
          <String, Object?>{
            'treeUri': treeUri,
            'recursive': recursive,
          },
        ) ??
        const <Object?>[];

    return rawFiles
        .whereType<Map<Object?, Object?>>()
        .map((item) {
          final uri = item['uri'] as String? ?? '';
          final fileName = item['name'] as String? ?? 'document.pdf';
          final relativeDirectory =
              item['relativeDirectory'] as String? ?? '';
          return AndroidTreePdfFile(
            uri: uri,
            fileName: fileName,
            relativeDirectory: _normalizeRelativeDirectory(relativeDirectory),
          );
        })
        .where((file) => file.uri.isNotEmpty && file.fileName.isNotEmpty)
        .toList(growable: false);
  }

  Future<String?> copyTreeFileToCache({
    required String documentUri,
    required String fileName,
  }) async {
    if (!isSupported) {
      return null;
    }
    return _channel.invokeMethod<String>(
      'copyTreeFileToCache',
      <String, Object?>{
        'uri': documentUri,
        'fileName': fileName,
      },
    );
  }

  Future<void> writeFileToTree({
    required String treeUri,
    required String relativeDirectory,
    required String fileName,
    required String sourcePath,
  }) {
    if (!isSupported) {
      return Future<void>.value();
    }
    return _channel.invokeMethod<void>(
      'writeFileToTree',
      <String, Object?>{
        'treeUri': treeUri,
        'relativeDirectory': _normalizeRelativeDirectory(relativeDirectory),
        'fileName': fileName,
        'sourcePath': sourcePath,
      },
    );
  }

  String _normalizeRelativeDirectory(String relativeDirectory) {
    final normalized = relativeDirectory
        .replaceAll('\\', '/')
        .trim()
        .replaceAll(RegExp(r'/+'), '/');
    if (normalized.isEmpty || normalized == '.') {
      return '';
    }
    return normalized.startsWith('/') ? normalized.substring(1) : normalized;
  }
}

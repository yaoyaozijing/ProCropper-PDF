import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:image/image.dart' as img;
import 'package:pdfrx/pdfrx.dart';

class PreviewMergeResult {
  const PreviewMergeResult({
    required this.pngBytes,
    required this.size,
    required this.bgraBytes,
    required this.width,
    required this.height,
  });

  final Uint8List pngBytes;
  final Size size;
  final Uint8List bgraBytes;
  final int width;
  final int height;
}

class PreviewMergeService {
  static const double _identicalPixelsThreshold = 0.8;

  static Future<PreviewMergeResult> buildClusterPreview({
    required PdfDocument document,
    required List<int> pageNumbers,
    required double pageWidth,
    required double pageHeight,
    int targetWidth = 900,
  }) async {
    final renderWidth = targetWidth.toDouble();
    final renderHeight = math.max(1, (targetWidth * pageHeight / pageWidth).round()).toDouble();
    final pixelCount = targetWidth * renderHeight.toInt();
    final sum = List<int>.filled(pixelCount, 0);
    final sumSquares = List<int>.filled(pixelCount, 0);
    final fallbackOverlay = List<int>.filled(pixelCount, 255);
    var renderedCount = 0;

    for (final pageNumber in pageNumbers) {
      final page = document.pages[pageNumber - 1];
      final image = await page.render(
        fullWidth: renderWidth,
        fullHeight: renderHeight,
      );
      if (image == null) {
        continue;
      }
      try {
        final pixels = image.pixels;
        for (var i = 0; i < pixelCount; i++) {
          final pixelOffset = i * 4;
          final b = pixels[pixelOffset];
          final g = pixels[pixelOffset + 1];
          final r = pixels[pixelOffset + 2];
          final grayscale = ((r * 299) + (g * 587) + (b * 114)) ~/ 1000;
          sum[i] += grayscale;
          sumSquares[i] += grayscale * grayscale;
          if (grayscale < fallbackOverlay[i]) {
            fallbackOverlay[i] = grayscale;
          }
        }
        renderedCount++;
      } finally {
        image.dispose();
      }
    }

    if (renderedCount == 0) {
      final fallback = img.Image(width: targetWidth, height: renderHeight.toInt());
      final png = Uint8List.fromList(img.encodePng(fallback));
      return PreviewMergeResult(
        pngBytes: png,
        size: Size(targetWidth.toDouble(), renderHeight),
        bgraBytes: Uint8List(targetWidth * renderHeight.toInt() * 4),
        width: targetWidth,
        height: renderHeight.toInt(),
      );
    }

    final merged = img.Image(width: targetWidth, height: renderHeight.toInt());
    final mergedBgra = Uint8List(merged.width * merged.height * 4);
    final overlay = _buildOverlay(
      sum: sum,
      sumSquares: sumSquares,
      fallbackOverlay: fallbackOverlay,
      pixelCount: pixelCount,
      renderedCount: renderedCount,
    );

    for (var y = 0; y < merged.height; y++) {
      for (var x = 0; x < merged.width; x++) {
        final index = y * merged.width + x;
        final pixelOffset = index * 4;
        final grayscale = overlay[index];
        mergedBgra[pixelOffset] = grayscale;
        mergedBgra[pixelOffset + 1] = grayscale;
        mergedBgra[pixelOffset + 2] = grayscale;
        mergedBgra[pixelOffset + 3] = 255;
        merged.setPixelRgb(x, y, grayscale, grayscale, grayscale);
      }
    }

    final pngBytes = Uint8List.fromList(img.encodePng(merged));
    return PreviewMergeResult(
      pngBytes: pngBytes,
      size: Size(merged.width.toDouble(), merged.height.toDouble()),
      bgraBytes: mergedBgra,
      width: merged.width,
      height: merged.height,
    );
  }

  static List<int> _buildOverlay({
    required List<int> sum,
    required List<int> sumSquares,
    required List<int> fallbackOverlay,
    required int pixelCount,
    required int renderedCount,
  }) {
    if (renderedCount <= 1) {
      return fallbackOverlay;
    }

    final overlay = List<int>.filled(pixelCount, 255);
    var identicalPixels = 0;
    var whitePixels = 0;

    for (var i = 0; i < pixelCount; i++) {
      final mean = sum[i] / renderedCount;
      final varianceNumerator = sumSquares[i] - ((sum[i] * sum[i]) / renderedCount);
      final variance = math.max(0.0, varianceNumerator / (renderedCount - 1));
      final sd = 255 - math.sqrt(variance).round();
      final clamped = sd.clamp(0, 255);
      overlay[i] = clamped;

      if (mean < 255) {
        if (clamped == 255) {
          identicalPixels++;
        }
      } else {
        whitePixels++;
      }
    }

    if (identicalPixels > (pixelCount * _identicalPixelsThreshold) - whitePixels) {
      return fallbackOverlay;
    }

    return overlay;
  }
}

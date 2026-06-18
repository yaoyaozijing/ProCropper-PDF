import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pdfrx/pdfrx.dart';

import '../models/crop_rect.dart';

class AutoCropService {
  static Future<CropRect> detectForPage(
    PdfPage page, {
    int targetLongSide = 900,
  }) async {
    final scale = targetLongSide / math.max(page.width, page.height);
    final fullWidth = math.max(1, (page.width * scale).round()).toDouble();
    final fullHeight = math.max(1, (page.height * scale).round()).toDouble();
    final image = await page.render(
      fullWidth: fullWidth,
      fullHeight: fullHeight,
    );

    if (image == null) {
      return CropRect.full;
    }

    try {
      final width = image.width;
      final height = image.height;
      final pixels = image.pixels;
      final rows = List<double>.filled(height, 255);
      final cols = List<double>.filled(width, 255);

      for (var y = 0; y < height; y++) {
        var rowMin = 255.0;
        final rowOffset = y * width * 4;
        for (var x = 0; x < width; x++) {
          final i = rowOffset + x * 4;
          final b = pixels[i];
          final g = pixels[i + 1];
          final r = pixels[i + 2];
          final luminance = (r * 0.299) + (g * 0.587) + (b * 0.114);
          if (luminance < rowMin) {
            rowMin = luminance;
          }
          if (luminance < cols[x]) {
            cols[x] = luminance;
          }
        }
        rows[y] = rowMin;
      }

      final threshold = _adaptiveThreshold([...rows, ...cols]);
      final left = _findStart(cols, threshold);
      final right = _findEnd(cols, threshold);
      final top = _findStart(rows, threshold);
      final bottom = _findEnd(rows, threshold);

      final crop = CropRect(
        left: left / width,
        top: top / height,
        right: (right + 1) / width,
        bottom: (bottom + 1) / height,
      ).normalized();

      return crop.isValid ? _expandSlightly(crop) : CropRect.full;
    } finally {
      image.dispose();
    }
  }

  static CropRect detectFromBgraPixels({
    required Uint8List pixels,
    required int width,
    required int height,
  }) {
    final rows = List<double>.filled(height, 255);
    final cols = List<double>.filled(width, 255);

    for (var y = 0; y < height; y++) {
      var rowMin = 255.0;
      final rowOffset = y * width * 4;
      for (var x = 0; x < width; x++) {
        final i = rowOffset + x * 4;
        final b = pixels[i];
        final g = pixels[i + 1];
        final r = pixels[i + 2];
        final luminance = (r * 0.299) + (g * 0.587) + (b * 0.114);
        if (luminance < rowMin) {
          rowMin = luminance;
        }
        if (luminance < cols[x]) {
          cols[x] = luminance;
        }
      }
      rows[y] = rowMin;
    }

    final threshold = _adaptiveThreshold([...rows, ...cols]);
    final left = _findStart(cols, threshold);
    final right = _findEnd(cols, threshold);
    final top = _findStart(rows, threshold);
    final bottom = _findEnd(rows, threshold);

    final crop = CropRect(
      left: left / width,
      top: top / height,
      right: (right + 1) / width,
      bottom: (bottom + 1) / height,
    ).normalized();

    return crop.isValid ? _expandSlightly(crop) : CropRect.full;
  }

  static double _adaptiveThreshold(List<double> values) {
    final sorted = [...values]..sort();
    final dark = sorted[(sorted.length * 0.08).floor()];
    final bright = sorted[(sorted.length * 0.9).floor()];
    return bright - ((bright - dark) * 0.12);
  }

  static int _findStart(List<double> values, double threshold) {
    for (var i = 0; i < values.length; i++) {
      if (values[i] < threshold) {
        return i;
      }
    }
    return 0;
  }

  static int _findEnd(List<double> values, double threshold) {
    for (var i = values.length - 1; i >= 0; i--) {
      if (values[i] < threshold) {
        return i;
      }
    }
    return values.length - 1;
  }

  static CropRect _expandSlightly(CropRect rect) {
    const padding = 0.008;
    return CropRect(
      left: rect.left - padding,
      top: rect.top - padding,
      right: rect.right + padding,
      bottom: rect.bottom + padding,
    ).normalized();
  }
}

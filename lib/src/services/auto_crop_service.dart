import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pdfrx/pdfrx.dart';

import '../models/cluster_settings.dart';
import '../models/crop_rect.dart';

class AutoCropService {
  static Future<CropRect> detectForPage(
    PdfPage page, {
    int targetLongSide = 900,
    EdgeFilterSettings edgeFilter = const EdgeFilterSettings(),
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
      return detectFromBgraPixels(
        pixels: image.pixels,
        width: image.width,
        height: image.height,
        edgeFilter: edgeFilter,
      );
    } finally {
      image.dispose();
    }
  }

  static CropRect detectFromBgraPixels({
    required Uint8List pixels,
    required int width,
    required int height,
    EdgeFilterSettings edgeFilter = const EdgeFilterSettings(),
  }) {
    final rows = List<double>.filled(height, 255);
    final cols = List<double>.filled(width, 255);
    final filterBounds = _resolveFilterBounds(width, height, edgeFilter);

    for (var y = 0; y < height; y++) {
      if (y < filterBounds.top || y > filterBounds.bottom) {
        continue;
      }
      var rowMin = 255.0;
      final rowOffset = y * width * 4;
      for (var x = filterBounds.left; x <= filterBounds.right; x++) {
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

    final filteredRows = rows.sublist(filterBounds.top, filterBounds.bottom + 1);
    final filteredCols = cols.sublist(filterBounds.left, filterBounds.right + 1);
    final threshold = _adaptiveThreshold([...filteredRows, ...filteredCols]);
    final left = _findStart(filteredCols, threshold) + filterBounds.left;
    final right = _findEnd(filteredCols, threshold) + filterBounds.left;
    final top = _findStart(filteredRows, threshold) + filterBounds.top;
    final bottom = _findEnd(filteredRows, threshold) + filterBounds.top;

    final crop = CropRect(
      left: left / width,
      top: top / height,
      right: (right + 1) / width,
      bottom: (bottom + 1) / height,
    ).normalized();

    return crop.isValid ? _expandSlightly(crop) : CropRect.full;
  }

  static _FilterBounds _resolveFilterBounds(
    int width,
    int height,
    EdgeFilterSettings edgeFilter,
  ) {
    final left = (edgeFilter.left.clamp(0.0, 0.45) * width).floor();
    final top = (edgeFilter.top.clamp(0.0, 0.45) * height).floor();
    final right = width - 1 - (edgeFilter.right.clamp(0.0, 0.45) * width).floor();
    final bottom = height - 1 - (edgeFilter.bottom.clamp(0.0, 0.45) * height).floor();
    return _FilterBounds(
      left: math.min(left, math.max(0, right)),
      top: math.min(top, math.max(0, bottom)),
      right: math.max(right, 0),
      bottom: math.max(bottom, 0),
    );
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

class _FilterBounds {
  const _FilterBounds({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final int left;
  final int top;
  final int right;
  final int bottom;
}

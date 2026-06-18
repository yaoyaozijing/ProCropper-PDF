import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pdfrx/pdfrx.dart';

import '../models/cluster_settings.dart';
import '../models/crop_rect.dart';

class PageAnalysis {
  const PageAnalysis({
    required this.pageNumber,
    required this.pageWidth,
    required this.pageHeight,
    required this.fingerprint,
    required this.suggestedCrop,
    required this.layoutLabel,
  });

  final int pageNumber;
  final double pageWidth;
  final double pageHeight;
  final PageFingerprint fingerprint;
  final CropRect suggestedCrop;
  final String layoutLabel;
}

class PageFingerprint {
  const PageFingerprint({
    required this.inkRatio,
    required this.headerDensity,
    required this.footerDensity,
    required this.leftDensity,
    required this.rightDensity,
    required this.centerX,
    required this.centerY,
    required this.contentBounds,
    required this.rowProfile,
    required this.columnProfile,
  });

  final double inkRatio;
  final double headerDensity;
  final double footerDensity;
  final double leftDensity;
  final double rightDensity;
  final double centerX;
  final double centerY;
  final CropRect contentBounds;
  final List<double> rowProfile;
  final List<double> columnProfile;

  double distanceTo(PageFingerprint other) {
    final boundsDistance =
        (contentBounds.left - other.contentBounds.left).abs() +
        (contentBounds.top - other.contentBounds.top).abs() +
        (contentBounds.right - other.contentBounds.right).abs() +
        (contentBounds.bottom - other.contentBounds.bottom).abs();
    final edgeDistance =
        (headerDensity - other.headerDensity).abs() +
        (footerDensity - other.footerDensity).abs() +
        (leftDensity - other.leftDensity).abs() +
        (rightDensity - other.rightDensity).abs();
    final centerDistance =
        (centerX - other.centerX).abs() + (centerY - other.centerY).abs();
    final inkDistance = (inkRatio - other.inkRatio).abs();
    final rowDistance = _profileDistance(rowProfile, other.rowProfile);
    final columnDistance = _profileDistance(columnProfile, other.columnProfile);
    final sparsePenalty = (inkRatio < 0.015) != (other.inkRatio < 0.015) ? 0.2 : 0.0;

    return (boundsDistance * 0.24) +
        (edgeDistance * 0.14) +
        (centerDistance * 0.12) +
        (inkDistance * 0.18) +
        (rowDistance * 0.16) +
        (columnDistance * 0.16) +
        sparsePenalty;
  }

  PageFingerprint mergeWith(PageFingerprint other, int currentCount) {
    final nextCount = currentCount + 1;
    return PageFingerprint(
      inkRatio: _mergeValue(inkRatio, other.inkRatio, currentCount, nextCount),
      headerDensity: _mergeValue(
        headerDensity,
        other.headerDensity,
        currentCount,
        nextCount,
      ),
      footerDensity: _mergeValue(
        footerDensity,
        other.footerDensity,
        currentCount,
        nextCount,
      ),
      leftDensity: _mergeValue(leftDensity, other.leftDensity, currentCount, nextCount),
      rightDensity: _mergeValue(
        rightDensity,
        other.rightDensity,
        currentCount,
        nextCount,
      ),
      centerX: _mergeValue(centerX, other.centerX, currentCount, nextCount),
      centerY: _mergeValue(centerY, other.centerY, currentCount, nextCount),
      contentBounds: CropRect(
        left: _mergeValue(
          contentBounds.left,
          other.contentBounds.left,
          currentCount,
          nextCount,
        ),
        top: _mergeValue(
          contentBounds.top,
          other.contentBounds.top,
          currentCount,
          nextCount,
        ),
        right: _mergeValue(
          contentBounds.right,
          other.contentBounds.right,
          currentCount,
          nextCount,
        ),
        bottom: _mergeValue(
          contentBounds.bottom,
          other.contentBounds.bottom,
          currentCount,
          nextCount,
        ),
      ).normalized(),
      rowProfile: _mergeProfiles(rowProfile, other.rowProfile, currentCount, nextCount),
      columnProfile: _mergeProfiles(
        columnProfile,
        other.columnProfile,
        currentCount,
        nextCount,
      ),
    );
  }

  static double _profileDistance(List<double> a, List<double> b) {
    if (a.isEmpty || b.isEmpty || a.length != b.length) {
      return 1;
    }
    var sum = 0.0;
    for (var i = 0; i < a.length; i++) {
      sum += (a[i] - b[i]).abs();
    }
    return sum / a.length;
  }

  static double _mergeValue(
    double current,
    double incoming,
    int currentCount,
    int nextCount,
  ) {
    return ((current * currentCount) + incoming) / nextCount;
  }

  static List<double> _mergeProfiles(
    List<double> current,
    List<double> incoming,
    int currentCount,
    int nextCount,
  ) {
    if (current.length != incoming.length) {
      return current;
    }
    return List<double>.generate(current.length, (index) {
      return _mergeValue(current[index], incoming[index], currentCount, nextCount);
    }, growable: false);
  }
}

class PageAnalysisService {
  static const int _profileBins = 12;

  static Future<PageAnalysis> analyzePage(
    PdfPage page, {
    int targetLongSide = 240,
    EdgeFilterSettings edgeFilter = const EdgeFilterSettings(),
  }) async {
    final pageNumber = page.pageNumber;
    final pageWidth = page.width;
    final pageHeight = page.height;
    final scale = targetLongSide / math.max(pageWidth, pageHeight);
    final fullWidth = math.max(1, (pageWidth * scale).round()).toDouble();
    final fullHeight = math.max(1, (pageHeight * scale).round()).toDouble();
    final image = await page.render(
      fullWidth: fullWidth,
      fullHeight: fullHeight,
    );

    if (image == null) {
      return PageAnalysis(
        pageNumber: pageNumber,
        pageWidth: pageWidth,
        pageHeight: pageHeight,
        fingerprint: const PageFingerprint(
          inkRatio: 0,
          headerDensity: 0,
          footerDensity: 0,
          leftDensity: 0,
          rightDensity: 0,
          centerX: 0.5,
          centerY: 0.5,
          contentBounds: CropRect.full,
          rowProfile: <double>[],
          columnProfile: <double>[],
        ),
        suggestedCrop: CropRect.full,
        layoutLabel: '空白页',
      );
    }

    try {
      return analyzePixels(
        pageNumber: pageNumber,
        pageWidth: pageWidth,
        pageHeight: pageHeight,
        pixels: image.pixels,
        width: image.width,
        height: image.height,
        edgeFilter: edgeFilter,
      );
    } finally {
      image.dispose();
    }
  }

  static PageAnalysis analyzePixels({
    required int pageNumber,
    required double pageWidth,
    required double pageHeight,
    required Uint8List pixels,
    required int width,
    required int height,
    EdgeFilterSettings edgeFilter = const EdgeFilterSettings(),
  }) {
    final rowDarkness = List<double>.filled(height, 0);
    final columnDarkness = List<double>.filled(width, 0);
    final rowMin = List<double>.filled(height, 255);
    final columnMin = List<double>.filled(width, 255);
    var darknessSum = 0.0;
    var weightedX = 0.0;
    var weightedY = 0.0;

    final leftEdge = (edgeFilter.left.clamp(0.0, 0.45) * width).floor();
    final topEdge = (edgeFilter.top.clamp(0.0, 0.45) * height).floor();
    final rightEdge = width - 1 - (edgeFilter.right.clamp(0.0, 0.45) * width).floor();
    final bottomEdge = height - 1 - (edgeFilter.bottom.clamp(0.0, 0.45) * height).floor();

    for (var y = 0; y < height; y++) {
      final rowOffset = y * width * 4;
      for (var x = 0; x < width; x++) {
        if (x < leftEdge || x > rightEdge || y < topEdge || y > bottomEdge) {
          continue;
        }
        final i = rowOffset + (x * 4);
        final b = pixels[i];
        final g = pixels[i + 1];
        final r = pixels[i + 2];
        final luminance = (r * 0.299) + (g * 0.587) + (b * 0.114);
        final darkness = 1 - (luminance / 255);
        rowDarkness[y] += darkness;
        columnDarkness[x] += darkness;
        if (luminance < rowMin[y]) {
          rowMin[y] = luminance;
        }
        if (luminance < columnMin[x]) {
          columnMin[x] = luminance;
        }
        darknessSum += darkness;
        weightedX += x * darkness;
        weightedY += y * darkness;
      }
    }

    final threshold = _adaptiveThreshold([...rowMin, ...columnMin]);
    final left = _findStart(columnMin, threshold);
    final right = _findEnd(columnMin, threshold);
    final top = _findStart(rowMin, threshold);
    final bottom = _findEnd(rowMin, threshold);
    final suggestedCrop = CropRect(
      left: left / width,
      top: top / height,
      right: (right + 1) / width,
      bottom: (bottom + 1) / height,
    ).normalized();
    final contentBounds = suggestedCrop.isValid ? _expandSlightly(suggestedCrop) : CropRect.full;

    final pixelCount = width * height;
    final inkRatio = pixelCount == 0 ? 0.0 : (darknessSum / pixelCount).toDouble();
    final centerX = darknessSum <= 0
        ? 0.5
        : ((weightedX / darknessSum) / math.max(1, width - 1)).toDouble();
    final centerY = darknessSum <= 0
        ? 0.5
        : ((weightedY / darknessSum) / math.max(1, height - 1)).toDouble();

    final topRows = math.max(1, (height * 0.15).round());
    final bottomRows = math.max(1, (height * 0.15).round());
    final leftColumns = math.max(1, (width * 0.15).round());
    final rightColumns = math.max(1, (width * 0.15).round());

    final rowArea = width.toDouble();
    final columnArea = height.toDouble();
    final headerDensity =
        _sumSlice(rowDarkness, 0, topRows) / (topRows * rowArea);
    final footerDensity =
        _sumSlice(rowDarkness, height - bottomRows, height) /
        (bottomRows * rowArea);
    final leftDensity =
        _sumSlice(columnDarkness, 0, leftColumns) / (leftColumns * columnArea);
    final rightDensity =
        _sumSlice(columnDarkness, width - rightColumns, width) /
        (rightColumns * columnArea);

    final rowProfile = _normalizeProfile(rowDarkness, width.toDouble());
    final columnProfile = _normalizeProfile(columnDarkness, height.toDouble());

    return PageAnalysis(
      pageNumber: pageNumber,
      pageWidth: pageWidth,
      pageHeight: pageHeight,
      fingerprint: PageFingerprint(
        inkRatio: inkRatio,
        headerDensity: headerDensity,
        footerDensity: footerDensity,
        leftDensity: leftDensity,
        rightDensity: rightDensity,
        centerX: centerX.clamp(0.0, 1.0).toDouble(),
        centerY: centerY.clamp(0.0, 1.0).toDouble(),
        contentBounds: contentBounds,
        rowProfile: rowProfile,
        columnProfile: columnProfile,
      ),
      suggestedCrop: contentBounds,
      layoutLabel: _resolveLayoutLabel(
        inkRatio: inkRatio,
        contentBounds: contentBounds,
        headerDensity: headerDensity,
        footerDensity: footerDensity,
      ),
    );
  }

  static String _resolveLayoutLabel({
    required double inkRatio,
    required CropRect contentBounds,
    required double headerDensity,
    required double footerDensity,
  }) {
    if (inkRatio < 0.01) {
      return '空白页';
    }
    final contentHeight = contentBounds.height;
    final topMargin = contentBounds.top;
    final bottomMargin = 1 - contentBounds.bottom;
    if (inkRatio > 0.22) {
      return '重内容页';
    }
    if (contentHeight < 0.58 || (topMargin > 0.18 && bottomMargin > 0.18)) {
      return '标题页';
    }
    if (headerDensity > footerDensity * 1.45 && topMargin < 0.1) {
      return '页眉明显';
    }
    if (footerDensity > headerDensity * 1.45 && bottomMargin < 0.1) {
      return '页脚明显';
    }
    return '正文页';
  }

  static List<double> _normalizeProfile(List<double> values, double divisor) {
    if (values.isEmpty) {
      return const <double>[];
    }
    final bins = List<double>.filled(_profileBins, 0);
    final counts = List<int>.filled(_profileBins, 0);
    for (var i = 0; i < values.length; i++) {
      final bin = math.min(
        _profileBins - 1,
        ((i / values.length) * _profileBins).floor(),
      );
      bins[bin] += values[i] / divisor;
      counts[bin]++;
    }
    for (var i = 0; i < bins.length; i++) {
      bins[i] = counts[i] == 0
          ? 0
          : (bins[i] / counts[i]).clamp(0.0, 1.0).toDouble();
    }
    return List<double>.unmodifiable(bins);
  }

  static double _sumSlice(List<double> values, int start, int end) {
    var sum = 0.0;
    final clampedStart = start.clamp(0, values.length);
    final clampedEnd = end.clamp(0, values.length);
    for (var i = clampedStart; i < clampedEnd; i++) {
      sum += values[i];
    }
    return sum;
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

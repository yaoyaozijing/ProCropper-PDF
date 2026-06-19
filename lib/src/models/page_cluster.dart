import 'dart:typed_data';
import 'dart:ui';

import '../l10n/app_localizations.dart';
import 'crop_aspect_ratio_lock.dart';
import 'crop_rect.dart';
import 'cluster_preview_data.dart';

class PageCluster {
  PageCluster({
    required this.id,
    required this.parityLabel,
    required this.layoutLabel,
    required this.groupingReason,
    required this.pageWidth,
    required this.pageHeight,
    required this.pages,
    required this.previewImageBytes,
    required this.previewSize,
    required this.previewBgraBytes,
    required this.previewPixelWidth,
    required this.previewPixelHeight,
    required this.cropRects,
    required this.aspectRatioLocks,
    this.containsOutlierPage = false,
  });

  final String id;
  final String parityLabel;
  final String layoutLabel;
  final String groupingReason;
  final double pageWidth;
  final double pageHeight;
  final List<int> pages;
  final Uint8List previewImageBytes;
  final Size previewSize;
  final Uint8List previewBgraBytes;
  final int previewPixelWidth;
  final int previewPixelHeight;
  final List<CropRect> cropRects;
  final List<CropAspectRatioLock?> aspectRatioLocks;
  final bool containsOutlierPage;

  String get title {
    final samplePages = pages.take(6).join(', ');
    final suffix = pages.length > 6 ? '...' : '';
    return AppLocalizations.current.clusterTitle(
      parityLabel,
      layoutLabel,
      pages.length,
      samplePages,
      suffix,
    );
  }

  PageCluster copyWith({
    List<CropRect>? cropRects,
    List<CropAspectRatioLock?>? aspectRatioLocks,
    Uint8List? previewImageBytes,
    Size? previewSize,
    Uint8List? previewBgraBytes,
    int? previewPixelWidth,
    int? previewPixelHeight,
    String? layoutLabel,
    String? groupingReason,
    bool? containsOutlierPage,
  }) {
    return PageCluster(
      id: id,
      parityLabel: parityLabel,
      layoutLabel: layoutLabel ?? this.layoutLabel,
      groupingReason: groupingReason ?? this.groupingReason,
      pageWidth: pageWidth,
      pageHeight: pageHeight,
      pages: pages,
      previewImageBytes: previewImageBytes ?? this.previewImageBytes,
      previewSize: previewSize ?? this.previewSize,
      previewBgraBytes: previewBgraBytes ?? this.previewBgraBytes,
      previewPixelWidth: previewPixelWidth ?? this.previewPixelWidth,
      previewPixelHeight: previewPixelHeight ?? this.previewPixelHeight,
      cropRects: cropRects ?? this.cropRects,
      aspectRatioLocks: aspectRatioLocks ?? this.aspectRatioLocks,
      containsOutlierPage: containsOutlierPage ?? this.containsOutlierPage,
    );
  }

  ClusterPreviewData get previewData {
    return ClusterPreviewData(
      pngBytes: previewImageBytes,
      previewSize: previewSize,
      bgraBytes: previewBgraBytes,
      pixelWidth: previewPixelWidth,
      pixelHeight: previewPixelHeight,
    );
  }
}

import 'dart:typed_data';
import 'dart:ui';

import 'crop_rect.dart';
import 'cluster_preview_data.dart';

class PageCluster {
  PageCluster({
    required this.id,
    required this.parityLabel,
    required this.pageWidth,
    required this.pageHeight,
    required this.pages,
    required this.previewImageBytes,
    required this.previewSize,
    required this.previewBgraBytes,
    required this.previewPixelWidth,
    required this.previewPixelHeight,
    required this.cropRects,
  });

  final String id;
  final String parityLabel;
  final double pageWidth;
  final double pageHeight;
  final List<int> pages;
  final Uint8List previewImageBytes;
  final Size previewSize;
  final Uint8List previewBgraBytes;
  final int previewPixelWidth;
  final int previewPixelHeight;
  final List<CropRect> cropRects;

  String get title {
    final samplePages = pages.take(6).join(', ');
    final suffix = pages.length > 6 ? '...' : '';
    return '$parityLabel页（${pages.length}页）[$samplePages$suffix]';
  }

  PageCluster copyWith({
    List<CropRect>? cropRects,
    Uint8List? previewImageBytes,
    Size? previewSize,
    Uint8List? previewBgraBytes,
    int? previewPixelWidth,
    int? previewPixelHeight,
  }) {
    return PageCluster(
      id: id,
      parityLabel: parityLabel,
      pageWidth: pageWidth,
      pageHeight: pageHeight,
      pages: pages,
      previewImageBytes: previewImageBytes ?? this.previewImageBytes,
      previewSize: previewSize ?? this.previewSize,
      previewBgraBytes: previewBgraBytes ?? this.previewBgraBytes,
      previewPixelWidth: previewPixelWidth ?? this.previewPixelWidth,
      previewPixelHeight: previewPixelHeight ?? this.previewPixelHeight,
      cropRects: cropRects ?? this.cropRects,
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

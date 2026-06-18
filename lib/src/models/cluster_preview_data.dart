import 'dart:typed_data';
import 'dart:ui';

class ClusterPreviewData {
  const ClusterPreviewData({
    required this.pngBytes,
    required this.previewSize,
    required this.bgraBytes,
    required this.pixelWidth,
    required this.pixelHeight,
  });

  final Uint8List pngBytes;
  final Size previewSize;
  final Uint8List bgraBytes;
  final int pixelWidth;
  final int pixelHeight;
}

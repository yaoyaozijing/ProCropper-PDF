import 'crop_rect.dart';

class CropClipboard {
  const CropClipboard({
    required this.cropRects,
    required this.sourceClusterId,
  });

  final List<CropRect> cropRects;
  final String sourceClusterId;
}

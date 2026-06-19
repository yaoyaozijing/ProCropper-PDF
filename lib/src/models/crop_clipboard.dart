import 'crop_aspect_ratio_lock.dart';
import 'crop_rect.dart';

class CropClipboard {
  const CropClipboard({
    required this.cropRects,
    required this.aspectRatioLocks,
    required this.sourceClusterId,
  });

  final List<CropRect> cropRects;
  final List<CropAspectRatioLock?> aspectRatioLocks;
  final String sourceClusterId;
}

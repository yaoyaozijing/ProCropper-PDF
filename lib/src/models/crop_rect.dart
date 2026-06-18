import 'dart:ui';

class CropRect {
  const CropRect({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final double left;
  final double top;
  final double right;
  final double bottom;

  static const CropRect full = CropRect(
    left: 0,
    top: 0,
    right: 1,
    bottom: 1,
  );

  double get width => right - left;
  double get height => bottom - top;
  bool get isValid => width > 0.005 && height > 0.005;

  Rect toPreviewRect(Size size) {
    return Rect.fromLTWH(
      left * size.width,
      top * size.height,
      width * size.width,
      height * size.height,
    );
  }

  CropRect copyWith({
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    return CropRect(
      left: left ?? this.left,
      top: top ?? this.top,
      right: right ?? this.right,
      bottom: bottom ?? this.bottom,
    ).normalized();
  }

  CropRect normalized() {
    return CropRect(
      left: left < right ? left : right,
      top: top < bottom ? top : bottom,
      right: right > left ? right : left,
      bottom: bottom > top ? bottom : top,
    );
  }

  factory CropRect.fromPreviewRect(Rect rect, Size size) {
    return CropRect(
      left: rect.left / size.width,
      top: rect.top / size.height,
      right: rect.right / size.width,
      bottom: rect.bottom / size.height,
    ).normalized();
  }
}

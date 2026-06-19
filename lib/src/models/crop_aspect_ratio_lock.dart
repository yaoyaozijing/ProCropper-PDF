class CropAspectRatioLock {
  const CropAspectRatioLock({
    required this.width,
    required this.height,
  });

  final double width;
  final double height;

  double get ratio => width / height;

  bool get isValid => width > 0 && height > 0;
}

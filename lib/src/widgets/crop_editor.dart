import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/crop_aspect_ratio_lock.dart';
import '../models/crop_rect.dart';

enum _DragHandle {
  move,
  top,
  right,
  bottom,
  left,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

enum _InteractionMode {
  none,
  editCrop,
  transformViewport,
}

class CropViewportController {
  VoidCallback? _zoomInAction;
  VoidCallback? _zoomOutAction;

  void _attach({
    required VoidCallback onZoomIn,
    required VoidCallback onZoomOut,
  }) {
    _zoomInAction = onZoomIn;
    _zoomOutAction = onZoomOut;
  }

  void _detach() {
    _zoomInAction = null;
    _zoomOutAction = null;
  }

  void zoomIn() => _zoomInAction?.call();

  void zoomOut() => _zoomOutAction?.call();
}

class CropEditor extends StatefulWidget {
  const CropEditor({
    required this.previewBytes,
    required this.previewSize,
    required this.cropRects,
    required this.aspectRatioLocks,
    required this.selectedRectIndex,
    required this.colorScheme,
    required this.onRectSelected,
    required this.onRectChanged,
    required this.onRectDeleteRequested,
    required this.onRectInfoRequested,
    this.contentPadding = EdgeInsets.zero,
    this.viewportController,
    super.key,
  });

  final Uint8List previewBytes;
  final Size previewSize;
  final List<CropRect> cropRects;
  final List<CropAspectRatioLock?> aspectRatioLocks;
  final int selectedRectIndex;
  final ColorScheme colorScheme;
  final ValueChanged<int> onRectSelected;
  final ValueChanged<CropRect> onRectChanged;
  final ValueChanged<int> onRectDeleteRequested;
  final ValueChanged<int> onRectInfoRequested;
  final EdgeInsets contentPadding;
  final CropViewportController? viewportController;

  @override
  State<CropEditor> createState() => _CropEditorState();
}

class _CropEditorState extends State<CropEditor> {
  static const double _minZoom = 0.35;
  static const double _maxZoom = 6;
  static const double _zoomStep = 1.15;

  _InteractionMode _interactionMode = _InteractionMode.none;
  _DragHandle? _dragHandle;
  Offset? _dragStart;
  CropRect? _dragStartRect;
  Size _viewportSize = Size.zero;
  Size? _baseFittedSize;
  EdgeInsets? _effectiveContentPadding;
  double _zoom = 1;
  Offset _pan = Offset.zero;
  double _gestureStartZoom = 1;
  Offset _gestureAnchor = const Offset(0.5, 0.5);

  @override
  void initState() {
    super.initState();
    widget.viewportController?._attach(
      onZoomIn: _zoomIn,
      onZoomOut: _zoomOut,
    );
  }

  @override
  void didUpdateWidget(covariant CropEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewportController != widget.viewportController) {
      oldWidget.viewportController?._detach();
      widget.viewportController?._attach(
        onZoomIn: _zoomIn,
        onZoomOut: _zoomOut,
      );
    }
    if (oldWidget.previewBytes != widget.previewBytes ||
        oldWidget.previewSize != widget.previewSize) {
      _baseFittedSize = null;
      _effectiveContentPadding = null;
      _zoom = 1;
      _pan = Offset.zero;
      _interactionMode = _InteractionMode.none;
      _dragHandle = null;
      _dragStart = null;
      _dragStartRect = null;
    }
  }

  @override
  void dispose() {
    widget.viewportController?._detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _viewportSize = constraints.biggest;
        _effectiveContentPadding ??= widget.contentPadding;
        _baseFittedSize ??= _fitSize(_contentRectFor(_viewportSize).size, widget.previewSize);
        final imageRect = _imageRectFor(_viewportSize);
        return Listener(
          onPointerSignal: _onPointerSignal,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onScaleStart: _onScaleStart,
            onScaleUpdate: _onScaleUpdate,
            onScaleEnd: _onScaleEnd,
            onTapUp: _onTapUp,
            onDoubleTapDown: _onDoubleTapDown,
            onSecondaryTapUp: _onSecondaryTapUp,
            child: ClipRect(
              child: Stack(
                children: [
                  Positioned.fromRect(
                    rect: imageRect,
                    child: Image.memory(
                      widget.previewBytes,
                      fit: BoxFit.fill,
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _CropPainter(
                        imageRect: imageRect,
                        cropRects: widget.cropRects,
                        selectedRectIndex: widget.selectedRectIndex,
                        colorScheme: widget.colorScheme,
                      ),
                    ),
                  ),
                  ...List<Widget>.generate(widget.cropRects.length, (index) {
                    final rect = _rectOnViewport(widget.cropRects[index], imageRect);
                    final selected = index == widget.selectedRectIndex;
                    return Positioned.fromRect(
                      rect: _labelRect(rect, index),
                      child: _RectInfoChip(
                        index: index,
                        selected: selected,
                        colorScheme: widget.colorScheme,
                        onTap: () {
                          widget.onRectSelected(index);
                          widget.onRectInfoRequested(index);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _onTapUp(TapUpDetails details) {
    final position = details.localPosition;
    final imageRect = _imageRectFor(_viewportSize);
    for (var i = widget.cropRects.length - 1; i >= 0; i--) {
      final rect = _rectOnViewport(widget.cropRects[i], imageRect);
      if (rect.contains(position)) {
        if (_isLabelHit(position, rect, i)) {
          widget.onRectInfoRequested(i);
          return;
        }
        widget.onRectSelected(i);
        return;
      }
    }
  }

  void _onSecondaryTapUp(TapUpDetails details) {
    final position = details.localPosition;
    final imageRect = _imageRectFor(_viewportSize);
    for (var i = widget.cropRects.length - 1; i >= 0; i--) {
      final rect = _rectOnViewport(widget.cropRects[i], imageRect);
      if (rect.contains(position)) {
        widget.onRectSelected(i);
        widget.onRectInfoRequested(i);
        return;
      }
    }
  }

  void _onDoubleTapDown(TapDownDetails details) {
    if (details.kind != PointerDeviceKind.mouse) {
      return;
    }

    final position = details.localPosition;
    final imageRect = _imageRectFor(_viewportSize);
    for (var i = widget.cropRects.length - 1; i >= 0; i--) {
      final rect = _rectOnViewport(widget.cropRects[i], imageRect);
      if (rect.contains(position)) {
        widget.onRectSelected(i);
        widget.onRectDeleteRequested(i);
        return;
      }
    }
  }

  void _onScaleStart(ScaleStartDetails details) {
    if (_viewportSize.isEmpty) {
      return;
    }

    final imageRect = _imageRectFor(_viewportSize);
    final local = details.localFocalPoint;
    final pressedKeys = HardwareKeyboard.instance.logicalKeysPressed;
    final isControlPressed =
        pressedKeys.contains(LogicalKeyboardKey.controlLeft) ||
        pressedKeys.contains(LogicalKeyboardKey.controlRight);

    if (isControlPressed) {
      _interactionMode = _InteractionMode.transformViewport;
      _gestureStartZoom = _zoom;
      _gestureAnchor = _normalizedAnchor(local, imageRect);
      return;
    }

    if (widget.cropRects.isNotEmpty) {
      final selectedRect = _rectOnViewport(
        widget.cropRects[widget.selectedRectIndex],
        imageRect,
      );
      final handle = _resolveHandle(local, selectedRect);
      if (handle != null) {
        _interactionMode = _InteractionMode.editCrop;
        _dragHandle = handle;
        _dragStart = local;
        _dragStartRect = widget.cropRects[widget.selectedRectIndex];
        return;
      }

      for (var i = widget.cropRects.length - 1; i >= 0; i--) {
        final rect = _rectOnViewport(widget.cropRects[i], imageRect);
        if (rect.contains(local)) {
          widget.onRectSelected(i);
          _interactionMode = _InteractionMode.editCrop;
          _dragHandle = _DragHandle.move;
          _dragStart = local;
          _dragStartRect = widget.cropRects[i];
          return;
        }
      }
    }

    _interactionMode = _InteractionMode.transformViewport;
    _gestureStartZoom = _zoom;
    _gestureAnchor = _normalizedAnchor(local, imageRect);
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_interactionMode == _InteractionMode.editCrop &&
        (details.scale - 1).abs() > 0.02) {
      _interactionMode = _InteractionMode.transformViewport;
      _dragHandle = null;
      _dragStart = null;
      _dragStartRect = null;
      _gestureStartZoom = _zoom;
      _gestureAnchor = _normalizedAnchor(
        details.localFocalPoint,
        _imageRectFor(_viewportSize),
      );
    }

    if (_interactionMode == _InteractionMode.editCrop) {
      _updateCropRect(details.localFocalPoint);
      return;
    }
    if (_interactionMode != _InteractionMode.transformViewport) {
      return;
    }

    final nextZoom = (_gestureStartZoom * details.scale)
        .clamp(_minZoom, _maxZoom)
        .toDouble();
    final contentRect = _contentRectFor(_viewportSize);
    final nextSize = _displaySizeFor(contentRect.size, nextZoom);
    final centered = _centeredTopLeft(contentRect, nextSize);
    final desiredTopLeft = details.localFocalPoint -
        Offset(
          _gestureAnchor.dx * nextSize.width,
          _gestureAnchor.dy * nextSize.height,
        );
    final nextPan = _clampPan(
      desiredTopLeft - centered,
      contentRect,
      nextSize,
      centered,
    );

    setState(() {
      _zoom = nextZoom;
      _pan = nextPan;
    });
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _interactionMode = _InteractionMode.none;
    _dragHandle = null;
    _dragStart = null;
    _dragStartRect = null;
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || _viewportSize.isEmpty) {
      return;
    }

    final pressedKeys = HardwareKeyboard.instance.logicalKeysPressed;
    final isControlPressed =
        pressedKeys.contains(LogicalKeyboardKey.controlLeft) ||
        pressedKeys.contains(LogicalKeyboardKey.controlRight);
    if (!isControlPressed) {
      return;
    }

    final factor = event.scrollDelta.dy < 0 ? _zoomStep : 1 / _zoomStep;
    _zoomAround(event.localPosition, factor);
  }

  void _updateCropRect(Offset localPosition) {
    if (_dragHandle == null || _dragStart == null || _dragStartRect == null) {
      return;
    }

    final imageRect = _imageRectFor(_viewportSize);
    final delta = localPosition - _dragStart!;
    final dx = delta.dx / imageRect.width;
    final dy = delta.dy / imageRect.height;
    var rect = _dragStartRect!;
    final aspectRatioLock = widget.aspectRatioLocks[widget.selectedRectIndex];

    switch (_dragHandle!) {
      case _DragHandle.move:
        rect = CropRect(
          left: rect.left + dx,
          top: rect.top + dy,
          right: rect.right + dx,
          bottom: rect.bottom + dy,
        ).normalized();
      case _DragHandle.top:
        rect = rect.copyWith(top: rect.top + dy);
      case _DragHandle.right:
        rect = rect.copyWith(right: rect.right + dx);
      case _DragHandle.bottom:
        rect = rect.copyWith(bottom: rect.bottom + dy);
      case _DragHandle.left:
        rect = rect.copyWith(left: rect.left + dx);
      case _DragHandle.topLeft:
        rect = rect.copyWith(left: rect.left + dx, top: rect.top + dy);
      case _DragHandle.topRight:
        rect = rect.copyWith(right: rect.right + dx, top: rect.top + dy);
      case _DragHandle.bottomLeft:
        rect = rect.copyWith(left: rect.left + dx, bottom: rect.bottom + dy);
      case _DragHandle.bottomRight:
        rect = rect.copyWith(right: rect.right + dx, bottom: rect.bottom + dy);
    }

    rect = _applyAspectRatioLock(
      rect: rect,
      originalRect: _dragStartRect!,
      handle: _dragHandle!,
      aspectRatioLock: aspectRatioLock,
    );

    if (rect.isValid) {
      widget.onRectChanged(rect.normalized());
    }
  }

  CropRect _applyAspectRatioLock({
    required CropRect rect,
    required CropRect originalRect,
    required _DragHandle handle,
    required CropAspectRatioLock? aspectRatioLock,
  }) {
    if (aspectRatioLock == null || !aspectRatioLock.isValid) {
      return rect;
    }

    final targetRatio =
        aspectRatioLock.ratio * (widget.previewSize.height / widget.previewSize.width);
    if (targetRatio <= 0) {
      return rect;
    }

    switch (handle) {
      case _DragHandle.move:
        return rect;
      case _DragHandle.left:
      case _DragHandle.right:
        final targetHeight = rect.width / targetRatio;
        final centerY = (originalRect.top + originalRect.bottom) / 2;
        return rect.copyWith(
          top: centerY - targetHeight / 2,
          bottom: centerY + targetHeight / 2,
        );
      case _DragHandle.top:
      case _DragHandle.bottom:
        final targetWidth = rect.height * targetRatio;
        final centerX = (originalRect.left + originalRect.right) / 2;
        return rect.copyWith(
          left: centerX - targetWidth / 2,
          right: centerX + targetWidth / 2,
        );
      case _DragHandle.topLeft:
        return rect.copyWith(
          top: rect.bottom - (rect.width / targetRatio),
        );
      case _DragHandle.topRight:
        return rect.copyWith(
          top: rect.bottom - (rect.width / targetRatio),
        );
      case _DragHandle.bottomLeft:
        return rect.copyWith(
          bottom: rect.top + (rect.width / targetRatio),
        );
      case _DragHandle.bottomRight:
        return rect.copyWith(
          bottom: rect.top + (rect.width / targetRatio),
        );
    }
  }

  void _zoomIn() => _zoomAround(_viewportSize.center(Offset.zero), _zoomStep);

  void _zoomOut() => _zoomAround(_viewportSize.center(Offset.zero), 1 / _zoomStep);

  void _zoomAround(Offset focalPoint, double factor) {
    if (_viewportSize.isEmpty) {
      return;
    }

    final currentRect = _imageRectFor(_viewportSize);
    if (currentRect.width <= 0 || currentRect.height <= 0) {
      return;
    }

    final nextZoom = (_zoom * factor).clamp(_minZoom, _maxZoom).toDouble();
    final anchor = _normalizedAnchor(focalPoint, currentRect);
    final contentRect = _contentRectFor(_viewportSize);
    final nextSize = _displaySizeFor(contentRect.size, nextZoom);
    final centered = _centeredTopLeft(contentRect, nextSize);
    final desiredTopLeft = focalPoint -
        Offset(
          anchor.dx * nextSize.width,
          anchor.dy * nextSize.height,
        );
    final nextPan = _clampPan(
      desiredTopLeft - centered,
      contentRect,
      nextSize,
      centered,
    );

    setState(() {
      _zoom = nextZoom;
      _pan = nextPan;
    });
  }

  Rect _rectOnViewport(CropRect cropRect, Rect imageRect) {
    return cropRect.toPreviewRect(imageRect.size).shift(imageRect.topLeft);
  }

  Rect _imageRectFor(Size viewport, {double? zoom, Offset? pan}) {
    final contentRect = _contentRectFor(viewport);
    final displaySize = _displaySizeFor(contentRect.size, zoom ?? _zoom);
    final centered = _centeredTopLeft(contentRect, displaySize);
    final effectivePan = _clampPan(
      pan ?? _pan,
      Offset.zero & viewport,
      displaySize,
      centered,
    );
    return centered + effectivePan & displaySize;
  }

  Size _displaySizeFor(Size availableSize, double zoom) {
    final fitted = _baseFittedSize ?? _fitSize(availableSize, widget.previewSize);
    return Size(fitted.width * zoom, fitted.height * zoom);
  }

  Rect _contentRectFor(Size viewport) {
    final padding = _effectiveContentPadding ?? widget.contentPadding;
    final left = padding.left.clamp(0.0, viewport.width).toDouble();
    final top = padding.top.clamp(0.0, viewport.height).toDouble();
    final right = padding.right.clamp(0.0, viewport.width - left).toDouble();
    final bottom = padding.bottom.clamp(0.0, viewport.height - top).toDouble();
    final width = math.max(0.0, viewport.width - left - right);
    final height = math.max(0.0, viewport.height - top - bottom);
    return Rect.fromLTWH(left, top, width, height);
  }

  Offset _centeredTopLeft(Rect contentRect, Size displaySize) {
    return Offset(
      contentRect.left + (contentRect.width - displaySize.width) / 2,
      contentRect.top + (contentRect.height - displaySize.height) / 2,
    );
  }

  Offset _clampPan(
    Offset pan,
    Rect boundsRect,
    Size displaySize,
    Offset baseTopLeft,
  ) {
    final minLeft = math.min(boundsRect.left, boundsRect.right - displaySize.width);
    final maxLeft = math.max(boundsRect.left, boundsRect.right - displaySize.width);
    final minTop = math.min(boundsRect.top, boundsRect.bottom - displaySize.height);
    final maxTop = math.max(boundsRect.top, boundsRect.bottom - displaySize.height);

    final clampedLeft = (baseTopLeft.dx + pan.dx).clamp(minLeft, maxLeft).toDouble();
    final clampedTop = (baseTopLeft.dy + pan.dy).clamp(minTop, maxTop).toDouble();
    return Offset(clampedLeft - baseTopLeft.dx, clampedTop - baseTopLeft.dy);
  }

  Offset _normalizedAnchor(Offset point, Rect rect) {
    if (rect.width <= 0 || rect.height <= 0) {
      return const Offset(0.5, 0.5);
    }
    return Offset(
      ((point.dx - rect.left) / rect.width).clamp(0.0, 1.0).toDouble(),
      ((point.dy - rect.top) / rect.height).clamp(0.0, 1.0).toDouble(),
    );
  }

  _DragHandle? _resolveHandle(Offset point, Rect rect) {
    const handleRadius = 16.0;
    const edgeDistance = 10.0;
    final insideHorizontal =
        point.dx >= rect.left + handleRadius && point.dx <= rect.right - handleRadius;
    final insideVertical =
        point.dy >= rect.top + handleRadius && point.dy <= rect.bottom - handleRadius;

    if ((point - rect.topLeft).distance <= handleRadius) {
      return _DragHandle.topLeft;
    }
    if ((point - rect.topRight).distance <= handleRadius) {
      return _DragHandle.topRight;
    }
    if ((point - rect.bottomLeft).distance <= handleRadius) {
      return _DragHandle.bottomLeft;
    }
    if ((point - rect.bottomRight).distance <= handleRadius) {
      return _DragHandle.bottomRight;
    }
    if ((point.dy - rect.top).abs() <= edgeDistance && insideHorizontal) {
      return _DragHandle.top;
    }
    if ((point.dx - rect.right).abs() <= edgeDistance && insideVertical) {
      return _DragHandle.right;
    }
    if ((point.dy - rect.bottom).abs() <= edgeDistance && insideHorizontal) {
      return _DragHandle.bottom;
    }
    if ((point.dx - rect.left).abs() <= edgeDistance && insideVertical) {
      return _DragHandle.left;
    }
    if (rect.contains(point)) {
      return _DragHandle.move;
    }
    return null;
  }

  Size _fitSize(Size bounds, Size source) {
    if (bounds.isEmpty || source.isEmpty) {
      return bounds;
    }
    final scale = math.min(bounds.width / source.width, bounds.height / source.height);
    return Size(source.width * scale, source.height * scale);
  }

  bool _isLabelHit(Offset point, Rect rect, int index) {
    final labelRect = _labelRect(rect, index);
    return labelRect.contains(point);
  }

  Rect _labelRect(Rect rect, int index) {
    const iconSize = 22.0;
    const iconSpacing = 10.0;
    const rightPadding = 18.0;
    final painter = TextPainter(
      text: const TextSpan(
        text: '00',
        style: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final digitCount = '${index + 1}'.length;
    final textWidth = painter.width * (digitCount / 2).clamp(0.5, 2.0);
    return Rect.fromLTWH(
      rect.left + 10,
      rect.top + 10,
      textWidth + 14 + iconSpacing + iconSize + rightPadding,
      painter.height + 18,
    );
  }
}

class _RectInfoChip extends StatelessWidget {
  const _RectInfoChip({
    required this.index,
    required this.selected,
    required this.colorScheme,
    required this.onTap,
  });

  final int index;
  final bool selected;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final darkScheme = ColorScheme.fromSeed(
      seedColor: colorScheme.primary,
      brightness: Brightness.dark,
    );
    final backgroundColor = selected
        ? Color.alphaBlend(
            darkScheme.primary.withValues(alpha: 0.28),
            darkScheme.surface.withValues(alpha: 0.82),
          )
        : darkScheme.surface.withValues(alpha: 0.52);
    final borderColor = selected
        ? darkScheme.primary.withValues(alpha: 0.42)
        : darkScheme.outline.withValues(alpha: 0.4);
    final foregroundColor = darkScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 9, 18, 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: foregroundColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CropPainter extends CustomPainter {
  const _CropPainter({
    required this.imageRect,
    required this.cropRects,
    required this.selectedRectIndex,
    required this.colorScheme,
  });

  final Rect imageRect;
  final List<CropRect> cropRects;
  final int selectedRectIndex;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final darkScheme = ColorScheme.fromSeed(
      seedColor: colorScheme.primary,
      brightness: Brightness.dark,
    );
    final activeFillColor = Color.alphaBlend(
      darkScheme.surface.withValues(alpha: 0.62),
      darkScheme.primary.withValues(alpha: 0.14),
    );
    final inactiveFillColor = darkScheme.surface.withValues(alpha: 0.2);
    final activeBorderColor = Color.alphaBlend(
      darkScheme.onPrimary.withValues(alpha: 0.82),
      darkScheme.primary,
    );
    final inactiveBorderColor = Color.alphaBlend(
      darkScheme.outline.withValues(alpha: 0.78),
      darkScheme.surface.withValues(alpha: 0.85),
    );
    for (var i = 0; i < cropRects.length; i++) {
      final rect = cropRects[i].toPreviewRect(imageRect.size).shift(imageRect.topLeft);
      final highlight = i == selectedRectIndex;
      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = highlight ? activeFillColor : inactiveFillColor;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        fillPaint,
      );

      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = highlight ? 3 : 2
        ..color = highlight ? activeBorderColor : inactiveBorderColor;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        borderPaint,
      );

      for (final point in [rect.topLeft, rect.topRight, rect.bottomLeft, rect.bottomRight]) {
        canvas.drawCircle(
          point,
          highlight ? 6 : 5,
          Paint()..color = borderPaint.color,
        );
        canvas.drawCircle(
          point,
          highlight ? 3 : 2.5,
          Paint()..color = Colors.white,
        );
      }

      _paintEdgeHandle(
        canvas,
        Offset(rect.center.dx, rect.top),
        horizontal: true,
        color: borderPaint.color,
        highlight: highlight,
      );
      _paintEdgeHandle(
        canvas,
        Offset(rect.right, rect.center.dy),
        horizontal: false,
        color: borderPaint.color,
        highlight: highlight,
      );
      _paintEdgeHandle(
        canvas,
        Offset(rect.center.dx, rect.bottom),
        horizontal: true,
        color: borderPaint.color,
        highlight: highlight,
      );
      _paintEdgeHandle(
        canvas,
        Offset(rect.left, rect.center.dy),
        horizontal: false,
        color: borderPaint.color,
        highlight: highlight,
      );
    }
  }

  void _paintEdgeHandle(
    Canvas canvas,
    Offset center, {
    required bool horizontal,
    required Color color,
    required bool highlight,
  }) {
    final size = horizontal
        ? Size(highlight ? 18 : 16, highlight ? 6 : 5)
        : Size(highlight ? 6 : 5, highlight ? 18 : 16);
    final rect = Rect.fromCenter(
      center: center,
      width: size.width,
      height: size.height,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(999));
    canvas.drawRRect(
      rrect,
      Paint()..color = color,
    );
    canvas.drawRRect(
      rrect.deflate(1.4),
      Paint()..color = Colors.white.withValues(alpha: 0.92),
    );
  }

  @override
  bool shouldRepaint(covariant _CropPainter oldDelegate) {
    return oldDelegate.imageRect != imageRect ||
        oldDelegate.cropRects != cropRects ||
        oldDelegate.selectedRectIndex != selectedRectIndex ||
        oldDelegate.colorScheme != colorScheme;
  }
}

import 'package:flutter/material.dart';

import '../models/photo_spec.dart';
import '../models/source_photo.dart';
import '../theme.dart';
import 'cropped_photo.dart';

/// The crop editor. A fixed-aspect window over the photo, with the photo moved
/// and zoomed underneath it rather than the window moved over the photo — the
/// window is the printed edge, so it must never move.
class CropCanvas extends StatefulWidget {
  const CropCanvas({
    required this.photo,
    required this.spec,
    required this.onChanged,
    super.key,
  });

  final SourcePhoto photo;
  final PhotoSpec spec;
  final ValueChanged<CropTransform> onChanged;

  @override
  State<CropCanvas> createState() => _CropCanvasState();
}

class _CropCanvasState extends State<CropCanvas> {
  /// Transform at the moment the current gesture began, so a gesture is always
  /// applied to a stable base instead of compounding frame by frame.
  CropTransform _base = CropTransform.identity;
  Offset _startFocal = Offset.zero;

  void _onScaleStart(ScaleStartDetails details) {
    _base = widget.photo.transform;
    _startFocal = details.focalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails details, Size window) {
    final panned = details.focalPoint - _startFocal;

    final next = CropTransform(
      scale: _base.scale * details.scale,
      // Pan is stored as a fraction of the window, so it stays correct when
      // the window is a different size on another screen or in the PDF.
      offset: _base.offset +
          Offset(panned.dx / window.width, panned.dy / window.height),
    ).clamped(
      imageWidth: widget.photo.width,
      imageHeight: widget.photo.height,
      windowAspect: widget.spec.aspectRatio,
    );

    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final window = _fitWindow(constraints, widget.spec.aspectRatio);

        return Center(
          child: Semantics(
            label:
                'Photo crop area, ${widget.spec.widthMm.round()} by '
                '${widget.spec.heightMm.round()} millimetres. '
                'Pinch to zoom, drag to move the photo.',
            child: SizedBox(
              width: window.width,
              height: window.height,
                child: GestureDetector(
                onScaleStart: _onScaleStart,
                onScaleUpdate: (d) => _onScaleUpdate(d, window),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CroppedPhoto(photo: widget.photo, window: window),
                    const IgnorePointer(child: _GuideOverlay()),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// The largest window of the required aspect ratio that fits, with a margin
  /// so the guide lines are never flush against the screen edge.
  static Size _fitWindow(BoxConstraints constraints, double aspect) {
    final maxW = constraints.maxWidth - AppSpacing.stackMd * 2;
    final maxH = constraints.maxHeight - AppSpacing.stackMd * 2;

    var width = maxW;
    var height = width / aspect;
    if (height > maxH) {
      height = maxH;
      width = height * aspect;
    }
    return Size(width, height);
  }
}

/// The passport-template markings: a dashed border, solid corner brackets, and
/// the horizontal eye line.
class _GuideOverlay extends StatelessWidget {
  const _GuideOverlay();

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.infinite, painter: _GuidePainter());
}

class _GuidePainter extends CustomPainter {
  /// Where the subject's eyes should sit, as a fraction from the top. Roughly
  /// the top third, matching a real passport photo template.
  static const eyeLineFraction = 0.33;

  static const _dash = 8.0;
  static const _gap = 6.0;
  static const _bracket = 28.0;

  @override
  void paint(Canvas canvas, Size size) {
    final thin = Paint()
      ..color = AppColors.guide
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final thick = Paint()
      ..color = AppColors.guide
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.square;

    _dashedRect(canvas, Offset.zero & size, thin);

    final eyeY = size.height * eyeLineFraction;
    _dashedLine(canvas, Offset(0, eyeY), Offset(size.width, eyeY), thin);

    // Corner brackets read as a physical template rather than a selection box.
    final w = size.width;
    final h = size.height;
    for (final (corner, dx, dy) in [
      (Offset.zero, 1.0, 1.0),
      (Offset(w, 0), -1.0, 1.0),
      (Offset(0, h), 1.0, -1.0),
      (Offset(w, h), -1.0, -1.0),
    ]) {
      canvas
        ..drawLine(corner, corner.translate(_bracket * dx, 0), thick)
        ..drawLine(corner, corner.translate(0, _bracket * dy), thick);
    }
  }

  void _dashedRect(Canvas canvas, Rect rect, Paint paint) {
    _dashedLine(canvas, rect.topLeft, rect.topRight, paint);
    _dashedLine(canvas, rect.topRight, rect.bottomRight, paint);
    _dashedLine(canvas, rect.bottomRight, rect.bottomLeft, paint);
    _dashedLine(canvas, rect.bottomLeft, rect.topLeft, paint);
  }

  void _dashedLine(Canvas canvas, Offset from, Offset to, Paint paint) {
    final total = (to - from).distance;
    if (total == 0) return;
    final unit = (to - from) / total;

    var travelled = 0.0;
    while (travelled < total) {
      final end = (travelled + _dash).clamp(0.0, total);
      canvas.drawLine(from + unit * travelled, from + unit * end, paint);
      travelled = end + _gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

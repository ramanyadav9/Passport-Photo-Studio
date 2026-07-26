import 'package:flutter/material.dart';

import '../models/source_photo.dart';
import '../theme.dart';

/// One photo in the strip. Tapping selects it for cropping; the × removes it.
class PhotoThumbnail extends StatelessWidget {
  const PhotoThumbnail({
    required this.photo,
    required this.isActive,
    required this.position,
    required this.total,
    required this.onSelect,
    required this.onRemove,
    super.key,
  });

  final SourcePhoto photo;
  final bool isActive;

  /// 1-based, for a spoken label the user can make sense of.
  final int position;
  final int total;

  final VoidCallback onSelect;
  final VoidCallback onRemove;

  static const width = 110.0;
  static const height = 140.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Semantics(
              button: true,
              selected: isActive,
              label: 'Photo $position of $total'
                  '${isActive ? ', selected' : ''}',
              child: GestureDetector(
                onTap: onSelect,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLowest,
                    borderRadius: BorderRadius.circular(AppRadii.chip),
                    border: Border.all(
                      color: isActive
                          ? AppColors.primary
                          : AppColors.outlineVariant,
                      width: isActive ? 3 : 1.5,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.memory(
                    photo.bytes,
                    fit: BoxFit.cover,
                    // Decoding at thumbnail size keeps a strip of camera-sized
                    // JPEGs from eating memory on a budget phone.
                    cacheWidth: (width * 3).round(),
                    gaplessPlayback: true,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: -6,
            right: -6,
            child: Semantics(
              button: true,
              label: 'Remove photo $position',
              child: InkWell(
                onTap: onRemove,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLowest,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 20,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The dashed "Add More" tile that sits at the end of the strip.
class AddMoreTile extends StatelessWidget {
  const AddMoreTile({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Add more photos',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.chip),
        child: DottedBorderBox(
          width: PhotoThumbnail.width,
          height: PhotoThumbnail.height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add, size: 28, color: AppColors.onSurfaceVariant),
              const SizedBox(height: 4),
              Text(
                'Add More',
                style: Theme.of(context).textTheme.labelMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A dashed-outline container. Flutter has no dashed border, so this paints one.
class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({
    required this.width,
    required this.height,
    required this.child,
    super.key,
  });

  final double width;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRectPainter(),
      child: SizedBox(width: width, height: height, child: child),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  static const _dash = 6.0;
  static const _gap = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.outlineVariant
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(AppRadii.chip),
    );

    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + _dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

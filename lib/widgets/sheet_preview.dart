import 'package:flutter/material.dart';

import '../layout/packing.dart';
import '../models/source_photo.dart';
import '../theme.dart';
import 'cropped_photo.dart';

/// Renders a sheet at whatever size it is given, scaling millimetres to
/// logical pixels. The page always keeps the real paper's aspect ratio, so the
/// shape on screen is the shape that comes out of the printer.
class SheetPreview extends StatelessWidget {
  const SheetPreview({
    required this.layout,
    required this.photoFor,
    this.tileBuilder,
    this.overlay,
    super.key,
  });

  final SheetLayout layout;
  final SourcePhoto? Function(String photoId) photoFor;

  /// Wraps each placed tile — used on the print screen to make tiles
  /// draggable. Given the mm-to-pixel scale so a gesture in pixels can be
  /// converted straight back into page millimetres. Null renders tiles plain.
  final Widget Function(
    BuildContext context,
    String tileId,
    double scale,
    Widget child,
  )?
  tileBuilder;

  /// Painted above the tiles, given the same mm-to-pixel scale.
  final Widget Function(BuildContext context, double scale)? overlay;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: layout.tiles.isEmpty
          ? 'Empty sheet'
          : 'Sheet with ${layout.tiles.length} photos',
      child: AspectRatio(
        aspectRatio: layout.pageMm.width / layout.pageMm.height,
        child: LayoutBuilder(
        builder: (context, constraints) {
          // One number converts every millimetre on this page to pixels.
          final scale = constraints.maxWidth / layout.pageMm.width;

          return DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                for (final tile in layout.tiles)
                  Positioned(
                    left: tile.positionMm.dx * scale,
                    top: tile.positionMm.dy * scale,
                    width: layout.tileSizeMm.width * scale,
                    height: layout.tileSizeMm.height * scale,
                    child: Builder(
                      builder: (context) {
                        final child = _TileContent(
                          photo: photoFor(tile.sourcePhotoId),
                          size: Size(
                            layout.tileSizeMm.width * scale,
                            layout.tileSizeMm.height * scale,
                          ),
                        );
                        return tileBuilder?.call(
                              context,
                              tile.id,
                              scale,
                              child,
                            ) ??
                            child;
                      },
                    ),
                  ),
                if (overlay != null)
                  Positioned.fill(
                    child: IgnorePointer(child: overlay!(context, scale)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TileContent extends StatelessWidget {
  const _TileContent({required this.photo, required this.size});

  final SourcePhoto? photo;
  final Size size;

  @override
  Widget build(BuildContext context) {
    if (photo == null) {
      return ColoredBox(
        color: AppColors.surfaceContainer,
        child: const SizedBox.expand(),
      );
    }
    return CroppedPhoto(
      photo: photo!,
      window: size,
      // A preview never needs full camera resolution.
      cacheWidth: (size.width * 2).round().clamp(64, 1200),
    );
  }
}

/// Shown instead of the sheet when nothing can be laid out.
class SheetPlaceholder extends StatelessWidget {
  const SheetPlaceholder({
    required this.aspectRatio,
    required this.message,
    super.key,
  });

  final double aspectRatio;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.stackMd),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLg.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

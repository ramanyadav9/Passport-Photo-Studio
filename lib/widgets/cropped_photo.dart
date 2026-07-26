import 'package:flutter/material.dart';

import '../models/source_photo.dart';

/// Draws a photo framed by its own [CropTransform], filling [window] exactly.
///
/// The arithmetic mirrors [CropTransform.sourceRect] so the crop editor, the
/// sheet preview and the PDF all show the same crop. Used everywhere a cropped
/// photo appears, so there is only one place for that to go wrong.
class CroppedPhoto extends StatelessWidget {
  const CroppedPhoto({
    required this.photo,
    required this.window,
    this.cacheWidth,
    super.key,
  });

  final SourcePhoto photo;
  final Size window;

  /// Decode width, for strips and previews where full resolution is wasted.
  final int? cacheWidth;

  @override
  Widget build(BuildContext context) {
    final t = photo.transform;

    // Work in the photo's rotated dimensions, so a sideways photo frames the
    // same way an upright one does.
    final sourceW = photo.effectiveWidth;
    final sourceH = photo.effectiveHeight;

    final byWidth = window.width / sourceW;
    final byHeight = window.height / sourceH;
    final effective = (byWidth > byHeight ? byWidth : byHeight) * t.scale;

    final displayW = sourceW * effective;
    final displayH = sourceH * effective;

    return ClipRect(
      child: SizedBox(
        width: window.width,
        height: window.height,
        child: Stack(
          children: [
            Positioned(
              left: (window.width - displayW) / 2 + t.offset.dx * window.width,
              top: (window.height - displayH) / 2 + t.offset.dy * window.height,
              width: displayW,
              height: displayH,
              // RotatedBox swaps the constraints it passes down, so the image
              // is laid out at its natural orientation and drawn turned.
              child: RotatedBox(
                quarterTurns: t.quarterTurns,
                child: Image.memory(
                  photo.bytes,
                  fit: BoxFit.fill,
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.medium,
                  cacheWidth: cacheWidth,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

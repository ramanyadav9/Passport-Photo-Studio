import 'dart:ui' show Offset, Rect;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import 'photo_spec.dart';

/// How one photo is framed inside the crop window.
///
/// Deliberately resolution-independent: [scale] multiplies a "cover" fit, and
/// [offset] is a fraction of the crop window's own size. The framing therefore
/// survives a change of photo size — switching 35x45 to 2x2in re-applies the
/// same framing to the new aspect ratio instead of resetting it — and the same
/// numbers drive both the on-screen preview and the print-resolution export.
@immutable
class CropTransform {
  const CropTransform({
    this.scale = 1,
    this.offset = Offset.zero,
    this.quarterTurns = 0,
  });

  /// 1.0 exactly covers the crop window. Never below 1, or the printed photo
  /// would have blank edges.
  final double scale;

  /// Pan, as a fraction of crop window width and height.
  final Offset offset;

  /// Clockwise rotation in quarter turns, 0 to 3. Applied before cropping, so
  /// a sideways photo is straightened first and framed second.
  final int quarterTurns;

  /// True when the rotation swaps the photo's width and height.
  bool get isSideways => quarterTurns.isOdd;

  static const identity = CropTransform();

  static const minScale = 1.0;
  static const maxScale = 6.0;

  CropTransform copyWith({double? scale, Offset? offset, int? quarterTurns}) =>
      CropTransform(
        scale: scale ?? this.scale,
        offset: offset ?? this.offset,
        quarterTurns: quarterTurns ?? this.quarterTurns,
      );

  CropTransform rotatedClockwise() =>
      copyWith(quarterTurns: (quarterTurns + 1) % 4);

  /// The source rectangle, in image pixels, visible through a crop window of
  /// [windowAspect] (width/height) over an image of [imageWidth]x[imageHeight].
  ///
  /// This is the one function that turns a gesture into print geometry, so the
  /// preview and the PDF cannot disagree about what was cropped.
  Rect sourceRect({
    required double imageWidth,
    required double imageHeight,
    required double windowAspect,
  }) {
    // Any window size works; only its ratio matters.
    const windowW = 1000.0;
    final windowH = windowW / windowAspect;

    final effective =
        _coverScale(
          imageWidth: imageWidth,
          imageHeight: imageHeight,
          windowW: windowW,
          windowH: windowH,
        ) *
        scale;

    final displayW = imageWidth * effective;
    final displayH = imageHeight * effective;

    // Top-left of the drawn image, in window coordinates.
    final left = (windowW - displayW) / 2 + offset.dx * windowW;
    final top = (windowH - displayH) / 2 + offset.dy * windowH;

    return Rect.fromLTWH(
      -left / effective,
      -top / effective,
      windowW / effective,
      windowH / effective,
    );
  }

  /// Clamps zoom and pan so the image always covers the window.
  CropTransform clamped({
    required double imageWidth,
    required double imageHeight,
    required double windowAspect,
  }) {
    final s = scale.clamp(minScale, maxScale);

    const windowW = 1000.0;
    final windowH = windowW / windowAspect;
    final effective =
        _coverScale(
          imageWidth: imageWidth,
          imageHeight: imageHeight,
          windowW: windowW,
          windowH: windowH,
        ) *
        s;

    // Slack is how far the image may move before an edge shows through.
    final slackX = (imageWidth * effective - windowW) / 2 / windowW;
    final slackY = (imageHeight * effective - windowH) / 2 / windowH;

    return CropTransform(
      scale: s,
      offset: Offset(
        offset.dx.clamp(-slackX, slackX),
        offset.dy.clamp(-slackY, slackY),
      ),
      quarterTurns: quarterTurns,
    );
  }

  static double _coverScale({
    required double imageWidth,
    required double imageHeight,
    required double windowW,
    required double windowH,
  }) {
    final byWidth = windowW / imageWidth;
    final byHeight = windowH / imageHeight;
    return byWidth > byHeight ? byWidth : byHeight;
  }
}

/// A photo the user added, carrying its own independent crop state.
class SourcePhoto {
  SourcePhoto({
    required this.id,
    required this.bytes,
    required this.width,
    required this.height,
    this.transform = CropTransform.identity,
  });

  final String id;
  final Uint8List bytes;

  /// Intrinsic pixel dimensions, as stored in the file.
  final double width;
  final double height;

  /// Dimensions as the user sees them, after any rotation. Everything that
  /// frames or crops the photo works in these, so a rotated photo behaves
  /// exactly like one that arrived the right way up.
  double get effectiveWidth => transform.isSideways ? height : width;
  double get effectiveHeight => transform.isSideways ? width : height;

  /// Mutable so panning a photo never rebuilds the whole photo list.
  CropTransform transform;

  /// Reads the intrinsic size without holding a decoded image in memory —
  /// these are camera-sized JPEGs and a studio may add several.
  static Future<SourcePhoto> fromBytes(String id, Uint8List bytes) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    final photo = SourcePhoto(
      id: id,
      bytes: bytes,
      width: descriptor.width.toDouble(),
      height: descriptor.height.toDouble(),
    );
    descriptor.dispose();
    return photo;
  }

  /// The visible rectangle, in pixels of the *rotated* image.
  Rect sourceRectFor(PhotoSpec spec) => transform.sourceRect(
    imageWidth: effectiveWidth,
    imageHeight: effectiveHeight,
    windowAspect: spec.aspectRatio,
  );

  /// Re-clamps this photo's framing against a crop window of [spec].
  /// Rotating or changing photo size both alter how much slack a pan has.
  void reclamp(PhotoSpec spec) {
    transform = transform.clamped(
      imageWidth: effectiveWidth,
      imageHeight: effectiveHeight,
      windowAspect: spec.aspectRatio,
    );
  }
}

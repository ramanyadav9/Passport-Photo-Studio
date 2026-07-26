// Builds the launcher icon from the Stitch logo.
//
// The exported logo is a navy mark on white with a wordmark underneath. A
// launcher icon is tiny, so the wordmark is dropped and the mark alone is
// used, reversed to white on navy so it reads on any wallpaper.
//
// Run with: dart run tool/make_icon.dart
import 'dart:io';

import 'package:image/image.dart' as img;

const navy = 0xFF031632; // AppColors.primary

void main() {
  final source = img.decodePng(
    File(
      'stitch_passport_photo_studio_mobile/stitch_passport_photo_studio_mobile/'
      'passport_photo_studio_logo/screen.png',
    ).readAsBytesSync(),
  )!;

  final bounds = _markBounds(source);
  stdout.writeln('mark bounds: $bounds');

  final mark = img.copyCrop(
    source,
    x: bounds.$1,
    y: bounds.$2,
    width: bounds.$3,
    height: bounds.$4,
  );

  // A square canvas with the mark inset, so it survives the circular and
  // squircle masks different launchers apply.
  const size = 1024;

  _write(
    'assets/icon/icon.png',
    _compose(_fit(mark, size, 0.70), size, background: navy),
  );
  _write(
    'assets/icon/icon_foreground.png',
    // Adaptive icons mask the outer ~25%, so the foreground needs more air.
    _compose(_fit(mark, size, 0.50), size, background: 0x00000000),
  );
}

/// Scales the mark so its longer edge occupies [fraction] of the canvas. The
/// mark is taller than it is wide, so fitting by width alone would leave it
/// looking lost.
img.Image _fit(img.Image mark, int size, double fraction) {
  final target = size * fraction;
  final scale = mark.width > mark.height
      ? target / mark.width
      : target / mark.height;

  return img.copyResize(
    mark,
    width: (mark.width * scale).round(),
    height: (mark.height * scale).round(),
    interpolation: img.Interpolation.cubic,
  );
}

/// The bounding box of the dark pixels above the wordmark.
(int, int, int, int) _markBounds(img.Image src) {
  var minX = src.width, minY = src.height, maxX = 0, maxY = 0;

  // The wordmark starts around 69% down; stop above it so its ascenders are
  // not mistaken for part of the mark.
  final limit = (src.height * 0.67).round();

  for (var y = 0; y < limit; y++) {
    for (var x = 0; x < src.width; x++) {
      final p = src.getPixel(x, y);
      if (p.r < 160 && p.g < 160 && p.b < 160) {
        if (x < minX) minX = x;
        if (y < minY) minY = y;
        if (x > maxX) maxX = x;
        if (y > maxY) maxY = y;
      }
    }
  }
  return (minX, minY, maxX - minX + 1, maxY - minY + 1);
}

/// Reverses the mark to white and centres it on [background].
img.Image _compose(img.Image mark, int size, {required int background}) {
  final canvas = img.Image(width: size, height: size, numChannels: 4);
  img.fill(canvas, color: _color(background));

  final left = (size - mark.width) ~/ 2;
  final top = (size - mark.height) ~/ 2;

  for (var y = 0; y < mark.height; y++) {
    for (var x = 0; x < mark.width; x++) {
      final p = mark.getPixel(x, y);
      // Dark ink becomes white; the paper behind it stays as the background.
      final ink = 255 - ((p.r + p.g + p.b) / 3).round();
      if (ink > 40) {
        canvas.setPixelRgba(left + x, top + y, 255, 255, 255, ink);
      }
    }
  }
  return canvas;
}

img.ColorRgba8 _color(int argb) => img.ColorRgba8(
  (argb >> 16) & 0xFF,
  (argb >> 8) & 0xFF,
  argb & 0xFF,
  (argb >> 24) & 0xFF,
);

void _write(String path, img.Image image) {
  final file = File(path)..createSync(recursive: true);
  file.writeAsBytesSync(img.encodePng(image));
  stdout.writeln('wrote $path');
}

import 'dart:ui' show Offset, Rect, Size;

/// One printed photo on the sheet.
///
/// [positionMm] is the tile's top-left corner on the page, in millimetres —
/// the same units the PDF is written in, so a tile's position on screen and on
/// paper are the same number.
class Tile {
  Tile({
    required this.id,
    required this.sourcePhotoId,
    required this.positionMm,
  });

  final String id;

  /// Which photo fills this slot. Mutable: tapping a tile cycles it to the
  /// next photo, which is how one sheet holds several different people.
  String sourcePhotoId;

  /// Mutable: the user may drag tiles anywhere on the sheet.
  Offset positionMm;

  Rect rectMm(Size sizeMm) => Rect.fromLTWH(
    positionMm.dx,
    positionMm.dy,
    sizeMm.width,
    sizeMm.height,
  );

  Tile copyWith({String? sourcePhotoId, Offset? positionMm}) => Tile(
    id: id,
    sourcePhotoId: sourcePhotoId ?? this.sourcePhotoId,
    positionMm: positionMm ?? this.positionMm,
  );
}

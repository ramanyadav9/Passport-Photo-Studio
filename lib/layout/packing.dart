import 'dart:ui' show Offset, Rect, Size;

import '../models/paper_spec.dart';
import '../models/photo_spec.dart';
import '../models/tile.dart';

/// The grid shape a copy count resolves to.
typedef Grid = ({int columns, int rows});

/// Breathing room between photos, in millimetres.
///
/// Photos packed edge to edge leave nothing to cut along — a hand-cut sheet
/// needs a little slack or every slip eats into the neighbouring photo. Small
/// enough that it costs no photos per sheet at the common sizes.
const defaultTileGapMm = 2.0;

/// Everything the preview and the PDF need to draw a sheet. Millimetres
/// throughout — no pixels, no DPI.
class SheetLayout {
  const SheetLayout({
    required this.pageMm,
    required this.usableMm,
    required this.tileSizeMm,
    required this.tiles,
  });

  final Size pageMm;

  /// The area tiles may occupy, after the page origin inset.
  final Rect usableMm;

  final Size tileSizeMm;
  final List<Tile> tiles;

  /// Gap between neighbouring photos, so the preview, the drag sheet and the
  /// PDF all space tiles the same way.
  double get gapMm => defaultTileGapMm;

  bool get isEmpty => tiles.isEmpty;

  /// True when even one photo cannot fit — the caller should say so rather
  /// than silently print a blank sheet.
  bool get photoTooLarge =>
      tileSizeMm.width > usableMm.width || tileSizeMm.height > usableMm.height;
}

/// The usable area of a sheet once the page origin is applied.
Rect usableArea(PaperSpec paper, PageOrigin origin) {
  final inset = origin.insetMm;
  return Rect.fromLTWH(
    inset,
    inset,
    paper.widthMm - inset * 2,
    paper.heightMm - inset * 2,
  );
}

/// How many tiles physically fit, allowing a gap between neighbours.
///
/// The gap only falls *between* photos, never outside the outermost ones, so
/// the arithmetic adds one gap to the available space and divides by the tile
/// plus its trailing gap.
int maxFit(Size tileMm, Rect usableMm, {double gapMm = defaultTileGapMm}) {
  final cols = _fitCount(usableMm.width, tileMm.width, gapMm);
  final rows = _fitCount(usableMm.height, tileMm.height, gapMm);
  return cols * rows;
}

int _fitCount(double available, double tile, double gap) {
  if (tile <= 0 || available < tile) return 0;
  return ((available + gap) / (tile + gap)).floor();
}

/// Resolves a copy count into a grid shape.
///
/// A preset count fixes the column count rather than packing as many across as
/// physically fit. That is what makes 6 come out as the studio-standard
/// 3-across by 2-down instead of the 5-then-1 that pure max-fit packing gives.
///
/// The shape chosen is the factor pair of [count] closest to square, preferring
/// wider than tall, that still fits the page. If no factor pair fits, the grid
/// falls back to as many columns and rows as do fit.
Grid gridFor(
  int count,
  Size tileMm,
  Rect usableMm, {
  double gapMm = defaultTileGapMm,
}) {
  final maxCols = _fitCount(usableMm.width, tileMm.width, gapMm);
  final maxRows = _fitCount(usableMm.height, tileMm.height, gapMm);

  if (maxCols < 1 || maxRows < 1) return (columns: 0, rows: 0);

  final pairs = <Grid>[
    for (var c = 1; c <= count; c++)
      if (count % c == 0) (columns: c, rows: count ~/ c),
  ]..sort((a, b) {
    final squareness = (a.columns - a.rows).abs().compareTo(
      (b.columns - b.rows).abs(),
    );
    if (squareness != 0) return squareness;
    // Tie-break wider rather than taller: a sheet is read across first.
    return b.columns.compareTo(a.columns);
  });

  for (final pair in pairs) {
    if (pair.columns <= maxCols && pair.rows <= maxRows) return pair;
  }

  // Nothing factors into the page; use everything available.
  return (columns: maxCols, rows: maxRows);
}

/// Builds the default arrangement: packed flush from the top-left of the usable
/// area, filling left to right, then wrapping to the next row.
///
/// With several photos added, slots are filled round-robin, so two people on a
/// 6-grid get three copies each.
SheetLayout packSheet({
  required PaperSpec paper,
  required PhotoSpec photo,
  required PageOrigin origin,
  required int? copies,
  required List<String> photoIds,
  double gapMm = defaultTileGapMm,
}) {
  final usable = usableArea(paper, origin);
  final tileSize = Size(photo.widthMm, photo.heightMm);

  final fits = maxFit(tileSize, usable, gapMm: gapMm);

  // A null copy count means "fill the sheet".
  final requested = copies ?? fits;
  final count = requested.clamp(0, fits);

  final grid = copies == null
      ? (
          columns: _fitCount(usable.width, tileSize.width, gapMm),
          rows: _fitCount(usable.height, tileSize.height, gapMm),
        )
      : gridFor(count, tileSize, usable, gapMm: gapMm);

  final columns = grid.columns;

  // Step by the tile plus one gap; the gap therefore sits between photos and
  // never adds a margin outside the block.
  final stepX = tileSize.width + gapMm;
  final stepY = tileSize.height + gapMm;

  final tiles = <Tile>[
    if (columns > 0 && photoIds.isNotEmpty)
      for (var i = 0; i < count; i++)
        Tile(
          id: 'tile-$i',
          sourcePhotoId: photoIds[i % photoIds.length],
          positionMm: Offset(
            usable.left + (i % columns) * stepX,
            usable.top + (i ~/ columns) * stepY,
          ),
        ),
  ];

  return SheetLayout(
    pageMm: Size(paper.widthMm, paper.heightMm),
    usableMm: usable,
    tileSizeMm: tileSize,
    tiles: tiles,
  );
}

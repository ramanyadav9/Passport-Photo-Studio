import 'dart:ui' show Offset, Rect;

import 'packing.dart' show defaultTileGapMm;

/// Which way a guide line runs.
enum SnapAxis {
  /// A vertical line at a fixed x — edges and centres line up left to right.
  x,

  /// A horizontal line at a fixed y.
  y,
}

/// A line to draw while dragging, because the dragged tile is aligned to it.
class SnapGuide {
  const SnapGuide(this.axis, this.positionMm);

  final SnapAxis axis;
  final double positionMm;

  @override
  bool operator ==(Object other) =>
      other is SnapGuide &&
      other.axis == axis &&
      (other.positionMm - positionMm).abs() < 0.001;

  @override
  int get hashCode => Object.hash(axis, positionMm.round());

  @override
  String toString() => 'SnapGuide($axis, ${positionMm}mm)';
}

class SnapResult {
  const SnapResult(this.positionMm, this.guides);

  /// Where the tile should actually go — snapped if anything was in range.
  final Offset positionMm;

  /// Lines to draw. Empty when nothing aligned.
  final List<SnapGuide> guides;

  bool get snapped => guides.isNotEmpty;
}

/// Default snap distance. About the width of a pencil line at print size —
/// close enough to feel magnetic, far enough not to fight the user.
const defaultSnapThresholdMm = 2.0;

/// Aligns a dragged tile to its neighbours and to the page, the way Word and
/// PowerPoint do: each of the tile's three edges in an axis (near edge, centre,
/// far edge) is tested against the same three lines on every other tile, plus
/// the page's own edges and centre.
///
/// The tile is first kept inside [page], so dragging can never push a photo off
/// the sheet and have it print clipped.
///
/// Pure arithmetic in millimetres — no widgets, no pixels — so the behaviour
/// can be tested exactly.
SnapResult snapTile({
  required Rect dragged,
  required Iterable<Rect> others,
  required Rect page,
  double thresholdMm = defaultSnapThresholdMm,
  double gapMm = defaultTileGapMm,
}) {
  // Keep the tile on the page first; snapping then refines from a legal spot.
  final clamped = Offset(
    dragged.left.clamp(page.left, page.right - dragged.width),
    dragged.top.clamp(page.top, page.bottom - dragged.height),
  );
  final rect = Rect.fromLTWH(
    clamped.dx,
    clamped.dy,
    dragged.width,
    dragged.height,
  );

  final xTargets = <double>[page.left, page.center.dx, page.right];
  final yTargets = <double>[page.top, page.center.dy, page.bottom];

  // Where the tile's near edge may rest to sit one neat gap from a neighbour,
  // and likewise its far edge. Without these, dragging would butt photos
  // together and lose the cutting room the default grid leaves.
  final xGapForNear = <double>[];
  final xGapForFar = <double>[];
  final yGapForNear = <double>[];
  final yGapForFar = <double>[];

  for (final other in others) {
    xTargets.addAll([other.left, other.center.dx, other.right]);
    yTargets.addAll([other.top, other.center.dy, other.bottom]);

    xGapForNear.add(other.right + gapMm);
    xGapForFar.add(other.left - gapMm);
    yGapForNear.add(other.bottom + gapMm);
    yGapForFar.add(other.top - gapMm);
  }

  final dx = _bestAdjustment(
    edges: [rect.left, rect.center.dx, rect.right],
    targets: xTargets,
    nearEdge: rect.left,
    nearTargets: xGapForNear,
    farEdge: rect.right,
    farTargets: xGapForFar,
    thresholdMm: thresholdMm,
  );
  final dy = _bestAdjustment(
    edges: [rect.top, rect.center.dy, rect.bottom],
    targets: yTargets,
    nearEdge: rect.top,
    nearTargets: yGapForNear,
    farEdge: rect.bottom,
    farTargets: yGapForFar,
    thresholdMm: thresholdMm,
  );

  final snapped = Rect.fromLTWH(
    rect.left + dx,
    rect.top + dy,
    rect.width,
    rect.height,
  );

  // Report every line the tile ended up sitting on, so two guides show when a
  // tile lands in a corner formed by two neighbours.
  final guides = <SnapGuide>[
    ..._matches(SnapAxis.x, [
      snapped.left,
      snapped.center.dx,
      snapped.right,
    ], [...xTargets, ...xGapForNear, ...xGapForFar]),
    ..._matches(SnapAxis.y, [
      snapped.top,
      snapped.center.dy,
      snapped.bottom,
    ], [...yTargets, ...yGapForNear, ...yGapForFar]),
  ];

  return SnapResult(Offset(snapped.left, snapped.top), guides);
}

/// The smallest shift bringing any edge onto any target, or zero if none is
/// within the threshold.
///
/// [edges] are matched against [targets] freely — any edge to any line. The
/// gap targets are narrower: only the near edge may rest a gap past a
/// neighbour's far side, and only the far edge a gap before its near side.
/// Letting a centre line snap to a gap offset would produce alignments nobody
/// asked for.
double _bestAdjustment({
  required List<double> edges,
  required List<double> targets,
  required double nearEdge,
  required List<double> nearTargets,
  required double farEdge,
  required List<double> farTargets,
  required double thresholdMm,
}) {
  var best = 0.0;
  var bestDistance = double.infinity;

  void consider(double edge, double target) {
    final delta = target - edge;
    final distance = delta.abs();
    if (distance <= thresholdMm && distance < bestDistance) {
      bestDistance = distance;
      best = delta;
    }
  }

  for (final edge in edges) {
    for (final target in targets) {
      consider(edge, target);
    }
  }
  for (final target in nearTargets) {
    consider(nearEdge, target);
  }
  for (final target in farTargets) {
    consider(farEdge, target);
  }

  return best;
}

List<SnapGuide> _matches(
  SnapAxis axis,
  List<double> edges,
  List<double> targets,
) {
  final found = <SnapGuide>{};
  for (final edge in edges) {
    for (final target in targets) {
      if ((target - edge).abs() < 0.01) found.add(SnapGuide(axis, target));
    }
  }
  return found.toList();
}

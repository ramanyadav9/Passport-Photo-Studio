import 'package:flutter/material.dart';

import '../layout/snapping.dart';
import '../state/studio_state.dart';
import '../theme.dart';
import 'sheet_preview.dart';

/// The sheet on the final screen: every tile can be dragged anywhere, snapping
/// to its neighbours and to the page, and a tap swaps which photo fills a slot.
class DraggableSheet extends StatefulWidget {
  const DraggableSheet({required this.state, super.key});

  final StudioState state;

  @override
  State<DraggableSheet> createState() => _DraggableSheetState();
}

class _DraggableSheetState extends State<DraggableSheet> {
  /// Guides currently showing. Only non-empty mid-drag.
  List<SnapGuide> _guides = const [];

  String? _draggingId;

  /// Position at the moment the drag began, so the tile follows the finger
  /// exactly instead of drifting by accumulated rounding.
  Offset _startMm = Offset.zero;
  Offset _accumulated = Offset.zero;

  void _onDragStart(String tileId) {
    final tile = widget.state.tiles.firstWhere((t) => t.id == tileId);
    setState(() {
      _draggingId = tileId;
      _startMm = tile.positionMm;
      _accumulated = Offset.zero;
    });
  }

  void _onDragUpdate(String tileId, Offset deltaPixels, double scale) {
    final layout = widget.state.layout;
    _accumulated += deltaPixels / scale;

    final proposed = Rect.fromLTWH(
      _startMm.dx + _accumulated.dx,
      _startMm.dy + _accumulated.dy,
      layout.tileSizeMm.width,
      layout.tileSizeMm.height,
    );

    final result = snapTile(
      dragged: proposed,
      others: [
        for (final tile in layout.tiles)
          if (tile.id != tileId) tile.rectMm(layout.tileSizeMm),
      ],
      page: layout.usableMm,
    );

    widget.state.moveTile(tileId, result.positionMm);
    setState(() => _guides = result.guides);
  }

  void _onDragEnd() {
    setState(() {
      _guides = const [];
      _draggingId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    return SheetPreview(
      layout: state.layout,
      photoFor: state.photoById,
      overlay: (context, scale) => CustomPaint(
        painter: _GuidePainter(guides: _guides, scale: scale),
      ),
      tileBuilder: (context, tileId, scale, child) {
        final isDragging = tileId == _draggingId;

        return Semantics(
          label: state.photos.length > 1
              ? 'Photo slot. Drag to move, tap to change which photo goes here.'
              : 'Photo slot. Drag to move.',
          child: GestureDetector(
            // A plain tap cycles the slot; anything more is a drag. Flutter's
            // gesture arena tells the two apart, so there is no threshold to
            // tune by hand.
            onTap: () => state.cycleTilePhoto(tileId),
            onPanStart: (_) => _onDragStart(tileId),
            onPanUpdate: (d) => _onDragUpdate(tileId, d.delta, scale),
            onPanEnd: (_) => _onDragEnd(),
            onPanCancel: _onDragEnd,
            child: Stack(
              fit: StackFit.expand,
              children: [
                child,
                if (isDragging)
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.fromBorderSide(
                        BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Thin dashed lines in the guide red, drawn the full width or height of the
/// page wherever the dragged tile has aligned to something.
class _GuidePainter extends CustomPainter {
  _GuidePainter({required this.guides, required this.scale});

  final List<SnapGuide> guides;
  final double scale;

  static const _dash = 5.0;
  static const _gap = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (guides.isEmpty) return;

    final paint = Paint()
      ..color = AppColors.guide
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (final guide in guides) {
      final at = guide.positionMm * scale;
      final (from, to) = switch (guide.axis) {
        SnapAxis.x => (Offset(at, 0), Offset(at, size.height)),
        SnapAxis.y => (Offset(0, at), Offset(size.width, at)),
      };
      _dashedLine(canvas, from, to, paint);
    }
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
  bool shouldRepaint(covariant _GuidePainter old) =>
      old.guides != guides || old.scale != scale;
}

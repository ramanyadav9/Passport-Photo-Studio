import 'dart:ui' show Offset, Size;

import 'package:flutter/foundation.dart';

import '../layout/packing.dart';
import '../models/paper_spec.dart';
import '../models/photo_spec.dart';
import '../models/source_photo.dart';
import '../models/tile.dart';

/// The four steps of the workflow, in order.
enum WorkflowStep {
  add('Add'),
  adjust('Adjust'),
  layout('Layout'),
  print('Print');

  const WorkflowStep(this.label);

  final String label;

  /// 1-based, for the numbered stepper.
  int get number => index + 1;
}

/// How many copies land on the sheet.
///
/// A preset count also fixes the column count, so 6 packs as 3x2 rather than
/// the 5+1 that pure max-fit packing would give. [fill] instead packs as many
/// as physically fit.
enum CopyCount {
  four('4', 4),
  six('6', 6),
  eight('8', 8),
  fill('Fill', null);

  const CopyCount(this.label, this.count);

  final String label;

  /// Null for [fill], where the count is computed from the page.
  final int? count;
}

/// Single source of truth for the whole app. Deliberately one object: the app
/// is small, and a walk-in-customer workflow has no state worth splitting.
///
/// Nothing here is persisted. Each launch starts clean, so a previous
/// customer's face never lingers in the app.
class StudioState extends ChangeNotifier {
  WorkflowStep _step = WorkflowStep.add;
  PhotoSpec _photoSpec = PhotoSpec.passport35x45;
  PaperSpec _paper = PaperSpec.a4;
  CopyCount _copies = CopyCount.six;
  PageOrigin _origin = PageOrigin.printableArea;

  final List<SourcePhoto> _photos = [];
  final List<Tile> _tiles = [];
  String? _activePhotoId;
  var _nextPhotoNumber = 0;

  WorkflowStep get step => _step;
  PhotoSpec get photoSpec => _photoSpec;
  PaperSpec get paper => _paper;
  CopyCount get copies => _copies;
  PageOrigin get origin => _origin;

  List<SourcePhoto> get photos => List.unmodifiable(_photos);
  bool get hasPhotos => _photos.isNotEmpty;

  String? get activePhotoId => _activePhotoId;

  /// The photo the crop editor is working on. Null only when nothing is added.
  SourcePhoto? get activePhoto {
    if (_photos.isEmpty) return null;
    return _photos.firstWhere(
      (p) => p.id == _activePhotoId,
      orElse: () => _photos.first,
    );
  }

  void addPhotos(Iterable<SourcePhoto> added) {
    if (added.isEmpty) return;
    _photos.addAll(added);
    // The first photo added becomes active, so step 2 always has something to
    // show without the user having to pick anything.
    _activePhotoId ??= _photos.first.id;
    // A new person changes the round-robin, so the sheet is laid out again.
    resetToGrid();
  }

  void removePhoto(String id) {
    _photos.removeWhere((p) => p.id == id);
    if (_activePhotoId == id) {
      _activePhotoId = _photos.isEmpty ? null : _photos.first.id;
    }
    resetToGrid();
  }

  void setActivePhoto(String id) {
    if (_activePhotoId == id) return;
    _activePhotoId = id;
    notifyListeners();
  }

  /// Records a new crop for the active photo. Each photo keeps its own
  /// transform, so switching between thumbnails never disturbs the others.
  void updateActiveTransform(CropTransform transform) {
    final photo = activePhoto;
    if (photo == null || photo.transform == transform) return;
    photo.transform = transform;
    notifyListeners();
  }

  /// Turns the active photo a quarter turn clockwise.
  ///
  /// Rotation changes which way the photo is taller, so the pan is re-clamped
  /// against the crop window afterwards rather than left hanging off an edge.
  void rotateActivePhoto() {
    final photo = activePhoto;
    if (photo == null) return;
    photo.transform = photo.transform.rotatedClockwise();
    photo.reclamp(_photoSpec);
    notifyListeners();
  }

  /// Stable, human-meaningful ids — used in semantics labels ("Photo 2 of 3").
  String nextPhotoId() => 'photo-${_nextPhotoNumber++}';

  void goToStep(WorkflowStep step) {
    if (_step == step) return;
    _step = step;
    notifyListeners();
  }

  void nextStep() {
    final next = _step.index + 1;
    if (next < WorkflowStep.values.length) {
      goToStep(WorkflowStep.values[next]);
    }
  }

  void setPhotoSpec(PhotoSpec spec) {
    if (_photoSpec == spec) return;
    _photoSpec = spec;

    // A new aspect ratio can leave an existing pan hanging off the edge, which
    // would print a blank strip. Re-clamp every photo against the new window;
    // the framing is preserved, only the illegal part of the pan is pulled in.
    for (final photo in _photos) {
      photo.reclamp(spec);
    }

    resetToGrid();
  }

  void setPaper(PaperSpec paper) {
    if (_paper == paper) return;
    _paper = paper;
    resetToGrid();
  }

  void setCopies(CopyCount copies) {
    if (_copies == copies) return;
    _copies = copies;
    resetToGrid();
  }

  void setOrigin(PageOrigin origin) {
    if (_origin == origin) return;
    _origin = origin;
    resetToGrid();
  }

  /// The sheet as currently arranged. Rebuilt from [_tiles] each time so the
  /// preview and the PDF read from one source.
  SheetLayout get layout => SheetLayout(
    pageMm: Size(_paper.widthMm, _paper.heightMm),
    usableMm: usableArea(_paper, _origin),
    tileSizeMm: Size(_photoSpec.widthMm, _photoSpec.heightMm),
    tiles: _tiles,
  );

  List<Tile> get tiles => List.unmodifiable(_tiles);

  /// Restores the default packed arrangement, discarding any dragging.
  void resetToGrid() {
    _tiles
      ..clear()
      ..addAll(
        packSheet(
          paper: _paper,
          photo: _photoSpec,
          origin: _origin,
          copies: _copies.count,
          photoIds: [for (final p in _photos) p.id],
        ).tiles,
      );
    notifyListeners();
  }

  /// Moves a tile to an absolute position on the page, in millimetres.
  void moveTile(String tileId, Offset positionMm) {
    final tile = _tiles.firstWhere((t) => t.id == tileId);
    if (tile.positionMm == positionMm) return;
    tile.positionMm = positionMm;
    notifyListeners();
  }

  /// Cycles a slot to the next photo — the quick way to change who goes where.
  void cycleTilePhoto(String tileId) {
    if (_photos.length < 2) return;
    final tile = _tiles.firstWhere((t) => t.id == tileId);
    final current = _photos.indexWhere((p) => p.id == tile.sourcePhotoId);
    tile.sourcePhotoId = _photos[(current + 1) % _photos.length].id;
    notifyListeners();
  }

  SourcePhoto? photoById(String id) {
    for (final photo in _photos) {
      if (photo.id == id) return photo;
    }
    return null;
  }
}

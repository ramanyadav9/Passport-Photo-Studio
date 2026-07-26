import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../layout/packing.dart';
import '../models/photo_spec.dart';
import '../models/source_photo.dart';

/// Print resolution. 300 DPI is what a photo lab expects and what consumer
/// printers resolve; beyond it the file grows without looking better.
const printDpi = 300.0;

/// Everything one crop job needs, in a form that can cross an isolate boundary.
typedef _CropJob = (
  Uint8List bytes,
  int quarterTurns,
  int srcLeft,
  int srcTop,
  int srcWidth,
  int srcHeight,
  int outWidth,
  int outHeight,
);

/// Builds the printable sheet as a PDF.
///
/// The page is created at the paper's true size and every photo is positioned
/// in millimetres — the same numbers the on-screen preview used. Nothing is
/// rendered to a screenshot and scaled, so there is no resolution to lose and
/// no rounding between what was previewed and what prints.
Future<Uint8List> buildSheetPdf({
  required SheetLayout layout,
  required PhotoSpec spec,
  required SourcePhoto? Function(String photoId) photoFor,
  double dpi = printDpi,
}) async {
  final tileWidthPx = (spec.widthMm / 25.4 * dpi).round();
  final tileHeightPx = (spec.heightMm / 25.4 * dpi).round();

  // Several tiles usually share one photo, so each photo is cropped once and
  // the result reused. On a filled A4 that is one decode instead of thirty.
  final rendered = <String, Uint8List>{};
  for (final tile in layout.tiles) {
    if (rendered.containsKey(tile.sourcePhotoId)) continue;

    final photo = photoFor(tile.sourcePhotoId);
    if (photo == null) continue;

    final source = photo.sourceRectFor(spec);
    rendered[tile.sourcePhotoId] = await compute(_cropToJpeg, (
      photo.bytes,
      photo.transform.quarterTurns,
      source.left.round(),
      source.top.round(),
      source.width.round(),
      source.height.round(),
      tileWidthPx,
      tileHeightPx,
    ));
  }

  final images = {
    for (final entry in rendered.entries)
      entry.key: pw.MemoryImage(entry.value),
  };

  final pageWidth = layout.pageMm.width * PdfPageFormat.mm;
  final pageHeight = layout.pageMm.height * PdfPageFormat.mm;

  final doc = pw.Document(title: 'Passport photos');
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat(pageWidth, pageHeight, marginAll: 0),
      build: (context) => pw.SizedBox(
        width: pageWidth,
        height: pageHeight,
        child: pw.Stack(
          children: [
            for (final tile in layout.tiles)
              if (images[tile.sourcePhotoId] != null)
                pw.Positioned(
                  left: tile.positionMm.dx * PdfPageFormat.mm,
                  top: tile.positionMm.dy * PdfPageFormat.mm,
                  child: pw.Image(
                    images[tile.sourcePhotoId]!,
                    width: layout.tileSizeMm.width * PdfPageFormat.mm,
                    height: layout.tileSizeMm.height * PdfPageFormat.mm,
                    fit: pw.BoxFit.fill,
                  ),
                ),
          ],
        ),
      ),
    ),
  );

  return doc.save();
}

/// Crops one photo to its visible rectangle and scales it to print size.
///
/// Runs on a background isolate: these are camera-sized JPEGs and a studio may
/// have several on one sheet, which would otherwise freeze the interface.
Uint8List _cropToJpeg(_CropJob job) {
  final (bytes, quarterTurns, left, top, width, height, outWidth, outHeight) =
      job;

  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw const PdfExportException('That photo could not be read.');
  }

  // Flutter applies EXIF rotation when it displays an image, so the same must
  // happen here or a phone-camera portrait would print on its side.
  var oriented = img.bakeOrientation(decoded);

  // The user's own rotation is applied before cropping, matching the order the
  // crop rectangle was computed in.
  if (quarterTurns % 4 != 0) {
    oriented = img.copyRotate(oriented, angle: 90 * (quarterTurns % 4));
  }
  final upright = oriented;

  // Rounding the crop rectangle can push it a pixel past the edge.
  final x = left.clamp(0, upright.width - 1);
  final y = top.clamp(0, upright.height - 1);
  final w = width.clamp(1, upright.width - x);
  final h = height.clamp(1, upright.height - y);

  final cropped = img.copyCrop(upright, x: x, y: y, width: w, height: h);
  final resized = img.copyResize(
    cropped,
    width: outWidth,
    height: outHeight,
    interpolation: img.Interpolation.average,
  );

  return img.encodeJpg(resized, quality: 92);
}

/// Raised when a sheet cannot be produced, carrying wording a non-technical
/// user can act on.
class PdfExportException implements Exception {
  const PdfExportException(this.message);

  final String message;

  @override
  String toString() => message;
}

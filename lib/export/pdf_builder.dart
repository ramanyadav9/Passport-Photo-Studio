import 'dart:math' as math;
import 'dart:ui' show Size;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../layout/packing.dart';
import '../models/photo_spec.dart';
import '../models/source_photo.dart';

/// Print resolution.
///
/// 300 is the photographic standard and roughly where the eye stops resolving
/// detail at reading distance, so 450 is not expected to look different on a
/// normal print. It is here as headroom for a sheet that gets enlarged,
/// scanned, or resampled by a professional lab.
///
/// The cost is small and worth knowing: a sheet goes from about 200 kB to
/// about 500 kB, and export takes no longer, because the time goes on decoding
/// the camera photo rather than resizing it. Raising it further buys nothing a
/// consumer printer can put on paper.
const printDpi = 450.0;

/// Thickness of the optional border around each photo. A hairline: thick
/// enough to cut along, thin enough not to eat into the face.
const borderWidthMm = 0.2;

/// Ceiling on the size of a rasterised page, in pixels.
///
/// Rasterising is not printing: the bitmap is built in native memory and
/// copied across the platform channel as raw RGBA, so an A4 page at 450 DPI is
/// 19.6 megapixels, 78 MB of pixels, and asks for roughly 139 MB in a single
/// allocation while the buffer grows. That is an OutOfMemoryError on a real
/// phone, and it kills the process rather than throwing something catchable.
///
/// 8 megapixels is far more than any screen or messaging app needs and leaves
/// generous headroom on a budget device.
const maxRasterPixels = 8000000;

/// The largest DPI that keeps a page of [pageMm] under [maxRasterPixels],
/// never exceeding [requestedDpi].
///
/// Pure arithmetic so the ceiling can be tested without rasterising anything.
double rasterDpiFor(Size pageMm, double requestedDpi) {
  final widthInches = pageMm.width / 25.4;
  final heightInches = pageMm.height / 25.4;
  final squareInches = widthInches * heightInches;
  if (squareInches <= 0) return requestedDpi;

  final fitting = math.sqrt(maxRasterPixels / squareInches);
  return fitting < requestedDpi ? fitting : requestedDpi;
}

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
  bool border = false,
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
                  child: pw.Container(
                    width: layout.tileSizeMm.width * PdfPageFormat.mm,
                    height: layout.tileSizeMm.height * PdfPageFormat.mm,
                    // The border is drawn inside the photo's own rectangle, so
                    // switching it on never moves a photo or changes how many
                    // fit — it only gives the cutter a line to follow.
                    decoration: border
                        ? pw.BoxDecoration(
                            border: pw.Border.all(
                              color: PdfColors.grey600,
                              width: borderWidthMm * PdfPageFormat.mm,
                            ),
                          )
                        : null,
                    child: pw.Image(
                      images[tile.sourcePhotoId]!,
                      fit: pw.BoxFit.fill,
                    ),
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

  // Box averaging is the right filter for shrinking — it takes every source
  // pixel into account, so a 12MP photo reduced to print size stays clean. It
  // is the wrong filter for enlarging, where it blocks up; cubic is smoother.
  // Which way we are going depends on how far the user zoomed in.
  final isEnlarging = outWidth > cropped.width;
  final resized = img.copyResize(
    cropped,
    width: outWidth,
    height: outHeight,
    interpolation: isEnlarging
        ? img.Interpolation.cubic
        : img.Interpolation.average,
  );

  // Full chroma rather than the usual 4:2:0 subsampling. Faces are mostly
  // smooth colour, and halving the colour resolution is exactly the sort of
  // loss that shows on skin at print size. Costs a little file size on a
  // document nobody stores.
  return img.encodeJpg(resized, quality: 95, chroma: img.JpegChroma.yuv444);
}

/// Raised when a sheet cannot be produced, carrying wording a non-technical
/// user can act on.
class PdfExportException implements Exception {
  const PdfExportException(this.message);

  final String message;

  @override
  String toString() => message;
}

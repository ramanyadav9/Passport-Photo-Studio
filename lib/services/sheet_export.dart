import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../export/pdf_builder.dart';
import '../state/studio_state.dart';

/// What the user gets when they choose Save / Share.
enum ExportFormat {
  /// Exact page size, what a printer wants.
  pdf('PDF', 'Best for printing', 'pdf'),

  /// Universally openable, and what messaging apps handle well — a studio
  /// sending a sheet to a print shop usually wants this.
  png('Image', 'Best for sharing', 'png');

  const ExportFormat(this.label, this.hint, this.extension);

  final String label;
  final String hint;
  final String extension;
}

/// Turns the arranged sheet into a document and hands it to the printer or to
/// whatever the user wants to share it with.
///
/// Both paths, and both formats, come from the same PDF, so what is shared is
/// exactly what would have printed.
class SheetExportService {
  const SheetExportService();

  Future<Uint8List> buildPdf(StudioState state) async {
    final layout = state.layout;
    if (layout.isEmpty) {
      throw const PdfExportException(
        'There is nothing to print yet. Add a photo in Step 1.',
      );
    }

    try {
      return await buildSheetPdf(
        layout: layout,
        spec: state.photoSpec,
        photoFor: state.photoById,
        dpi: state.quality.dpi.toDouble(),
        border: state.photoBorder,
      );
    } on PdfExportException {
      rethrow;
    } catch (_) {
      throw const PdfExportException(
        'The sheet could not be prepared. Please try again.',
      );
    }
  }

  /// Opens the system print dialog, so the user can pick whichever printer is
  /// already set up on the phone or network.
  Future<void> print(StudioState state) async {
    final bytes = await buildPdf(state);
    try {
      await Printing.layoutPdf(
        name: _fileName(state, ExportFormat.pdf),
        onLayout: (_) async => bytes,
      );
    } catch (_) {
      throw const PdfExportException(
        'The printer could not be reached. Try "Save / Share" instead and '
        'print from there.',
      );
    }
  }

  /// The way out when there is no printer to hand: save the sheet or send it
  /// to a print shop.
  Future<void> share(StudioState state, ExportFormat format) async {
    final pdf = await buildPdf(state);

    try {
      if (format == ExportFormat.pdf) {
        await Printing.sharePdf(
          bytes: pdf,
          filename: _fileName(state, format),
        );
        return;
      }

      // Rasterised from the same PDF rather than laid out again, so the image
      // cannot disagree with what would have printed.
      //
      // The DPI is capped: rasterising ships the page across the platform
      // channel as raw pixels, and doing that at print resolution runs the
      // process out of memory before any Dart code can catch it.
      final page = await Printing.raster(
        pdf,
        dpi: rasterDpiFor(state.layout.pageMm, state.quality.dpi.toDouble()),
      ).first;
      final png = await page.toPng();

      // Written to a real file. An in-memory XFile with a made-up path leaves
      // the receiving app nothing to open.
      final path =
          '${(await getTemporaryDirectory()).path}/'
          '${_fileName(state, format)}';
      await File(path).writeAsBytes(png, flush: true);

      await SharePlus.instance.share(
        ShareParams(files: [XFile(path, mimeType: 'image/png')]),
      );
    } on PdfExportException {
      rethrow;
    } catch (_) {
      throw const PdfExportException(
        'The sheet could not be shared. Please try again.',
      );
    }
  }

  String _fileName(StudioState state, ExportFormat format) {
    final w = _trim(state.photoSpec.widthMm);
    final h = _trim(state.photoSpec.heightMm);
    return 'passport-photos-${w}x${h}mm-${state.paper.name}.${format.extension}';
  }

  static String _trim(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}

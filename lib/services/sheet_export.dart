import 'dart:typed_data';

import 'package:printing/printing.dart';

import '../export/pdf_builder.dart';
import '../state/studio_state.dart';

/// Turns the arranged sheet into a PDF and hands it to the printer or to
/// whatever the user wants to share it with.
///
/// Both paths use the same document, so what is shared is exactly what would
/// have printed.
class SheetExportService {
  const SheetExportService();

  Future<Uint8List> build(StudioState state) async {
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
    final bytes = await build(state);
    try {
      await Printing.layoutPdf(
        name: _fileName(state),
        onLayout: (_) async => bytes,
      );
    } catch (_) {
      throw const PdfExportException(
        'The printer could not be reached. Try "Save / Share" instead and '
        'print from there.',
      );
    }
  }

  /// The way out when there is no printer to hand: save the PDF or send it to
  /// a print shop.
  Future<void> share(StudioState state) async {
    final bytes = await build(state);
    try {
      await Printing.sharePdf(bytes: bytes, filename: _fileName(state));
    } catch (_) {
      throw const PdfExportException(
        'The sheet could not be shared. Please try again.',
      );
    }
  }

  String _fileName(StudioState state) {
    final w = _trim(state.photoSpec.widthMm);
    final h = _trim(state.photoSpec.heightMm);
    return 'passport-photos-${w}x${h}mm-${state.paper.name}.pdf';
  }

  static String _trim(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}

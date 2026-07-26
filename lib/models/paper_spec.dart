import 'package:flutter/foundation.dart';

/// A sheet of paper, in millimetres.
@immutable
class PaperSpec {
  const PaperSpec({
    required this.name,
    required this.widthMm,
    required this.heightMm,
  });

  final String name;
  final double widthMm;
  final double heightMm;

  double get aspectRatio => widthMm / heightMm;

  static const a4 = PaperSpec(name: 'A4', widthMm: 210, heightMm: 297);
  static const letter = PaperSpec(
    name: 'Letter',
    widthMm: 215.9,
    heightMm: 279.4,
  );
  static const photo4x6 = PaperSpec(
    name: '4x6',
    widthMm: 101.6,
    heightMm: 152.4,
  );

  static const presets = <PaperSpec>[a4, letter, photo4x6];

  @override
  bool operator ==(Object other) =>
      other is PaperSpec &&
      other.name == name &&
      other.widthMm == widthMm &&
      other.heightMm == heightMm;

  @override
  int get hashCode => Object.hash(name, widthMm, heightMm);

  @override
  String toString() => 'PaperSpec($name, ${widthMm}x${heightMm}mm)';
}

/// Where tile packing starts from.
enum PageOrigin {
  /// Inset from the paper corner by [PageOrigin.printableInsetMm] so nothing is
  /// clipped by the printer's unprintable margin. The safe default.
  printableArea('Printable area'),

  /// The true paper corner, for tighter packing. Needs a borderless printer.
  paperEdge('Paper edge');

  const PageOrigin(this.label);

  final String label;

  /// Typical unprintable margin on consumer inkjet and laser printers.
  static const printableInsetMm = 5.0;

  double get insetMm => this == PageOrigin.printableArea ? printableInsetMm : 0;
}

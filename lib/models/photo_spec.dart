import 'package:flutter/foundation.dart';

/// A photo size, in millimetres. Every dimension in this app is millimetres —
/// never pixels — so that the on-screen preview and the printed PDF consume
/// exactly the same numbers.
@immutable
class PhotoSpec {
  const PhotoSpec({
    required this.name,
    required this.widthMm,
    required this.heightMm,
  });

  final String name;
  final double widthMm;
  final double heightMm;

  double get aspectRatio => widthMm / heightMm;

  static const passport35x45 = PhotoSpec(
    name: '35x45mm (Default)',
    widthMm: 35,
    heightMm: 45,
  );

  static const passport2x2in = PhotoSpec(
    name: '2x2in (USA)',
    widthMm: 50.8,
    heightMm: 50.8,
  );

  static const id35x35 = PhotoSpec(
    name: '35x35mm (ID)',
    widthMm: 35,
    heightMm: 35,
  );

  static const print4x6in = PhotoSpec(
    name: '4x6in Print',
    widthMm: 101.6,
    heightMm: 152.4,
  );

  static const presets = <PhotoSpec>[
    passport35x45,
    passport2x2in,
    id35x35,
    print4x6in,
  ];

  static PhotoSpec custom(double widthMm, double heightMm) =>
      PhotoSpec(name: 'Custom', widthMm: widthMm, heightMm: heightMm);

  bool get isCustom => name == 'Custom';

  PhotoSpec copyWith({String? name, double? widthMm, double? heightMm}) =>
      PhotoSpec(
        name: name ?? this.name,
        widthMm: widthMm ?? this.widthMm,
        heightMm: heightMm ?? this.heightMm,
      );

  @override
  bool operator ==(Object other) =>
      other is PhotoSpec &&
      other.name == name &&
      other.widthMm == widthMm &&
      other.heightMm == heightMm;

  @override
  int get hashCode => Object.hash(name, widthMm, heightMm);

  @override
  String toString() => 'PhotoSpec($name, ${widthMm}x${heightMm}mm)';
}

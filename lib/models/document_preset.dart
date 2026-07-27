import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';

import 'photo_spec.dart';

/// A named document photo requirement — the thing a user actually asks for
/// ("Indian passport"), rather than the millimetres they would otherwise have
/// to look up.
///
/// These are guidance, not law. Requirements change and vary by consulate, so
/// the picker says so and nothing here blocks the user from proceeding.
@immutable
class DocumentPreset {
  const DocumentPreset({
    required this.country,
    required this.document,
    required this.widthMm,
    required this.heightMm,
    required this.backgroundName,
    required this.backgroundColour,
    this.headHeightPercent,
    this.notes,
  });

  final String country;
  final String document;
  final double widthMm;
  final double heightMm;

  /// What the authority calls the required background, in their words.
  final String backgroundName;

  /// Used to check the photo's own background and warn on a mismatch.
  final Color backgroundColour;

  /// Chin-to-crown height as a fraction of the photo height, where published.
  /// Null where the authority states no figure we can rely on.
  final ({double min, double max})? headHeightPercent;

  final String? notes;

  String get label => '$country - $document';

  String get sizeLabel =>
      '${_trim(widthMm)} x ${_trim(heightMm)} mm';

  PhotoSpec get spec =>
      PhotoSpec(name: label, widthMm: widthMm, heightMm: heightMm);

  /// Matches against country, document and size, so "35x45", "india" and
  /// "passport" all find the right thing.
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return country.toLowerCase().contains(q) ||
        document.toLowerCase().contains(q) ||
        sizeLabel.toLowerCase().contains(q) ||
        '${_trim(widthMm)}x${_trim(heightMm)}'.contains(q.replaceAll(' ', ''));
  }

  static String _trim(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  @override
  bool operator ==(Object other) =>
      other is DocumentPreset &&
      other.country == country &&
      other.document == document &&
      other.widthMm == widthMm &&
      other.heightMm == heightMm;

  @override
  int get hashCode => Object.hash(country, document, widthMm, heightMm);
}

/// Common background colours, kept as constants so the same value is used for
/// the swatch shown to the user and the check run against their photo.
abstract final class DocumentBackgrounds {
  static const white = Color(0xFFFFFFFF);
  static const offWhite = Color(0xFFF7F5F0);
  static const lightGrey = Color(0xFFE6E6E6);
  static const lightBlue = Color(0xFFD8E4F0);
}

/// The presets offered in the picker.
///
/// Deliberately a short, common list rather than an exhaustive one: a long list
/// is harder to search, and every entry is a claim we have to keep correct.
const documentPresets = <DocumentPreset>[
  DocumentPreset(
    country: 'India',
    document: 'Passport',
    widthMm: 35,
    heightMm: 45,
    backgroundName: 'White',
    backgroundColour: DocumentBackgrounds.white,
    headHeightPercent: (min: 0.60, max: 0.80),
    notes: 'Face should fill most of the frame, looking straight ahead.',
  ),
  DocumentPreset(
    country: 'India',
    document: 'Stamp size',
    widthMm: 20,
    heightMm: 25,
    backgroundName: 'White',
    backgroundColour: DocumentBackgrounds.white,
  ),
  DocumentPreset(
    country: 'India',
    document: 'PAN card',
    widthMm: 25,
    heightMm: 35,
    backgroundName: 'White',
    backgroundColour: DocumentBackgrounds.white,
  ),
  DocumentPreset(
    country: 'India',
    document: 'OCI / visa (2x2 in)',
    widthMm: 50.8,
    heightMm: 50.8,
    backgroundName: 'White',
    backgroundColour: DocumentBackgrounds.white,
  ),
  DocumentPreset(
    country: 'United States',
    document: 'Passport',
    widthMm: 50.8,
    heightMm: 50.8,
    backgroundName: 'White or off-white',
    backgroundColour: DocumentBackgrounds.offWhite,
    headHeightPercent: (min: 0.50, max: 0.69),
    notes: 'Head must measure 25 to 35 mm from chin to crown.',
  ),
  DocumentPreset(
    country: 'United States',
    document: 'Visa',
    widthMm: 50.8,
    heightMm: 50.8,
    backgroundName: 'White or off-white',
    backgroundColour: DocumentBackgrounds.offWhite,
    headHeightPercent: (min: 0.50, max: 0.69),
  ),
  DocumentPreset(
    country: 'United Kingdom',
    document: 'Passport',
    widthMm: 35,
    heightMm: 45,
    backgroundName: 'Light grey or cream',
    backgroundColour: DocumentBackgrounds.lightGrey,
    headHeightPercent: (min: 0.64, max: 0.76),
    notes: 'Head must measure 29 to 34 mm from chin to crown.',
  ),
  DocumentPreset(
    country: 'Schengen / EU',
    document: 'Visa',
    widthMm: 35,
    heightMm: 45,
    backgroundName: 'Light grey',
    backgroundColour: DocumentBackgrounds.lightGrey,
    headHeightPercent: (min: 0.70, max: 0.80),
  ),
  DocumentPreset(
    country: 'Canada',
    document: 'Passport',
    widthMm: 50,
    heightMm: 70,
    backgroundName: 'Plain white',
    backgroundColour: DocumentBackgrounds.white,
    notes: 'Face must measure 31 to 36 mm from chin to crown.',
  ),
  DocumentPreset(
    country: 'Australia',
    document: 'Passport',
    widthMm: 35,
    heightMm: 45,
    backgroundName: 'Plain light grey or white',
    backgroundColour: DocumentBackgrounds.lightGrey,
  ),
  DocumentPreset(
    country: 'China',
    document: 'Visa',
    widthMm: 33,
    heightMm: 48,
    backgroundName: 'White',
    backgroundColour: DocumentBackgrounds.white,
  ),
  DocumentPreset(
    country: 'Japan',
    document: 'Passport',
    widthMm: 35,
    heightMm: 45,
    backgroundName: 'Plain white',
    backgroundColour: DocumentBackgrounds.white,
  ),
  DocumentPreset(
    country: 'Singapore',
    document: 'Passport / pass',
    widthMm: 35,
    heightMm: 45,
    backgroundName: 'White',
    backgroundColour: DocumentBackgrounds.white,
  ),
  DocumentPreset(
    country: 'UAE',
    document: 'Visa',
    widthMm: 43,
    heightMm: 55,
    backgroundName: 'White',
    backgroundColour: DocumentBackgrounds.white,
  ),
  DocumentPreset(
    country: 'New Zealand',
    document: 'Passport',
    widthMm: 35,
    heightMm: 45,
    backgroundName: 'Plain light grey or white',
    backgroundColour: DocumentBackgrounds.lightGrey,
  ),
  DocumentPreset(
    country: 'Generic',
    document: 'ID photo',
    widthMm: 35,
    heightMm: 35,
    backgroundName: 'White',
    backgroundColour: DocumentBackgrounds.white,
  ),
  DocumentPreset(
    country: 'Generic',
    document: 'Photo print 4x6 in',
    widthMm: 101.6,
    heightMm: 152.4,
    backgroundName: 'Any',
    backgroundColour: DocumentBackgrounds.white,
  ),
];

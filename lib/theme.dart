import 'package:flutter/material.dart';

/// Declared in pubspec.yaml and bundled as an asset.
const appFontFamily = 'Atkinson Hyperlegible Next';

/// Design tokens from the "Clarity Path" system.
///
/// Where the exported design doc's prose and its tokens disagreed, the tokens
/// win — the screens were rendered from them.
abstract final class AppColors {
  static const primary = Color(0xFF031632);
  static const primaryContainer = Color(0xFF1A2B48);
  static const onPrimary = Color(0xFFFFFFFF);

  static const background = Color(0xFFF9F9FF);
  static const surfaceLowest = Color(0xFFFFFFFF);
  static const surfaceContainer = Color(0xFFE7EEFE);
  static const surfaceContainerLow = Color(0xFFF0F3FF);

  static const onSurface = Color(0xFF151C27);
  static const onSurfaceVariant = Color(0xFF44474D);

  static const outline = Color(0xFF75777E);
  static const outlineVariant = Color(0xFFC5C6CE);

  /// Reserved for crop guides, alignment guides and critical errors only.
  /// Its use is surgical, so it never reads as anxiety.
  static const guide = Color(0xFFBA1A1A);

  static const selectedFill = Color(0xFFD7E2FF);
}

abstract final class AppSpacing {
  static const pageMargin = 24.0;
  static const gutter = 16.0;
  static const stackSm = 8.0;
  static const stackMd = 24.0;
  static const stackLg = 40.0;

  /// Nothing tappable is ever smaller than this.
  static const touchTargetMin = 48.0;
  static const primaryButtonHeight = 56.0;
}

abstract final class AppRadii {
  static const chip = 8.0;
  static const card = 12.0;
  static const button = 12.0;

  /// The crop frame is deliberately sharp — a cut photograph has square
  /// corners, and the frame should read as the physical thing.
  static const cropFrame = 0.0;
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
  );

  // Atkinson Hyperlegible Next raises character recognition for low-vision
  // readers, which is the whole reason the design system picked it. The font
  // ships inside the app, so it renders identically with no connection.
  final textTheme = base.textTheme
      .apply(
        fontFamily: appFontFamily,
        bodyColor: AppColors.onSurface,
        displayColor: AppColors.onSurface,
      );

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      surface: AppColors.background,
      onSurface: AppColors.onSurface,
      error: AppColors.guide,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
    ),
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      foregroundColor: AppColors.primary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.headlineSmall?.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w700,
      ),
    ),
    // Motion is kept minimal throughout; these users may find it distracting.
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
      },
    ),
  );
}

/// Text styles named after the design system's scale.
extension AppTextStyles on TextTheme {
  TextStyle get stepNumber =>
      const TextStyle(fontSize: 48, fontWeight: FontWeight.w800, height: 1.1);
  TextStyle get headlineLg =>
      const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.2);
  TextStyle get bodyLg =>
      const TextStyle(fontSize: 20, fontWeight: FontWeight.w400, height: 1.5);
  TextStyle get labelBold =>
      const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, height: 1.2);
  TextStyle get labelMd =>
      const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 1.2);
  TextStyle get buttonText =>
      const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, height: 1.0);
}

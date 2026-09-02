import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Type scale for Bookslane.
///
/// The reference design uses a geometric sans (Poppins). Until the family is
/// bundled, [fontFamily] resolves to the platform default — Flutter falls back
/// silently, so nothing breaks. To switch the whole app to Poppins:
///
///   1. drop the .ttf files in `assets/fonts/`,
///   2. declare `family: Poppins` under `flutter: fonts:` in pubspec.yaml,
///   3. set [fontFamily] below to `'Poppins'`.
abstract final class AppTypography {
  /// Set to `'Poppins'` once the family ships with the app.
  static const String? fontFamily = null;

  static const List<String> fontFamilyFallback = <String>[
    'Poppins',
    'SF Pro Text',
    'Roboto',
  ];

  static TextStyle _style({
    required double size,
    required FontWeight weight,
    double? height,
    double? letterSpacing,
    Color color = AppColors.headingText,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontFamilyFallback: fontFamilyFallback,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  // ---------------------------------------------------------------------------
  // Display — brand moments only (splash, auth header).
  // ---------------------------------------------------------------------------
  static final TextStyle displayLarge = _style(
    size: 34,
    weight: FontWeight.w800,
    letterSpacing: -0.5,
    height: 1.15,
  );

  static final TextStyle displayMedium = _style(
    size: 28,
    weight: FontWeight.w800,
    letterSpacing: -0.4,
    height: 1.2,
  );

  // ---------------------------------------------------------------------------
  // Headings
  // ---------------------------------------------------------------------------
  static final TextStyle headlineLarge = _style(
    size: 24,
    weight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.25,
  );

  static final TextStyle headlineMedium = _style(
    size: 20,
    weight: FontWeight.w700,
    height: 1.3,
  );

  static final TextStyle titleLarge = _style(
    size: 18,
    weight: FontWeight.w700,
    height: 1.35,
  );

  static final TextStyle titleMedium = _style(
    size: 16,
    weight: FontWeight.w600,
    height: 1.4,
  );

  // ---------------------------------------------------------------------------
  // Body
  // ---------------------------------------------------------------------------
  static final TextStyle bodyLarge = _style(
    size: 20,
    weight: FontWeight.w400,
    height: 1.45,
  );

  static final TextStyle bodyMedium = _style(
    size: 18,
    weight: FontWeight.w400,
    height: 1.45,
    color: AppColors.mutedText,
  );

  static final TextStyle bodySmall = _style(
    size: 16,
    weight: FontWeight.w400,
    height: 1.45,
    color: AppColors.mutedText,
  );

  // ---------------------------------------------------------------------------
  // Labels & interactive text
  // ---------------------------------------------------------------------------

  /// Uppercase field label — "EMAIL", "PASSWORD".
  static final TextStyle fieldLabel = _style(
    size: 12.5,
    weight: FontWeight.w700,
    letterSpacing: 1.1,
    color: AppColors.inputLabelText,
  );

  /// Primary button label — "SIGN IN".
  static final TextStyle button = _style(
    size: 20,
    weight: FontWeight.w800,
    letterSpacing: 1.2,
    color: AppColors.ctaText,
  );

  static final TextStyle buttonSmall = _style(
    size: 16,
    weight: FontWeight.w700,
    letterSpacing: 0.8,
    color: AppColors.ctaText,
  );

  /// Inline text link — "Forgot password?".
  static final TextStyle link = _style(
    size: 18,
    weight: FontWeight.w700,
    color: AppColors.linkText,
  );

  /// Brand-coloured link inside a sentence — "Create account".
  static final TextStyle linkBrand = _style(
    size: 15,
    weight: FontWeight.w800,
    color: AppColors.linkTextBrand,
  );

  static final TextStyle input = _style(size: 16, weight: FontWeight.w400);

  static final TextStyle hint = _style(
    size: 16,
    weight: FontWeight.w400,
    color: AppColors.inputHintText,
  );

  static final TextStyle caption = _style(
    size: 12,
    weight: FontWeight.w500,
    color: AppColors.mutedText,
  );

  /// Maps the scale onto Material's [TextTheme] so framework widgets inherit it.
  static TextTheme textTheme(Color onSurface, Color onSurfaceMuted) {
    return TextTheme(
      displayLarge: displayLarge.copyWith(color: onSurface),
      displayMedium: displayMedium.copyWith(color: onSurface),
      displaySmall: headlineLarge.copyWith(color: onSurface),
      headlineLarge: headlineLarge.copyWith(color: onSurface),
      headlineMedium: headlineMedium.copyWith(color: onSurface),
      headlineSmall: titleLarge.copyWith(color: onSurface),
      titleLarge: titleLarge.copyWith(color: onSurface),
      titleMedium: titleMedium.copyWith(color: onSurface),
      titleSmall: bodyLarge.copyWith(
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      bodyLarge: bodyLarge.copyWith(color: onSurface),
      bodyMedium: bodyMedium.copyWith(color: onSurfaceMuted),
      bodySmall: bodySmall.copyWith(color: onSurfaceMuted),
      labelLarge: button,
      labelMedium: fieldLabel,
      labelSmall: caption.copyWith(color: onSurfaceMuted),
    );
  }
}

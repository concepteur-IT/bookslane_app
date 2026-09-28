import 'package:flutter/material.dart';

import 'app_palette.dart';

/// Role-named colour tokens — the layer feature code uses.
///
/// Each name says **where the colour goes**, not what hue it is, so a rebrand
/// is a one-line change in [AppPalette]. Read these as sentences:
/// `AppColors.ctaBackground`, `AppColors.inputBorderFocused`,
/// `AppColors.headingText`.
///
/// These are the light-theme values. Dark-mode surfaces live in
/// [AppColorsDark]; `AppTheme` picks between them.
abstract final class AppColors {
  // ---------------------------------------------------------------------------
  // Call to action — the red "SIGN IN" button and anything that behaves like it
  // ---------------------------------------------------------------------------
  static const Color ctaBackground = AppPalette.red500;
  static const Color ctaBackgroundPressed = AppPalette.red700;
  static const Color ctaBackgroundDisabled = AppPalette.neutral400;
  static const Color ctaGradientStart = AppPalette.red400;
  static const Color ctaGradientEnd = AppPalette.red500;
  static const Color ctaText = AppPalette.white;
  static const Color ctaIcon = AppPalette.white;
  static const Color ctaShadow = AppPalette.red25;

  // Secondary (outlined) button.
  static const Color secondaryButtonBackground = AppPalette.white;
  static const Color secondaryButtonBorder = AppPalette.neutral300;
  static const Color secondaryButtonText = AppPalette.red500;

  // ---------------------------------------------------------------------------
  // Links
  // ---------------------------------------------------------------------------

  /// Standalone link — "Forgot password?".
  static const Color linkText = AppPalette.red500;

  /// Link inside a sentence — "Create account".
  static const Color linkTextBrand = AppPalette.purple500;

  // ---------------------------------------------------------------------------
  // Brand header — the purple block behind the logo
  // ---------------------------------------------------------------------------
  static const Color brandPrimary = AppPalette.purple500;
  static const Color brandPrimaryDark = AppPalette.purple700;
  static const Color brandHeaderGradientStart = AppPalette.purple500;
  static const Color brandHeaderGradientEnd = AppPalette.purple700;
  static const Color brandHeaderText = AppPalette.white;
  static const Color brandHeaderSubtitleText = AppPalette.white80;
  static const Color brandSoftBackground = AppPalette.purple50;

  // Logo mark.
  static const Color logoTileBackground = AppPalette.white;
  static const Color logoRingBorder = AppPalette.red500;
  static const Color logoGlyph = AppPalette.navy700;
  static const Color logoLetter = AppPalette.red500;

  // ---------------------------------------------------------------------------
  // Backgrounds & surfaces
  // ---------------------------------------------------------------------------
  static const Color screenBackground = AppPalette.neutral100;
  static const Color surfaceBackground = AppPalette.white; // cards, app bars
  static const Color sheetBackground = AppPalette.white; // the white auth sheet
  static const Color dialogBackground = AppPalette.white;
  static const Color modalScrim = AppPalette.black60;

  // ---------------------------------------------------------------------------
  // Inputs
  // ---------------------------------------------------------------------------
  static const Color inputBackground = AppPalette.neutral50;
  static const Color inputBorder = AppPalette.neutral300;
  static const Color inputBorderFocused = AppPalette.purple500;
  static const Color inputBorderError = AppPalette.red500;
  static const Color inputText = AppPalette.neutral900;
  static const Color inputHintText = AppPalette.neutral400;
  static const Color inputPrefixIcon = AppPalette.neutral700;
  static const Color inputSuffixIcon = AppPalette.neutral500;
  static const Color inputLabelText = AppPalette.neutral700; // "EMAIL"
  static const Color inputCursor = AppPalette.red500;

  // ---------------------------------------------------------------------------
  // Text
  // ---------------------------------------------------------------------------
  static const Color headingText = AppPalette.neutral900; // "Welcome back"
  static const Color bodyText = AppPalette.neutral900;
  static const Color secondaryText = AppPalette.neutral700;
  static const Color mutedText =
      AppPalette.neutral500; // sub-headlines, captions
  static const Color disabledText = AppPalette.neutral400;
  static const Color inverseText = AppPalette.white; // on dark/brand surfaces

  // ---------------------------------------------------------------------------
  // Lines, icons & controls
  // ---------------------------------------------------------------------------
  static const Color borderColor = AppPalette.neutral300;
  static const Color dividerColor = AppPalette.neutral200;
  static const Color iconPrimary = AppPalette.neutral700;
  static const Color iconMuted = AppPalette.neutral500;
  static const Color focusRing = AppPalette.purple500;
  static const Color controlSelected =
      AppPalette.red500; // checkbox, switch, radio
  static const Color controlUnselectedBorder = AppPalette.neutral300;
  static const Color navItemSelected = AppPalette.purple500;
  static const Color navItemUnselected = AppPalette.neutral500;
  static const Color navIndicatorBackground = AppPalette.purple50;

  // ---------------------------------------------------------------------------
  // Status — text/icon colour paired with its tinted background
  // ---------------------------------------------------------------------------
  static const Color successText = AppPalette.green500;
  static const Color successBackground = AppPalette.green50;
  static const Color warningText = AppPalette.amber500;
  static const Color warningBackground = AppPalette.amber50;
  static const Color infoText = AppPalette.blue500;
  static const Color infoBackground = AppPalette.blue50;

  /// Validation errors reuse the CTA red so the UI never gains a second red.
  static const Color errorText = AppPalette.red500;
  static const Color errorBackground = AppPalette.red50;

  // ---------------------------------------------------------------------------
  // Feedback surfaces
  // ---------------------------------------------------------------------------
  static const Color snackBarBackground = AppPalette.neutral900;
  static const Color snackBarText = AppPalette.white;
  static const Color snackBarActionText = AppPalette.red400;
  static const Color tooltipBackground = AppPalette.neutral900;
  static const Color tooltipText = AppPalette.white;
  static const Color skeletonBase = AppPalette.neutral50;
  static const Color skeletonHighlight = AppPalette.neutral300;
  static const Color dragHandle = AppPalette.neutral300;

  // ---------------------------------------------------------------------------
  // Book covers — the generated cover shown when a book has no image
  // ---------------------------------------------------------------------------
  /// Picked per book (stable by id), so a shelf of imageless books reads as
  /// a varied row of spines rather than a wall of one colour.
  static const List<Color> coverTints = [
    AppPalette.navy700,
    AppPalette.purple500,
    AppPalette.red700,
    AppPalette.purple900,
    AppPalette.green500,
    AppPalette.blue500,
  ];
  static const Color coverText = AppPalette.white;
  static const Color coverTextMuted = AppPalette.white80;

  /// The dark "Sold out" tag laid over a cover.
  static const Color soldOutTagBackground = AppPalette.neutral900;
  static const Color soldOutTagText = AppPalette.white;

  // ---------------------------------------------------------------------------
  // Shadows
  // ---------------------------------------------------------------------------
  static const Color cardShadow = AppPalette.black06;
  static const Color raisedShadow = AppPalette.black20;
  static const Color bottomBarShadow = AppPalette.black08;
}

/// Dark-mode overrides.
///
/// Only surfaces and text shift — the brand purple and CTA red are identical in
/// both themes, so anything not listed here comes straight from [AppColors].
/// The reference design is light-only, so this ramp is derived, not designed.
abstract final class AppColorsDark {
  static const Color screenBackground = AppPalette.darkNeutral900;
  static const Color surfaceBackground = AppPalette.darkNeutral800;
  static const Color sheetBackground = AppPalette.darkNeutral800;
  static const Color inputBackground = AppPalette.darkNeutral700;
  static const Color inputBorder = AppPalette.darkNeutral600;
  static const Color borderColor = AppPalette.darkNeutral600;
  static const Color dividerColor = AppPalette.darkNeutral600;

  static const Color headingText = AppPalette.darkNeutral50;
  static const Color bodyText = AppPalette.darkNeutral50;
  static const Color mutedText = AppPalette.neutral400;
  static const Color iconPrimary = AppPalette.neutral400;

  static const Color brandOnDark = AppPalette.purple50;
  static const Color snackBarBackground = AppPalette.darkNeutral700;
}

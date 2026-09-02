import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_gradients.dart';
import 'app_shadows.dart';
import 'app_spacing.dart';

/// Ready-made decorations for the pieces [ThemeData] cannot describe —
/// anything with a gradient, and the branded auth layout.
abstract final class AppDecorations {
  /// Purple backdrop of the sign-in / sign-up header.
  static const BoxDecoration brandHeader = BoxDecoration(
    gradient: AppGradients.brandHeader,
  );

  /// White sheet that overlaps the header and holds the form.
  static const BoxDecoration sheet = BoxDecoration(
    color: AppColors.sheetBackground,
    borderRadius: AppRadius.sheetTop,
  );

  /// Rounded white tile the logo mark sits in.
  static const BoxDecoration logoTile = BoxDecoration(
    color: AppColors.logoTileBackground,
    borderRadius: AppRadius.pillAll,
    boxShadow: AppShadows.raised,
  );

  /// Gradient fill + glow for the call-to-action button.
  static const BoxDecoration ctaButton = BoxDecoration(
    gradient: AppGradients.ctaButton,
    borderRadius: AppRadius.lgAll,
    boxShadow: AppShadows.ctaButton,
  );

  /// [ctaButton] with the glow removed — use while `onPressed` is null or a
  /// request is in flight.
  static const BoxDecoration ctaButtonDisabled = BoxDecoration(
    color: AppColors.ctaBackgroundDisabled,
    borderRadius: AppRadius.lgAll,
  );

  /// Content card on a light background.
  static final BoxDecoration card = BoxDecoration(
    color: AppColors.surfaceBackground,
    borderRadius: AppRadius.mdAll,
    border: Border.all(color: AppColors.borderColor),
    boxShadow: AppShadows.card,
  );

  /// Matches the filled input fields, for read-only boxes that must look like
  /// a field without being one.
  static final BoxDecoration inputLookalike = BoxDecoration(
    color: AppColors.inputBackground,
    borderRadius: AppRadius.mdAll,
    border: Border.all(color: AppColors.inputBorder),
  );

  /// Tinted pill for status chips — pair with the matching `*Background`
  /// token, e.g. `AppColors.successBackground`.
  static BoxDecoration statusPill(Color background) =>
      BoxDecoration(color: background, borderRadius: AppRadius.pillAll);
}

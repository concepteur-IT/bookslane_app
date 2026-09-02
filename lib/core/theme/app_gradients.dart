import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Gradients cannot live in [ThemeData], so they are tokens of their own.
abstract final class AppGradients {
  /// Purple backdrop behind the logo on the auth / splash screens.
  static const LinearGradient brandHeader = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[
      AppColors.brandHeaderGradientStart,
      AppColors.brandHeaderGradientEnd,
    ],
  );

  /// Fill of the primary call-to-action button.
  static const LinearGradient ctaButton = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[AppColors.ctaGradientStart, AppColors.ctaGradientEnd],
  );

  /// Pressed variant of [ctaButton].
  static const LinearGradient ctaButtonPressed = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[AppColors.ctaGradientEnd, AppColors.ctaBackgroundPressed],
  );

  /// Skeleton shimmer for loading placeholders.
  static const LinearGradient skeletonShimmer = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: <Color>[
      AppColors.skeletonBase,
      AppColors.skeletonHighlight,
      AppColors.skeletonBase,
    ],
    stops: <double>[0.1, 0.5, 0.9],
  );
}

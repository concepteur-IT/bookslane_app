import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Elevation tokens. The design is mostly flat — shadows are reserved for the
/// logo tile, the CTA glow and floating surfaces.
abstract final class AppShadows {
  /// Barely-there lift for list cards.
  static const List<BoxShadow> card = <BoxShadow>[
    BoxShadow(
      color: AppColors.cardShadow,
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  /// Raised surfaces: the white logo tile, dialogs, popovers.
  static const List<BoxShadow> raised = <BoxShadow>[
    BoxShadow(
      color: AppColors.raisedShadow,
      blurRadius: 24,
      offset: Offset(0, 10),
    ),
  ];

  /// Red glow under the call-to-action button.
  static const List<BoxShadow> ctaButton = <BoxShadow>[
    BoxShadow(color: AppColors.ctaShadow, blurRadius: 18, offset: Offset(0, 8)),
  ];

  /// Upward shadow for bars anchored to the bottom of the screen.
  static const List<BoxShadow> bottomBar = <BoxShadow>[
    BoxShadow(
      color: AppColors.bottomBarShadow,
      blurRadius: 20,
      offset: Offset(0, -6),
    ),
  ];
}

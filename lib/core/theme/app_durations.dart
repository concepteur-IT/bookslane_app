import 'package:flutter/animation.dart';

/// Motion tokens. Interaction feedback is `fast`, most transitions `medium`,
/// and only full-screen or sheet motion uses `slow`.
abstract final class AppDurations {
  static const Duration instant = Duration(milliseconds: 80);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);

  /// How long the splash screen holds before routing to sign-in.
  static const Duration splash = Duration(seconds: 2);

  /// Default snack bar visibility.
  static const Duration snackBar = Duration(seconds: 4);
}

/// Easing curves paired with [AppDurations].
abstract final class AppCurves {
  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeInOutCubic;
  static const Curve enter = Curves.easeOut;
  static const Curve exit = Curves.easeIn;
}

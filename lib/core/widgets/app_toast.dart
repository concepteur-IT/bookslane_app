import 'package:flutter/material.dart';

import 'package:bookslane_app/core/theme/theme.dart';

/// Brief messages at the bottom of the screen.
///
/// Wraps `ScaffoldMessenger` so every toast in the app looks the same and
/// carries the right status colour.
abstract final class AppToast {
  static void error(BuildContext context, String message) =>
      _show(context, message, AppColors.errorText, Icons.error_outline_rounded);

  static void success(BuildContext context, String message) => _show(
    context,
    message,
    AppColors.successText,
    Icons.check_circle_outline_rounded,
  );

  static void info(BuildContext context, String message) => _show(
    context,
    message,
    AppColors.snackBarBackground,
    Icons.info_outline_rounded,
  );

  static void _show(
    BuildContext context,
    String message,
    Color background,
    IconData icon,
  ) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger
      // One message at a time: a queue of stale errors helps nobody.
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: background,
          duration: AppDurations.snackBar,
          content: Row(
            children: [
              Icon(icon, color: AppColors.inverseText, size: AppSizes.iconMd),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.inverseText,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}

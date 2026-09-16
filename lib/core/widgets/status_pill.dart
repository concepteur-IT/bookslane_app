import 'package:flutter/material.dart';

import 'package:bookslane_app/core/theme/theme.dart';

/// Solid pill carrying a short status word — "Done", "Active", "Upcoming".
///
/// Pass the colour that encodes the status ([AppColors.successText],
/// [AppColors.brandPrimary], [AppColors.secondaryText], ...); the label is
/// always [AppColors.inverseText] so contrast holds on any of them.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecorations.statusPill(color),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs + 2,
        vertical: AppSpacing.xxs + 2,
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: AppColors.inverseText,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}

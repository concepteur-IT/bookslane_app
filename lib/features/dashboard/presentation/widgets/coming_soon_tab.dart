import 'package:flutter/material.dart';

import 'package:bookslane_app/core/theme/theme.dart';

/// Placeholder for the tabs that have no screen yet.
///
/// Better than leaving the previous tab's content on screen, which reads as a
/// broken button.
class ComingSoonTab extends StatelessWidget {
  const ComingSoonTab({super.key, required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppSizes.logoTile, color: AppColors.disabledText),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: AppTypography.headlineMedium),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'This screen is not built yet.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

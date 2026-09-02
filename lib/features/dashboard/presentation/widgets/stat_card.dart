import 'package:flutter/material.dart';

import 'package:bookslane_app/core/theme/theme.dart';

/// One figure in the stats row: tinted icon tile, value, label.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.onTap,
  });

  final IconData icon;

  /// Fill of the icon tile — brand purple, CTA red, warning amber, ...
  final Color iconColor;

  /// Preformatted for display: "128", "1,248", "84.3k".
  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.lgAll,
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surfaceBackground,
            borderRadius: AppRadius.lgAll,
            boxShadow: AppShadows.card,
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: AppSizes.tileMd,
                height: AppSizes.tileMd,
                decoration: BoxDecoration(
                  color: iconColor,
                  borderRadius: AppRadius.smAll,
                ),
                child: Icon(
                  icon,
                  size: AppSizes.iconLg,
                  color: AppColors.inverseText,
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.headlineLarge,
              ),

              const SizedBox(height: AppSpacing.xxs),

              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

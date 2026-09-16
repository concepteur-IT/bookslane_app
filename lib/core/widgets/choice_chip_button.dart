import 'package:flutter/material.dart';

import 'package:bookslane_app/core/theme/theme.dart';

/// Pill button for filter and sort rows.
class ChoiceChipButton extends StatelessWidget {
  const ChoiceChipButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onPressed,
    this.selectedColor = AppColors.brandPrimary,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  /// Filled with this when selected; outlined on white when not.
  final Color selectedColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? selectedColor : AppColors.surfaceBackground,
      borderRadius: AppRadius.pillAll,
      child: InkWell(
        borderRadius: AppRadius.pillAll,
        onTap: onPressed,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.pillAll,
            border: Border.all(
              color: isSelected ? selectedColor : AppColors.borderColor,
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm + 2,
            vertical: AppSpacing.xs + 2,
          ),
          child: Text(
            label,
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? AppColors.inverseText
                  : AppColors.secondaryText,
            ),
          ),
        ),
      ),
    );
  }
}

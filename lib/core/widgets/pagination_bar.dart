import 'package:flutter/material.dart';

import 'package:bookslane_app/core/theme/theme.dart';

/// "6 of 12" on the left, page arrows on the right.
class PaginationBar extends StatelessWidget {
  const PaginationBar({
    super.key,
    required this.shown,
    required this.total,
    required this.page,
    required this.pageCount,
    required this.onPrevious,
    required this.onNext,
  });

  /// How many rows are on screen right now.
  final int shown;

  final int total;

  /// 1-based, so it reads the same as the label.
  final int page;
  final int pageCount;

  /// Null disables the arrow — first page back, last page forward.
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$shown of $total', style: AppTypography.bodyMedium),
        const Spacer(),
        _ArrowButton(
          icon: Icons.chevron_left_rounded,
          tooltip: 'Previous page',
          onPressed: onPrevious,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text('$page/$pageCount', style: AppTypography.titleMedium),
        ),
        _ArrowButton(
          icon: Icons.chevron_right_rounded,
          tooltip: 'Next page',
          onPressed: onNext,
        ),
      ],
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.surfaceBackground,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.smAll,
          side: BorderSide(color: AppColors.borderColor),
        ),
        child: InkWell(
          borderRadius: AppRadius.smAll,
          onTap: onPressed,
          child: SizedBox(
            width: AppSizes.tileMd,
            height: AppSizes.tileMd,
            child: Icon(
              icon,
              size: AppSizes.iconLg,
              color: isEnabled ? AppColors.iconPrimary : AppColors.disabledText,
            ),
          ),
        ),
      ),
    );
  }
}

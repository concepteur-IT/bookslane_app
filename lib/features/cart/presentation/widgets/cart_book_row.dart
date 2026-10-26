import 'package:flutter/material.dart';

import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/core/widgets/widgets.dart';
import 'package:bookslane_app/features/cart/presentation/providers/cart_provider.dart';

/// One cart line, in the Shop list row's template with the minimum: cover,
/// title, author, unit price, and a quantity stepper with remove.
class CartBookRow extends StatelessWidget {
  const CartBookRow({
    super.key,
    required this.line,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  final CartLine line;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  static const double _thumbWidth = 72;

  @override
  Widget build(BuildContext context) {
    final book = line.book;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceBackground,
        borderRadius: AppRadius.lgAll,
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _thumbWidth,
            child: BookCover(
              title: book.title,
              author: book.author,
              imageUrl: book.imageUrl,
              seed: book.id,
              compact: true,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption,
                ),
                const SizedBox(height: 2),
                Text(
                  book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.headingText,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  book.formattedPrice,
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.ctaBackground,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    _StepButton(
                      icon: Icons.remove_rounded,
                      tooltip: 'Remove one',
                      onPressed: onDecrement,
                    ),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '${line.quantity}',
                        textAlign: TextAlign.center,
                        style: AppTypography.titleMedium,
                      ),
                    ),
                    _StepButton(
                      icon: Icons.add_rounded,
                      tooltip: 'Add one',
                      onPressed: line.quantity >= book.stock
                          ? null
                          : onIncrement,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: onRemove,
                      tooltip: 'Remove from cart',
                      icon: const Icon(Icons.delete_outline_rounded),
                      color: AppColors.secondaryText,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Opacity(
        opacity: onPressed == null ? 0.4 : 1,
        child: Material(
          color: AppColors.brandPrimary,
          borderRadius: AppRadius.smAll,
          child: InkWell(
            borderRadius: AppRadius.smAll,
            onTap: onPressed,
            child: SizedBox(
              width: 36,
              height: 36,
              child: Icon(
                icon,
                size: AppSizes.iconSm,
                color: AppColors.inverseText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

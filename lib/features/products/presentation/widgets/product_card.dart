import 'package:flutter/material.dart';

import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/core/widgets/widgets.dart';
import 'package:bookslane_app/features/products/domain/entities/product.dart';

/// One product row. The eye opens the full details; the pencil edits the
/// quantity, which is all this screen can change.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.onViewDetails,
    this.onEditQuantity,
  });

  final Product product;
  final VoidCallback? onViewDetails;
  final VoidCallback? onEditQuantity;

  static const double _coverWidth = 72;

  @override
  Widget build(BuildContext context) {
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
          // The Shop's 2:3 cover, at the Shop list's thumbnail width.
          SizedBox(
            width: _coverWidth,
            child: BookCover(
              title: product.name,
              author: product.author,
              imageUrl: product.imageUrl,
              seed: '${product.id}',
              compact: true,
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleLarge,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  product.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                // A Wrap, not a Row: beside the cover, a narrow phone leaves too
                // little width for both pills on one line.
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xxs,
                  children: [
                    StatusPill(
                      label: product.isActive ? 'Active' : 'Inactive',
                      color: product.isActive
                          ? AppColors.successText
                          : AppColors.secondaryText,
                    ),
                    _StockPill(stock: product.stock),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.xs),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(product.formattedPrice, style: AppTypography.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SquareAction(
                    tooltip: 'View details',
                    onPressed: onViewDetails,
                    background: AppColors.inputBackground,
                    icon: Icons.visibility_outlined,
                    iconColor: AppColors.iconMuted,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _SquareAction(
                    tooltip: 'Edit quantity',
                    onPressed: onEditQuantity,
                    background: AppColors.brandSoftBackground,
                    icon: Icons.edit_outlined,
                    iconColor: AppColors.brandPrimary,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A small square icon button — the same shape as BookCard's actions.
class _SquareAction extends StatelessWidget {
  const _SquareAction({
    required this.tooltip,
    required this.onPressed,
    required this.background,
    required this.icon,
    required this.iconColor,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final Color background;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        borderRadius: AppRadius.smAll,
        child: InkWell(
          borderRadius: AppRadius.smAll,
          onTap: onPressed,
          child: SizedBox(
            width: AppSizes.tileMd - AppSpacing.xs,
            height: AppSizes.tileMd - AppSpacing.xs,
            child: Icon(icon, size: AppSizes.iconSm, color: iconColor),
          ),
        ),
      ),
    );
  }
}

class _StockPill extends StatelessWidget {
  const _StockPill({required this.stock});

  final int stock;

  @override
  Widget build(BuildContext context) {
    final isOut = stock == 0;

    return Container(
      decoration: BoxDecoration(
        color: isOut ? AppColors.errorBackground : AppColors.inputBackground,
        borderRadius: AppRadius.pillAll,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xs,
      ),
      child: Text(
        isOut ? 'Out of stock' : '$stock in stock',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.caption.copyWith(
          fontWeight: FontWeight.w600,
          color: isOut ? AppColors.errorText : AppColors.mutedText,
        ),
      ),
    );
  }
}

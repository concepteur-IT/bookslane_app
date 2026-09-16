import 'package:flutter/material.dart';

import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/core/widgets/widgets.dart';
import 'package:bookslane_app/features/products/domain/entities/product.dart';

/// One product row. The pencil is the only action: quantity is all this
/// screen can change.
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, this.onEditQuantity});

  final Product product;
  final VoidCallback? onEditQuantity;

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
          _Cover(imageUrl: product.imageUrl),

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
                Row(
                  children: [
                    StatusPill(
                      label: product.isActive ? 'Active' : 'Inactive',
                      color: product.isActive
                          ? AppColors.successText
                          : AppColors.secondaryText,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(child: _StockPill(stock: product.stock)),
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
              Tooltip(
                message: 'Edit quantity',
                child: Material(
                  color: AppColors.brandSoftBackground,
                  borderRadius: AppRadius.smAll,
                  child: InkWell(
                    borderRadius: AppRadius.smAll,
                    onTap: onEditQuantity,
                    child: SizedBox(
                      width: AppSizes.tileMd - AppSpacing.xs,
                      height: AppSizes.tileMd - AppSpacing.xs,
                      child: Icon(
                        Icons.edit_outlined,
                        size: AppSizes.iconSm,
                        color: AppColors.brandPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The cover image, falling back to the box icon when there is none or it
/// fails to load.
class _Cover extends StatelessWidget {
  const _Cover({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.tileMd,
      height: AppSizes.tileMd,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: AppColors.brandSoftBackground,
        borderRadius: AppRadius.mdAll,
      ),
      child: imageUrl == null
          ? _placeholder
          : Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _placeholder,
            ),
    );
  }

  static Widget get _placeholder => Icon(
    Icons.inventory_2_outlined,
    size: AppSizes.iconLg,
    color: AppColors.brandPrimary,
  );
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

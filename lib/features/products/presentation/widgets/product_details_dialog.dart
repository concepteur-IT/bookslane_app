import 'package:flutter/material.dart';

import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/core/widgets/widgets.dart';
import 'package:bookslane_app/features/products/domain/entities/product.dart';

/// A read-only, full-detail view of one product — opened from the eye icon on
/// [ProductCard]. The list row from `/v1/products` already carries every
/// field shown here, so there is no second request. Laid out like
/// `BookDetailsDialog` so both shelves read the same.
class ProductDetailsDialog extends StatelessWidget {
  const ProductDetailsDialog({super.key, required this.product});

  final Product product;

  /// Opens the dialog.
  static Future<void> show(BuildContext context, Product product) {
    return showDialog<void>(
      context: context,
      builder: (_) => ProductDetailsDialog(product: product),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(child: _Cover(imageUrl: product.imageUrl)),

                      const SizedBox(height: AppSpacing.md),

                      Text(
                        product.name,
                        textAlign: TextAlign.center,
                        style: AppTypography.headlineMedium,
                      ),

                      if (product.author.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          product.author,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium,
                        ),
                      ],

                      const SizedBox(height: AppSpacing.sm),

                      Center(
                        child: StatusPill(
                          label: product.isActive ? 'Active' : 'Inactive',
                          color: product.isActive
                              ? AppColors.successText
                              : AppColors.secondaryText,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg),
                      const Divider(),
                      const SizedBox(height: AppSpacing.xs),

                      _InfoRow(label: 'Code', value: _orDash(product.code)),
                      _InfoRow(label: 'ISBN', value: _orDash(product.isbn)),
                      _InfoRow(
                        label: 'Publisher',
                        value: _orDash(product.publisherName ?? ''),
                      ),
                      _InfoRow(
                        label: 'Language',
                        value: _orDash(product.language),
                      ),
                      _InfoRow(
                        label: 'Binding',
                        value: _orDash(product.binding),
                      ),
                      _InfoRow(
                        label: 'Pages',
                        value: product.pageCount > 0
                            ? '${product.pageCount}'
                            : '—',
                      ),
                      _InfoRow(
                        label: 'Published',
                        value: product.publishYear?.toString() ?? '—',
                      ),
                      _InfoRow(label: 'Price', value: product.formattedPrice),
                      if (product.hasOfferedPrice)
                        _InfoRow(
                          label: 'Offered price',
                          value: product.formattedOfferedPrice,
                        ),
                      _InfoRow(
                        label: 'Quantity',
                        value: '${product.stock} in stock',
                      ),

                      if (product.description.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text('Description', style: AppTypography.titleMedium),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          product.description,
                          style: AppTypography.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _orDash(String value) => value.isNotEmpty ? value : '—';
}

/// A larger cover than [ProductCard]'s tile — same fallback shape.
class _Cover extends StatelessWidget {
  const _Cover({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.logoTile,
      height: AppSizes.logoTile,
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

/// A label/value pair, laid out as an aligned two-column row.
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
          ),
          Expanded(child: Text(value, style: AppTypography.bodyMedium)),
        ],
      ),
    );
  }
}

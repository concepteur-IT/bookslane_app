import 'package:flutter/material.dart';

import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/core/widgets/widgets.dart';
import 'package:bookslane_app/features/shop/domain/entities/shop_book.dart';

/// A read-only, full-detail view of one Shop book — opened from the eye icon.
/// The list row from `/v1/shop/books` already carries every field shown, so
/// there is no second request. Laid out like `ProductDetailsDialog` and
/// `BookDetailsDialog`, so all three shelves read the same.
class ShopBookDetailsDialog extends StatelessWidget {
  const ShopBookDetailsDialog({super.key, required this.book});

  final ShopBook book;

  static Future<void> show(BuildContext context, ShopBook book) {
    return showDialog<void>(
      context: context,
      builder: (_) => ShopBookDetailsDialog(book: book),
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
                      Center(child: _Cover(imageUrl: book.imageUrl)),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        book.title,
                        textAlign: TextAlign.center,
                        style: AppTypography.headlineMedium,
                      ),
                      if (book.author.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          book.author,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xxs,
                        children: [
                          StatusPill(
                            label: book.isActive ? 'Active' : 'Inactive',
                            color: book.isActive
                                ? AppColors.successText
                                : AppColors.secondaryText,
                          ),
                          StatusPill(
                            label: book.source.label,
                            color: book.source == ShopSource.store
                                ? AppColors.infoText
                                : AppColors.brandPrimary,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const Divider(),
                      const SizedBox(height: AppSpacing.xs),

                      _InfoRow(label: 'Code / SKU', value: _orDash(book.sku)),
                      if (book.source == ShopSource.publishing) ...[
                        _InfoRow(label: 'ISBN', value: _orDash(book.isbn)),
                        _InfoRow(
                          label: 'Publisher',
                          value: _orDash(book.publisherName),
                        ),
                      ],
                      _InfoRow(
                        label: 'Category',
                        value: book.categories.isEmpty
                            ? '—'
                            : book.categories.join(', '),
                      ),
                      _InfoRow(
                        label: 'Language',
                        value: _orDash(book.language),
                      ),
                      _InfoRow(label: 'Binding', value: _orDash(book.binding)),
                      if (book.source == ShopSource.publishing) ...[
                        _InfoRow(
                          label: 'Pages',
                          value: book.pageCount > 0 ? '${book.pageCount}' : '—',
                        ),
                        _InfoRow(
                          label: 'Published',
                          value: book.publishYear?.toString() ?? '—',
                        ),
                      ],
                      _InfoRow(label: 'Price', value: book.formattedMrp),
                      if (book.isDiscounted)
                        _InfoRow(
                          label: 'Selling price',
                          value: book.formattedPrice,
                        ),
                      _InfoRow(
                        label: 'Quantity',
                        value: book.isSoldOut
                            ? 'Sold out'
                            : '${book.stock} in stock',
                      ),

                      if (book.description.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text('Description', style: AppTypography.titleMedium),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(book.description, style: AppTypography.bodyMedium),
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

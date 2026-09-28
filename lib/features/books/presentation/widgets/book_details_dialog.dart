import 'package:flutter/material.dart';

import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/core/widgets/widgets.dart';
import 'package:bookslane_app/features/books/domain/entities/book_detail.dart';
import 'package:bookslane_app/features/books/domain/entities/book_form_options.dart';

/// A read-only, full-detail view of one book — opened from the eye icon on
/// [BookCard]. `showDialog` already centres its content over the screen, so
/// this widget only supplies what goes inside it.
class BookDetailsDialog extends StatelessWidget {
  const BookDetailsDialog({super.key, required this.detail});

  final BookDetail detail;

  /// Opens the dialog.
  static Future<void> show(BuildContext context, BookDetail detail) {
    return showDialog<void>(
      context: context,
      builder: (_) => BookDetailsDialog(detail: detail),
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
                      Center(child: _Cover(imageUrl: detail.imageUrl)),

                      const SizedBox(height: AppSpacing.md),

                      Text(
                        detail.title,
                        textAlign: TextAlign.center,
                        style: AppTypography.headlineMedium,
                      ),

                      if (detail.subtitle.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          detail.subtitle,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium,
                        ),
                      ],

                      const SizedBox(height: AppSpacing.sm),

                      Center(
                        child: StatusPill(
                          label: detail.status == BookStatus.active
                              ? 'Active'
                              : 'Inactive',
                          color: detail.status == BookStatus.active
                              ? AppColors.successText
                              : AppColors.secondaryText,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg),
                      const Divider(),
                      const SizedBox(height: AppSpacing.xs),

                      _InfoRow(label: 'SKU', value: _orDash(detail.sku)),
                      _InfoRow(label: 'Author', value: _orDash(detail.author)),
                      _InfoRow(
                        label: 'Language',
                        value: detail.language?.label ?? '—',
                      ),
                      _InfoRow(
                        label: 'Category',
                        value: detail.category?.label ?? '—',
                      ),
                      _InfoRow(
                        label: 'Binding',
                        value: detail.binding?.label ?? '—',
                      ),
                      _InfoRow(
                        label: 'Price',
                        value: '₹${detail.price.toStringAsFixed(2)}',
                      ),
                      if (detail.discount > 0)
                        _InfoRow(
                          label: 'Discount',
                          value: detail.discountType == DiscountType.percentage
                              ? '${_trimZeros(detail.discount)}%'
                              : '₹${detail.discount.toStringAsFixed(2)}',
                        ),
                      _InfoRow(
                        label: 'Selling price',
                        value: '₹${detail.effectivePrice.toStringAsFixed(2)}',
                      ),
                      _InfoRow(
                        label: 'Quantity',
                        value: '${detail.quantity} in stock',
                      ),

                      if (detail.description.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text('Description', style: AppTypography.titleMedium),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          detail.description,
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

  /// '50' rather than '50.0' for a whole-number percentage.
  static String _trimZeros(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
}

/// A larger cover than [BookCard]'s tile — same fallback shape.
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

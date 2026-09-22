import 'package:flutter/material.dart';

import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/core/widgets/widgets.dart';
import 'package:bookslane_app/features/books/domain/entities/book.dart';

/// One row of the books list: cover tile, title and subtitle, status, price,
/// and the two per-row actions.
class BookCard extends StatelessWidget {
  const BookCard({
    super.key,
    required this.book,
    this.onTap,
    this.onToggleActive,
    this.onEdit,
  });

  final Book book;
  final VoidCallback? onTap;

  /// The round dot on the right — flips active/inactive.
  final VoidCallback? onToggleActive;

  final VoidCallback? onEdit;

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
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Cover(imageUrl: book.imageUrl),

              const SizedBox(width: AppSpacing.sm),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      book.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        StatusPill(
                          label: book.isActive ? 'Active' : 'Inactive',
                          color: book.isActive
                              ? AppColors.successText
                              : AppColors.secondaryText,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(child: _StockPill(stock: book.stock)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.xs),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(book.formattedPrice, style: AppTypography.titleLarge),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      _SquareAction(
                        onPressed: onToggleActive,
                        tooltip: book.isActive ? 'Deactivate' : 'Activate',
                        background: book.isActive
                            ? AppColors.successBackground
                            : AppColors.inputBackground,
                        child: _Dot(
                          color: book.isActive
                              ? AppColors.successText
                              : AppColors.iconMuted,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      _SquareAction(
                        onPressed: onEdit,
                        tooltip: 'Edit',
                        background: AppColors.brandSoftBackground,
                        child: Icon(
                          Icons.edit_outlined,
                          size: AppSizes.iconSm,
                          color: AppColors.brandPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The cover image, falling back to the book icon when there is none — every
/// sample book (My Publishings) — or it fails to load. See ProductCard's
/// `_Cover` for the same shape.
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

/// "23 in stock" — grey, or red once nothing is left.
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

class _SquareAction extends StatelessWidget {
  const _SquareAction({
    required this.child,
    required this.background,
    required this.tooltip,
    this.onPressed,
  });

  final Widget child;
  final Color background;
  final String tooltip;
  final VoidCallback? onPressed;

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
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSpacing.md,
      height: AppSpacing.md,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

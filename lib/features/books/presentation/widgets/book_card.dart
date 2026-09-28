import 'package:flutter/material.dart';

import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/core/widgets/widgets.dart';
import 'package:bookslane_app/features/books/domain/entities/book.dart';

/// One row of the books list: cover, title and subtitle, status, price,
/// and the two per-row actions.
class BookCard extends StatelessWidget {
  const BookCard({
    super.key,
    required this.book,
    this.onTap,
    this.onViewDetails,
    this.onEdit,
  });

  final Book book;
  final VoidCallback? onTap;

  /// The eye icon — opens [BookDetailsDialog] on this book.
  final VoidCallback? onViewDetails;

  final VoidCallback? onEdit;

  static const double _coverWidth = 72;

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
              // The Shop's 2:3 cover, at the Shop list's thumbnail width.
              SizedBox(
                width: _coverWidth,
                child: BookCover(
                  title: book.title,
                  author: book.subtitle,
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
                    // A Wrap, not a Row: beside the cover, a narrow phone leaves too
                    // little width for both pills on one line.
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xxs,
                      children: [
                        StatusPill(
                          label: book.isActive ? 'Active' : 'Inactive',
                          color: book.isActive
                              ? AppColors.successText
                              : AppColors.secondaryText,
                        ),
                        _StockPill(stock: book.stock),
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
                        onPressed: onViewDetails,
                        tooltip: 'View details',
                        background: AppColors.inputBackground,
                        child: Icon(
                          Icons.visibility_outlined,
                          size: AppSizes.iconSm,
                          color: AppColors.iconMuted,
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

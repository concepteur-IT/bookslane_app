import 'package:flutter/material.dart';

import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/features/shop/domain/entities/shop_book.dart';
import 'package:bookslane_app/core/widgets/widgets.dart';

/// One book in the grid view: the cover with the eye and any "Sold out" tag
/// laid over it, then author, title, SKU and the price with the cart button.
///
/// Needs a bounded height (the grid gives it one via IntrinsicHeight), since
/// a Spacer pins the price row to the bottom.
class ShopBookGridTile extends StatelessWidget {
  const ShopBookGridTile({
    super.key,
    required this.book,
    required this.onViewDetails,
    required this.onAddToCart,
  });

  final ShopBook book;
  final VoidCallback onViewDetails;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            _cover(book),
            if (book.isSoldOut)
              const Positioned(
                top: AppSpacing.xs,
                left: AppSpacing.xs,
                child: _SoldOutTag(),
              ),
            Positioned(
              top: AppSpacing.xs,
              right: AppSpacing.xs,
              child: _EyeButton(onPressed: onViewDetails),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.sm),

        _AuthorText(book.author),
        const SizedBox(height: 2),
        _TitleText(book.title),
        // Takes up the slack when the neighbouring tile's title wraps to two
        // lines, so both prices sit on the same baseline.
        const Spacer(),
        const SizedBox(height: AppSpacing.xs),
        _SkuText(book.sku),

        const SizedBox(height: AppSpacing.xs),

        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: _PriceBlock(book: book)),
            _CartButton(book: book, onPressed: onAddToCart),
          ],
        ),
      ],
    );
  }
}

/// One book in the list view: a thumbnail, the same text as the grid tile,
/// and the eye and cart actions on the right.
class ShopBookListRow extends StatelessWidget {
  const ShopBookListRow({
    super.key,
    required this.book,
    required this.onViewDetails,
    required this.onAddToCart,
  });

  final ShopBook book;
  final VoidCallback onViewDetails;
  final VoidCallback onAddToCart;

  static const double _thumbWidth = 72;

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
          SizedBox(width: _thumbWidth, child: _cover(book, compact: true)),

          const SizedBox(width: AppSpacing.sm),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AuthorText(book.author),
                const SizedBox(height: 2),
                _TitleText(book.title),
                const SizedBox(height: AppSpacing.xxs),
                Row(
                  children: [
                    Flexible(child: _SkuText(book.sku)),
                    if (book.isSoldOut) ...[
                      const SizedBox(width: AppSpacing.xs),
                      const _SoldOutTag(),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                _PriceBlock(book: book),
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.xs),

          SizedBox(
            height: _thumbWidth / BookCover.aspectRatio,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _EyeButton(onPressed: onViewDetails, outlined: true),
                _CartButton(book: book, onPressed: onAddToCart),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pieces shared by both layouts
// ---------------------------------------------------------------------------

Widget _cover(ShopBook book, {bool compact = false}) => BookCover(
  title: book.title,
  author: book.author,
  imageUrl: book.imageUrl,
  seed: book.id,
  compact: compact,
);

class _AuthorText extends StatelessWidget {
  const _AuthorText(this.author);

  final String author;

  @override
  Widget build(BuildContext context) {
    return Text(
      author,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.caption,
    );
  }
}

class _TitleText extends StatelessWidget {
  const _TitleText(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.titleMedium.copyWith(
        color: AppColors.headingText,
        height: 1.25,
      ),
    );
  }
}

class _SkuText extends StatelessWidget {
  const _SkuText(this.sku);

  final String sku;

  @override
  Widget build(BuildContext context) {
    return Text(
      sku,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.caption.copyWith(
        letterSpacing: 0.6,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

/// The struck-through MRP (only when discounted) over the red price.
class _PriceBlock extends StatelessWidget {
  const _PriceBlock({required this.book});

  final ShopBook book;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (book.isDiscounted)
          Text(
            book.formattedMrp,
            style: AppTypography.caption.copyWith(
              decoration: TextDecoration.lineThrough,
              decorationColor: AppColors.mutedText,
            ),
          ),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            book.formattedPrice,
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.ctaBackground,
            ),
          ),
        ),
      ],
    );
  }
}

/// The purple bag button. Faded and inert when the book is sold out.
class _CartButton extends StatelessWidget {
  const _CartButton({required this.book, required this.onPressed});

  final ShopBook book;
  final VoidCallback onPressed;

  static const double _size = 40;

  @override
  Widget build(BuildContext context) {
    final enabled = !book.isSoldOut;

    return Tooltip(
      message: enabled ? 'Add to cart' : 'Sold out',
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Material(
          color: AppColors.brandPrimary,
          borderRadius: AppRadius.smAll,
          child: InkWell(
            borderRadius: AppRadius.smAll,
            onTap: enabled ? onPressed : null,
            child: const SizedBox(
              width: _size,
              height: _size,
              child: Icon(
                Icons.shopping_bag_outlined,
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

/// The eye button. A white circle over the cover in the grid; an outlined
/// square beside the text in the list.
class _EyeButton extends StatelessWidget {
  const _EyeButton({required this.onPressed, this.outlined = false});

  final VoidCallback onPressed;
  final bool outlined;

  static const double _size = 36;

  @override
  Widget build(BuildContext context) {
    final shape = outlined
        ? const RoundedRectangleBorder(
            borderRadius: AppRadius.smAll,
            side: BorderSide(color: AppColors.borderColor),
          )
        : const CircleBorder();

    return Tooltip(
      message: 'View details',
      child: Material(
        color: AppColors.surfaceBackground,
        shape: shape,
        elevation: outlined ? 0 : 1,
        shadowColor: AppColors.cardShadow,
        child: InkWell(
          customBorder: shape,
          onTap: onPressed,
          child: const SizedBox(
            width: _size,
            height: _size,
            child: Icon(
              Icons.visibility_outlined,
              size: AppSizes.iconSm,
              color: AppColors.brandPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _SoldOutTag extends StatelessWidget {
  const _SoldOutTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
      decoration: const BoxDecoration(
        color: AppColors.soldOutTagBackground,
        borderRadius: AppRadius.xsAll,
      ),
      child: Text(
        'Sold out',
        style: AppTypography.caption.copyWith(
          color: AppColors.soldOutTagText,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

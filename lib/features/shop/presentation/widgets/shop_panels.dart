import 'package:flutter/material.dart';

import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/core/widgets/widgets.dart';
import 'package:bookslane_app/features/shop/domain/entities/shop_book.dart';

// ---------------------------------------------------------------------------
// Filter
// ---------------------------------------------------------------------------

/// Edits a draft of the filters; nothing changes on the page until Apply.
/// Pops with the new [ShopFilters], or null if dismissed.
class ShopFilterPanel extends StatefulWidget {
  const ShopFilterPanel({
    super.key,
    required this.initial,
    required this.maxPrice,
    required this.countFor,
  });

  final ShopFilters initial;
  final double maxPrice;

  /// How many books a draft would show — the Apply button says so, so you
  /// know before closing whether you've filtered down to nothing.
  final int Function(ShopFilters) countFor;

  @override
  State<ShopFilterPanel> createState() => _ShopFilterPanelState();
}

class _ShopFilterPanelState extends State<ShopFilterPanel> {
  late ShopFilters _draft = widget.initial;

  RangeValues get _range {
    final range = _draft.priceRange;
    return RangeValues(range?.min ?? 0, range?.max ?? widget.maxPrice);
  }

  void _setRange(RangeValues values) {
    setState(() {
      final isFull = values.start <= 0 && values.end >= widget.maxPrice;
      _draft = isFull
          ? _draft.copyWith(clearPriceRange: true)
          : _draft.copyWith(priceRange: (min: values.start, max: values.end));
    });
  }

  Set<T> _toggle<T>(Set<T> set, T value) =>
      set.contains(value) ? ({...set}..remove(value)) : {...set, value};

  @override
  Widget build(BuildContext context) {
    final count = widget.countFor(_draft);
    final range = _range;

    return FilterPanelFrame(
      onReset: _draft.isInitial
          ? null
          : () => setState(() => _draft = ShopFilters.initial),
      onApply: () => Navigator.of(context).pop(_draft),
      applyLabel: 'SHOW $count ${count == 1 ? 'BOOK' : 'BOOKS'}',
      sections: [
        PanelHeading(
          'Price',
          trailing:
              '₹${range.start.round()} – ₹${range.end.round()}'
              '${range.end >= widget.maxPrice ? '+' : ''}',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: RangeSlider(
            values: range,
            max: widget.maxPrice,
            divisions: 20,
            activeColor: AppColors.brandPrimary,
            inactiveColor: AppColors.brandSoftBackground,
            onChanged: _setRange,
          ),
        ),

        const PanelHeading('Availability'),
        PanelSwitchRow(
          label: 'In stock only',
          value: _draft.inStockOnly,
          onChanged: (value) => setState(() {
            _draft = _draft.copyWith(inStockOnly: value);
          }),
        ),

        const PanelHeading('Category'),
        PanelChipWrap(
          children: [
            for (final category in ShopCategory.values)
              ChoiceChipButton(
                dense: true,
                label: category.label,
                isSelected: _draft.categories.contains(category),
                onPressed: () => setState(() {
                  _draft = _draft.copyWith(
                    categories: _toggle(_draft.categories, category),
                  );
                }),
              ),
          ],
        ),

        const PanelHeading('Language'),
        PanelChipWrap(
          children: [
            for (final language in ShopLanguage.values)
              ChoiceChipButton(
                dense: true,
                label: language.label,
                isSelected: _draft.languages.contains(language),
                onPressed: () => setState(() {
                  _draft = _draft.copyWith(
                    languages: _toggle(_draft.languages, language),
                  );
                }),
              ),
          ],
        ),
      ],
    );
  }
}

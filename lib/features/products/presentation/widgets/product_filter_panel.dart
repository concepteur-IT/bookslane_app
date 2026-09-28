import 'package:flutter/material.dart';

import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/core/widgets/widgets.dart';
import 'package:bookslane_app/features/products/domain/entities/product.dart';

/// The My Publishings filter overlay — the same layout as My Store's: status,
/// stock, then category. Edits a draft; Apply pops the new [ProductFilters]
/// (null if dismissed).
///
/// Status and category are single-choice — app-api takes one of each — so
/// tapping the selected chip again clears it. The category options are the
/// caller's own, from `GET /v1/products/categories`.
class ProductFilterPanel extends StatefulWidget {
  const ProductFilterPanel({
    super.key,
    required this.initial,
    required this.categories,
    this.categoriesFailed = false,
  });

  final ProductFilters initial;
  final List<ProductCategory> categories;
  final bool categoriesFailed;

  @override
  State<ProductFilterPanel> createState() => _ProductFilterPanelState();
}

class _ProductFilterPanelState extends State<ProductFilterPanel> {
  late ProductFilters _draft = widget.initial;

  void _setStatus(bool isActive) => setState(() {
    _draft = _draft.isActive == isActive
        ? _draft.copyWith(clearIsActive: true)
        : _draft.copyWith(isActive: isActive);
  });

  void _setCategory(ProductCategory category) => setState(() {
    _draft = _draft.category == category
        ? _draft.copyWith(clearCategory: true)
        : _draft.copyWith(category: category);
  });

  @override
  Widget build(BuildContext context) {
    return FilterPanelFrame(
      onReset: _draft.isInitial
          ? null
          : () => setState(() => _draft = ProductFilters.initial),
      onApply: () => Navigator.of(context).pop(_draft),
      sections: [
        const PanelHeading('Status'),
        PanelChipWrap(
          children: [
            ChoiceChipButton(
              dense: true,
              label: 'Active',
              isSelected: _draft.isActive == true,
              onPressed: () => _setStatus(true),
            ),
            ChoiceChipButton(
              dense: true,
              label: 'Inactive',
              isSelected: _draft.isActive == false,
              onPressed: () => _setStatus(false),
            ),
          ],
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
        if (widget.categories.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              widget.categoriesFailed
                  ? "Categories couldn't be loaded."
                  : 'No categories yet.',
              style: AppTypography.bodySmall,
            ),
          )
        else
          PanelChipWrap(
            children: [
              for (final category in widget.categories)
                ChoiceChipButton(
                  dense: true,
                  label: category.name,
                  isSelected: _draft.category == category,
                  onPressed: () => _setCategory(category),
                ),
            ],
          ),
      ],
    );
  }
}

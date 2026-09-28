import 'package:flutter/material.dart';

import 'package:bookslane_app/core/widgets/widgets.dart';
import 'package:bookslane_app/features/books/domain/entities/book.dart';
import 'package:bookslane_app/features/books/domain/entities/book_form_options.dart';

/// The My Store filter overlay: status, stock, then category. Edits a draft;
/// nothing changes on the page until Apply, which pops the new
/// [BookFilters] (null if dismissed).
///
/// Status and category are single-choice — app-api takes one of each — so
/// tapping the selected chip again clears it.
class BookFilterPanel extends StatefulWidget {
  const BookFilterPanel({super.key, required this.initial});

  final BookFilters initial;

  @override
  State<BookFilterPanel> createState() => _BookFilterPanelState();
}

class _BookFilterPanelState extends State<BookFilterPanel> {
  late BookFilters _draft = widget.initial;

  void _setStatus(bool isActive) => setState(() {
    _draft = _draft.isActive == isActive
        ? _draft.copyWith(clearIsActive: true)
        : _draft.copyWith(isActive: isActive);
  });

  void _setCategory(BookCategory category) => setState(() {
    _draft = _draft.category == category
        ? _draft.copyWith(clearCategory: true)
        : _draft.copyWith(category: category);
  });

  @override
  Widget build(BuildContext context) {
    return FilterPanelFrame(
      onReset: _draft.isInitial
          ? null
          : () => setState(() => _draft = BookFilters.initial),
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
        PanelChipWrap(
          children: [
            for (final category in BookCategory.values)
              ChoiceChipButton(
                dense: true,
                label: category.label,
                isSelected: _draft.category == category,
                onPressed: () => _setCategory(category),
              ),
          ],
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/core/widgets/widgets.dart';
import 'package:bookslane_app/features/books/domain/entities/book.dart';

/// The All / Active / Inactive / In stock row.
class BookFilterBar extends StatelessWidget {
  const BookFilterBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final BookFilter selected;
  final ValueChanged<BookFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          for (final filter in BookFilter.values) ...[
            ChoiceChipButton(
              label: filter.label,
              isSelected: filter == selected,
              selectedColor: AppColors.brandPrimary,
              onPressed: () => onChanged(filter),
            ),
            if (filter != BookFilter.values.last)
              const SizedBox(width: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

/// The Sort row: a label, then Newest / Name / Qty / Price.
class BookSortBar extends StatelessWidget {
  const BookSortBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final BookSort selected;
  final ValueChanged<BookSort> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          Icon(Icons.tune_rounded, size: AppSizes.iconMd, color: AppColors.iconMuted),
          const SizedBox(width: AppSpacing.xs),
          Text('Sort', style: AppTypography.bodyMedium),
          const SizedBox(width: AppSpacing.sm),
          for (final sort in BookSort.values) ...[
            ChoiceChipButton(
              // The active sort shows which way it runs.
              label: sort == selected ? '${sort.label} ↓' : sort.label,
              isSelected: sort == selected,
              selectedColor: AppColors.headingText,
              onPressed: () => onChanged(sort),
            ),
            if (sort != BookSort.values.last)
              const SizedBox(width: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/features/books/domain/entities/book.dart';

/// The Books tab's first screen: pick a shelf.
///
/// Two large targets rather than a segmented control — this is the whole
/// content of the tab, and both destinations are equally important.
class BooksHubPage extends StatelessWidget {
  const BooksHubPage({super.key, required this.onSourceSelected});

  final ValueChanged<BookSource> onSourceSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.lg,
        AppSpacing.page,
        AppSpacing.xl,
      ),
      children: [
        Text('Books', style: AppTypography.displayMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Choose which shelf you want to work on.',
          style: AppTypography.bodyMedium,
        ),

        const SizedBox(height: AppSpacing.xl),

        _SourceButton(
          source: BookSource.store,
          icon: Icons.storefront_outlined,
          onPressed: () => onSourceSelected(BookSource.store),
        ),

        const SizedBox(height: AppSpacing.md),

        _SourceButton(
          source: BookSource.publishings,
          icon: Icons.auto_stories_outlined,
          onPressed: () => onSourceSelected(BookSource.publishings),
        ),
      ],
    );
  }
}

/// One of the two large buttons.
class _SourceButton extends StatelessWidget {
  const _SourceButton({
    required this.source,
    required this.icon,
    required this.onPressed,
  });

  final BookSource source;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.xlAll,
        onTap: onPressed,
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppGradients.brandHeader,
            borderRadius: AppRadius.xlAll,
            boxShadow: AppShadows.card,
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: AppSizes.tileLg,
                height: AppSizes.tileLg,
                decoration: BoxDecoration(
                  color: AppColors.inverseText.withValues(alpha: 0.15),
                  borderRadius: AppRadius.mdAll,
                ),
                child: Icon(
                  icon,
                  size: AppSizes.iconLg,
                  color: AppColors.inverseText,
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      source.label,
                      style: AppTypography.headlineMedium.copyWith(
                        color: AppColors.brandHeaderText,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      source.description,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.brandHeaderSubtitleText,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.arrow_forward_rounded,
                size: AppSizes.iconLg,
                color: AppColors.brandHeaderText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

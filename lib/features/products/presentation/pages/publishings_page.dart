import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bookslane_app/core/network/api_failure.dart';
import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/core/widgets/widgets.dart';
import 'package:bookslane_app/features/products/domain/entities/product.dart';
import 'package:bookslane_app/features/products/domain/repositories/products_repository.dart';
import 'package:bookslane_app/features/products/presentation/providers/products_provider.dart';
import 'package:bookslane_app/features/products/presentation/widgets/product_card.dart';
import 'package:bookslane_app/features/products/presentation/widgets/update_quantity_sheet.dart';

/// My Publishings — the signed-in publisher's catalogue from `/v1/products`.
///
/// Creates its own [ProductsProvider] so the list state lives and dies with
/// the screen; the repository comes from the app-wide graph.
class PublishingsPage extends StatelessWidget {
  const PublishingsPage({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ProductsProvider>(
      create: (_) =>
          ProductsProvider(context.read<ProductsRepository>())..load(),
      child: _PublishingsView(onBack: onBack),
    );
  }
}

class _PublishingsView extends StatelessWidget {
  const _PublishingsView({this.onBack});

  final VoidCallback? onBack;

  Future<void> _editQuantity(BuildContext context, Product product) async {
    final provider = context.read<ProductsProvider>();

    final newTotal = await showUpdateQuantitySheet(
      context: context,
      product: product,
      onSubmit: (quantity) async {
        try {
          await provider.updateQuantity(
            productId: product.id,
            newQuantity: quantity,
          );
        } on ApiFailure catch (failure) {
          if (context.mounted) AppToast.error(context, failure.message);
          rethrow; // keeps the sheet open with the number intact
        }
      },
    );

    if (newTotal != null && context.mounted) {
      AppToast.success(context, '${product.name} now has $newTotal in stock.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductsProvider>();

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      // The page owns its bar: on an inner screen the logo and app name earn
      // less than the space they cost.
      appBar: InnerPageAppBar(
        title: 'My Publishings',
        subtitle: provider.total > 0 ? '${provider.total} titles' : null,
        onBack: onBack,
        actions: [
          IconButton(
            onPressed: provider.refresh,
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            color: AppColors.iconPrimary,
          ),
        ],
        searchField: AppSearchField(
          hintText: 'Search name, author, code or ISBN...',
          onChanged: provider.setSearch,
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: AppSpacing.md),

          _FilterRow(provider: provider),

          const SizedBox(height: AppSpacing.sm),

          _SortRow(provider: provider),

          const SizedBox(height: AppSpacing.md),

          Expanded(
            child: _Body(provider: provider, onEdit: _editQuantity),
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.provider});

  final ProductsProvider provider;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          for (final filter in ProductFilter.values) ...[
            ChoiceChipButton(
              label: filter.label,
              isSelected: filter == provider.filter,
              selectedColor: AppColors.brandPrimary,
              onPressed: () => provider.setFilter(filter),
            ),
            if (filter != ProductFilter.values.last)
              const SizedBox(width: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _SortRow extends StatelessWidget {
  const _SortRow({required this.provider});

  final ProductsProvider provider;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          Icon(
            Icons.tune_rounded,
            size: AppSizes.iconMd,
            color: AppColors.iconMuted,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text('Sort', style: AppTypography.bodyMedium),
          const SizedBox(width: AppSpacing.sm),
          for (final sort in ProductSort.values) ...[
            ChoiceChipButton(
              label: sort == provider.sort ? '${sort.label} ↓' : sort.label,
              isSelected: sort == provider.sort,
              selectedColor: AppColors.headingText,
              onPressed: () => provider.setSort(sort),
            ),
            if (sort != ProductSort.values.last)
              const SizedBox(width: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.provider, required this.onEdit});

  final ProductsProvider provider;
  final Future<void> Function(BuildContext, Product) onEdit;

  @override
  Widget build(BuildContext context) {
    // First load only: later refetches keep the list on screen and dim it, so
    // paging doesn't flash an empty page.
    if (provider.status == ProductsStatus.loading &&
        provider.products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.status == ProductsStatus.error) {
      return _ErrorState(
        message: provider.errorMessage ?? 'Something went wrong.',
        onRetry: provider.refresh,
      );
    }

    if (provider.products.isEmpty) {
      return const _EmptyState();
    }

    return Opacity(
      opacity: provider.isLoading ? 0.5 : 1,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.xl,
        ),
        children: [
          for (final product in provider.products) ...[
            ProductCard(
              product: product,
              onEditQuantity: () => onEdit(context, product),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],

          const SizedBox(height: AppSpacing.xs),

          PaginationBar(
            shown: provider.products.length,
            total: provider.total,
            page: provider.currentPage,
            pageCount: provider.totalPages,
            onPrevious: provider.hasPrevious ? provider.previousPage : null,
            onNext: provider.hasNext ? provider.nextPage : null,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: AppSizes.logoTile,
              color: AppColors.disabledText,
            ),
            const SizedBox(height: AppSpacing.md),
            Text('No products here.', style: AppTypography.titleLarge),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Nothing matches this search or filter.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: AppSizes.logoTile,
              color: AppColors.disabledText,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(onPressed: onRetry, child: const Text('TRY AGAIN')),
          ],
        ),
      ),
    );
  }
}

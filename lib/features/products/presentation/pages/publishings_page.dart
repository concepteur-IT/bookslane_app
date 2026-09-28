import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bookslane_app/core/network/api_failure.dart';
import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/core/widgets/widgets.dart';
import 'package:bookslane_app/features/products/domain/entities/product.dart';
import 'package:bookslane_app/features/products/domain/repositories/products_repository.dart';
import 'package:bookslane_app/features/products/presentation/providers/products_provider.dart';
import 'package:bookslane_app/features/products/presentation/widgets/product_card.dart';
import 'package:bookslane_app/features/products/presentation/widgets/product_details_dialog.dart';
import 'package:bookslane_app/features/products/presentation/widgets/product_filter_panel.dart';
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
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: _PublishingsToolbar(provider: provider),
          ),

          Expanded(
            child: _Body(provider: provider, onEdit: _editQuantity),
          ),
        ],
      ),
    );
  }
}

/// Search, filter and sort on one line — the Shop's toolbar, over
/// [ProductsProvider]. Stateful only to own the key the overlays anchor to.
class _PublishingsToolbar extends StatefulWidget {
  const _PublishingsToolbar({required this.provider});

  final ProductsProvider provider;

  @override
  State<_PublishingsToolbar> createState() => _PublishingsToolbarState();
}

class _PublishingsToolbarState extends State<_PublishingsToolbar> {
  final GlobalKey _anchor = GlobalKey();

  Future<void> _openFilters() async {
    final provider = widget.provider;
    final filters = await showAnchoredPanel<ProductFilters>(
      context: context,
      anchor: _anchor,
      builder: (_) => ProductFilterPanel(
        initial: provider.filters,
        categories: provider.categories,
        categoriesFailed: provider.categoriesFailed,
      ),
    );
    if (filters != null) await provider.setFilters(filters);
  }

  Future<void> _openSort() async {
    final sort = await showAnchoredPanel<ProductSort>(
      context: context,
      anchor: _anchor,
      maxWidth: 280,
      builder: (_) => SortPanel<ProductSort>(
        options: ProductSort.values,
        selected: widget.provider.sort,
        initial: ProductSort.initial,
        labelOf: (sort) => sort.label,
      ),
    );
    if (sort != null) await widget.provider.setSort(sort);
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;

    return ListToolbar(
      key: _anchor,
      searchHint: 'Name, author, code or ISBN',
      filterCount: provider.filters.activeCount,
      isSorted: provider.sort != ProductSort.initial,
      onSearchChanged: provider.setSearch,
      onFilterPressed: _openFilters,
      onSortPressed: _openSort,
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
              onViewDetails: () => ProductDetailsDialog.show(context, product),
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

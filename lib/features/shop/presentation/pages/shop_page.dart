import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bookslane_app/core/filters/catalog_filters.dart';
import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/core/widgets/widgets.dart';
import 'package:bookslane_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:bookslane_app/features/shop/domain/entities/shop_book.dart';
import 'package:bookslane_app/features/shop/domain/repositories/shop_repository.dart';
import 'package:bookslane_app/features/shop/presentation/providers/shop_provider.dart';
import 'package:bookslane_app/features/shop/presentation/widgets/shop_book_details_dialog.dart';
import 'package:bookslane_app/features/shop/presentation/widgets/shop_book_tile.dart';

/// The Shop tab: the account's two shelves — My Publishings and My Store — as
/// one list of books (or a grid of covers). Each card says which shelf it came
/// from. Search, filters, sort and paging all run on the server —
/// `GET /v1/shop/books`, with the filter panel's options from
/// `GET /v1/shop/filters`.
///
/// "Add to cart" fills the in-memory [CartProvider] (the count on the app
/// bar); "View details" opens a dialog from the row already loaded. The
/// branded app bar and bottom bar come from DashboardPage, so this is just
/// the body under them.
class ShopPage extends StatelessWidget {
  const ShopPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ShopProvider>(
      create: (_) => ShopProvider(context.read<ShopRepository>())..load(),
      child: const _ShopView(),
    );
  }
}

class _ShopView extends StatefulWidget {
  const _ShopView();

  @override
  State<_ShopView> createState() => _ShopViewState();
}

class _ShopViewState extends State<_ShopView> {
  /// The filter and sort overlays drop down from under this row.
  final GlobalKey _toolbarKey = GlobalKey();

  // List only for now — the grid/list toggle in build() is commented out.
  // Not final: the commented-out toggle writes it.
  // ignore: prefer_final_fields
  ShopView _view = ShopView.list;

  Future<void> _openFilters() async {
    final provider = context.read<ShopProvider>();
    final filters = await showAnchoredPanel<CatalogFilters>(
      context: context,
      anchor: _toolbarKey,
      builder: (_) => DynamicFilterPanel(
        spec: ShopProvider.filterSpec,
        initial: provider.filters,
        loadFacets: provider.loadFacets,
      ),
    );
    if (filters != null) await provider.setFilters(filters);
  }

  Future<void> _openSort() async {
    final provider = context.read<ShopProvider>();
    final sort = await showAnchoredPanel<ShopSort>(
      context: context,
      anchor: _toolbarKey,
      maxWidth: 280,
      builder: (_) => SortPanel<ShopSort>(
        options: ShopSort.values,
        selected: provider.sort,
        initial: ShopSort.initial,
        labelOf: (sort) => sort.label,
      ),
    );
    if (sort != null) await provider.setSort(sort);
  }

  void _viewDetails(ShopBook book) => ShopBookDetailsDialog.show(context, book);

  void _addToCart(ShopBook book) {
    switch (context.read<CartProvider>().add(book)) {
      case CartAddResult.added:
        AppToast.success(context, '${book.title} added to cart.');
      case CartAddResult.atStockLimit:
        AppToast.info(
          context,
          'Only ${book.stock} of ${book.title} in stock — all are in your cart.',
        );
      case CartAddResult.soldOut:
        AppToast.info(context, '${book.title} is sold out.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ShopProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            0,
          ),
          child: ListToolbar(
            // On the row itself, not the padding, so overlays line up with
            // the search box and the last button rather than the screen edge.
            key: _toolbarKey,
            filterCount: provider.filters.activeCount(
              ShopProvider.filterSpec.initial,
            ),
            isSorted: provider.sort != ShopSort.initial,
            onSearchChanged: provider.setSearch,
            onFilterPressed: _openFilters,
            onSortPressed: _openSort,
            // Grid/list toggle — disabled for now, the Shop shows the list
            // only. Uncomment (and set _view back to ShopView.grid) to bring
            // the grid back; the grid view itself is still built.
            // trailing: [
            //   // Shows what you'd switch *to*, like most shop apps.
            //   ToolbarIconButton(
            //     icon: _view == ShopView.grid
            //         ? Icons.view_agenda_outlined
            //         : Icons.grid_view_rounded,
            //     tooltip: _view == ShopView.grid ? 'List view' : 'Grid view',
            //     onPressed: () => setState(() {
            //       _view = _view == ShopView.grid
            //           ? ShopView.list
            //           : ShopView.grid;
            //     }),
            //   ),
            // ],
          ),
        ),

        Expanded(
          child: _Body(
            provider: provider,
            view: _view,
            onViewDetails: _viewDetails,
            onAddToCart: _addToCart,
          ),
        ),
      ],
    );
  }
}

/// Loading, error, empty and the listing itself.
class _Body extends StatelessWidget {
  const _Body({
    required this.provider,
    required this.view,
    required this.onViewDetails,
    required this.onAddToCart,
  });

  final ShopProvider provider;
  final ShopView view;
  final ValueChanged<ShopBook> onViewDetails;
  final ValueChanged<ShopBook> onAddToCart;

  @override
  Widget build(BuildContext context) {
    // First load only: later refetches keep the list on screen and dim it, so
    // paging doesn't flash an empty page.
    if (provider.status == ShopStatus.loading && provider.books.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.status == ShopStatus.error) {
      return _ErrorState(
        message: provider.errorMessage ?? 'Something went wrong.',
        onRetry: provider.refresh,
      );
    }

    if (provider.books.isEmpty) {
      return _EmptyState(
        canClear: !provider.filters.isInitial(ShopProvider.filterSpec.initial),
        onClear: () => provider.setFilters(ShopProvider.filterSpec.initial),
      );
    }

    final footer = PaginationBar(
      shown: provider.books.length,
      total: provider.total,
      page: provider.currentPage,
      pageCount: provider.totalPages,
      onPrevious: provider.hasPrevious ? provider.previousPage : null,
      onNext: provider.hasNext ? provider.nextPage : null,
    );

    return Opacity(
      opacity: provider.isLoading ? 0.5 : 1,
      child: view == ShopView.grid
          ? _Grid(
              books: provider.books,
              footer: footer,
              onViewDetails: onViewDetails,
              onAddToCart: onAddToCart,
            )
          : _List(
              books: provider.books,
              footer: footer,
              onViewDetails: onViewDetails,
              onAddToCart: onAddToCart,
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Listing
// ---------------------------------------------------------------------------

const EdgeInsets _listingPadding = EdgeInsets.fromLTRB(
  AppSpacing.md,
  AppSpacing.md,
  AppSpacing.md,
  AppSpacing.xl,
);

/// Two columns, built a row at a time so both tiles in a row share a height
/// and their price lines up even when one title wraps and the other doesn't.
class _Grid extends StatelessWidget {
  const _Grid({
    required this.books,
    required this.footer,
    required this.onViewDetails,
    required this.onAddToCart,
  });

  final List<ShopBook> books;
  final Widget footer;
  final ValueChanged<ShopBook> onViewDetails;
  final ValueChanged<ShopBook> onAddToCart;

  @override
  Widget build(BuildContext context) {
    final rowCount = (books.length / 2).ceil();

    return ListView.separated(
      padding: _listingPadding,
      itemCount: rowCount + 1,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
      itemBuilder: (context, row) {
        if (row == rowCount) return footer;
        final left = books[row * 2];
        final right = row * 2 + 1 < books.length ? books[row * 2 + 1] : null;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _tile(left)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: right == null ? const SizedBox() : _tile(right)),
            ],
          ),
        );
      },
    );
  }

  Widget _tile(ShopBook book) => ShopBookGridTile(
    book: book,
    onViewDetails: () => onViewDetails(book),
    onAddToCart: () => onAddToCart(book),
  );
}

class _List extends StatelessWidget {
  const _List({
    required this.books,
    required this.footer,
    required this.onViewDetails,
    required this.onAddToCart,
  });

  final List<ShopBook> books;
  final Widget footer;
  final ValueChanged<ShopBook> onViewDetails;
  final ValueChanged<ShopBook> onAddToCart;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: _listingPadding,
      itemCount: books.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        if (index == books.length) return footer;
        final book = books[index];
        return ShopBookListRow(
          book: book,
          onViewDetails: () => onViewDetails(book),
          onAddToCart: () => onAddToCart(book),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.canClear, required this.onClear});

  final bool canClear;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: AppSizes.logoTile,
              color: AppColors.disabledText,
            ),
            const SizedBox(height: AppSpacing.md),
            Text('No books match that.', style: AppTypography.titleLarge),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Try a different search or filter.',
              style: AppTypography.bodyMedium,
            ),
            if (canClear) ...[
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton(
                onPressed: onClear,
                child: const Text('CLEAR FILTERS'),
              ),
            ],
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
            const Icon(
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

import 'package:flutter/material.dart';

import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/core/widgets/widgets.dart';
import 'package:bookslane_app/features/shop/domain/entities/sample_shop_books.dart';
import 'package:bookslane_app/features/shop/domain/entities/shop_book.dart';
import 'package:bookslane_app/features/shop/presentation/widgets/shop_book_tile.dart';
import 'package:bookslane_app/features/shop/presentation/widgets/shop_panels.dart';

/// The Shop tab: the catalogue to order from, as a grid of covers or a list.
///
/// MOCKUP: runs over [SampleShopBooks] in memory, and "View details" and "Add
/// to cart" only toast. The branded app bar and bottom bar come from
/// DashboardPage, so this is just the body under them.
class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  /// The filter and sort overlays drop down from under this row.
  final GlobalKey _toolbarKey = GlobalKey();

  final List<ShopBook> _books = SampleShopBooks.all;

  String _query = '';
  ShopFilters _filters = ShopFilters.initial;
  ShopSort _sort = ShopSort.initial;
  // List only for now — the grid/list toggle in build() is commented out.
  // Not final: the commented-out toggle writes it.
  // ignore: prefer_final_fields
  ShopView _view = ShopView.list;

  List<ShopBook> _matching(ShopFilters filters) {
    final query = _query.trim().toLowerCase();
    return _books.where((book) {
      if (!filters.matches(book)) return false;
      if (query.isEmpty) return true;
      return book.title.toLowerCase().contains(query) ||
          book.author.toLowerCase().contains(query) ||
          book.sku.toLowerCase().contains(query);
    }).toList();
  }

  List<ShopBook> get _visible => _matching(_filters)..sort(_sort.compare);

  Future<void> _openFilters() async {
    final filters = await showAnchoredPanel<ShopFilters>(
      context: context,
      anchor: _toolbarKey,
      builder: (_) => ShopFilterPanel(
        initial: _filters,
        maxPrice: SampleShopBooks.maxPrice,
        countFor: (draft) => _matching(draft).length,
      ),
    );
    if (filters != null) setState(() => _filters = filters);
  }

  Future<void> _openSort() async {
    final sort = await showAnchoredPanel<ShopSort>(
      context: context,
      anchor: _toolbarKey,
      maxWidth: 280,
      builder: (_) => SortPanel<ShopSort>(
        options: ShopSort.values,
        selected: _sort,
        initial: ShopSort.initial,
        labelOf: (sort) => sort.label,
      ),
    );
    if (sort != null) setState(() => _sort = sort);
  }

  void _viewDetails(ShopBook book) =>
      AppToast.info(context, 'Details for ${book.title} — coming soon.');

  void _addToCart(ShopBook book) =>
      AppToast.success(context, '${book.title} added to cart.');

  @override
  Widget build(BuildContext context) {
    final visible = _visible;

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
            filterCount: _filters.activeCount,
            isSorted: _sort != ShopSort.initial,
            onSearchChanged: (value) => setState(() => _query = value),
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
          child: visible.isEmpty
              ? _EmptyState(
                  canClear: !_filters.isInitial,
                  onClear: () => setState(() => _filters = ShopFilters.initial),
                )
              : _view == ShopView.grid
              ? _Grid(
                  books: visible,
                  onViewDetails: _viewDetails,
                  onAddToCart: _addToCart,
                )
              : _List(
                  books: visible,
                  onViewDetails: _viewDetails,
                  onAddToCart: _addToCart,
                ),
        ),
      ],
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
    required this.onViewDetails,
    required this.onAddToCart,
  });

  final List<ShopBook> books;
  final ValueChanged<ShopBook> onViewDetails;
  final ValueChanged<ShopBook> onAddToCart;

  @override
  Widget build(BuildContext context) {
    final rowCount = (books.length / 2).ceil();

    return ListView.separated(
      padding: _listingPadding,
      itemCount: rowCount,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
      itemBuilder: (context, row) {
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
    required this.onViewDetails,
    required this.onAddToCart,
  });

  final List<ShopBook> books;
  final ValueChanged<ShopBook> onViewDetails;
  final ValueChanged<ShopBook> onAddToCart;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: _listingPadding,
      itemCount: books.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
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

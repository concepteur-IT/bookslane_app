import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bookslane_app/core/network/api_failure.dart';
import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/core/widgets/widgets.dart';
import 'package:bookslane_app/features/books/domain/entities/book.dart';
import 'package:bookslane_app/features/books/domain/entities/book_detail.dart';
import 'package:bookslane_app/features/books/domain/repositories/books_repository.dart';
import 'package:bookslane_app/features/books/presentation/providers/books_provider.dart';
import 'package:bookslane_app/features/books/presentation/widgets/book_card.dart';
import 'package:bookslane_app/features/books/presentation/widgets/book_details_dialog.dart';
import 'package:bookslane_app/features/books/presentation/widgets/book_filter_panel.dart';
import 'package:bookslane_app/features/books/presentation/widgets/add_book.dart';
import 'package:bookslane_app/features/products/presentation/pages/publishings_page.dart';

/// One Books shelf, chosen by [source]:
///
/// * `My Store` — the caller's own books, backed by [BooksProvider] over
///   `GET /v1/books`.
/// * `My Publishings` — the caller's imprint catalogue in the thinkerslane
///   (legacy) database, served by app-api's `GET /v1/products`. That shelf
///   has its own feature and page, [PublishingsPage]; this just routes to it.
class BookListPage extends StatelessWidget {
  const BookListPage({super.key, required this.source, this.onBack});

  final BookSource source;

  /// Returns to the hub. The tab keeps its own history, so the bottom bar
  /// stays put instead of a full-screen route covering it.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    if (source == BookSource.store) {
      return ChangeNotifierProvider<BooksProvider>(
        create: (_) => BooksProvider(context.read<BooksRepository>())..load(),
        child: _StoreBookListView(onBack: onBack),
      );
    }
    return PublishingsPage(onBack: onBack);
  }
}

// ---------------------------------------------------------------------------
// My Store — real data, via BooksProvider.
// ---------------------------------------------------------------------------

class _StoreBookListView extends StatelessWidget {
  const _StoreBookListView({this.onBack});

  final VoidCallback? onBack;

  Future<void> _addBook(BuildContext context) async {
    final provider = context.read<BooksProvider>();

    final draft = await AddBookForm.show(
      context,
      source: BookSource.store,
      onSubmit: (draft) async {
        try {
          await provider.createBook(draft);
        } on ApiFailure catch (failure) {
          if (context.mounted) AppToast.error(context, failure.message);
          rethrow; // keeps the sheet open with every field intact
        }
      },
    );

    if (draft != null && context.mounted) {
      AppToast.success(
        context,
        '${draft.title} added to ${BookSource.store.label}.',
      );
    }
  }

  /// Fetches a book's full detail behind a loading dialog — the list row
  /// doesn't carry enough for either the details popup or the Edit Book
  /// form. Returns null (having already shown the toast) on failure.
  Future<BookDetail?> _fetchDetail(BuildContext context, Book book) async {
    final provider = context.read<BooksProvider>();

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final detail = await provider.getBookDetail(book.id);
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      return detail;
    } on ApiFailure catch (failure) {
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      if (context.mounted) AppToast.error(context, failure.message);
      return null;
    }
  }

  Future<void> _viewDetails(BuildContext context, Book book) async {
    final detail = await _fetchDetail(context, book);
    if (detail == null || !context.mounted) return;
    await BookDetailsDialog.show(context, detail);
  }

  /// Fetches the book's full detail, then opens the Edit Book sheet on it.
  Future<void> _editBook(BuildContext context, Book book) async {
    final provider = context.read<BooksProvider>();

    final detail = await _fetchDetail(context, book);
    if (detail == null || !context.mounted) return;

    final draft = await AddBookForm.showEdit(
      context,
      initial: detail,
      onSubmit: (draft) async {
        try {
          await provider.updateBook(book.id, draft);
        } on ApiFailure catch (failure) {
          if (context.mounted) AppToast.error(context, failure.message);
          rethrow; // keeps the sheet open with every field intact
        }
      },
    );

    if (draft != null && context.mounted) {
      AppToast.success(context, '${draft.title} updated.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BooksProvider>();

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: InnerPageAppBar(
        title: BookSource.store.label,
        subtitle: provider.total > 0 ? '${provider.total} books' : null,
        onBack: onBack,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: _AddButton(onPressed: () => _addBook(context)),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: _StoreToolbar(provider: provider),
          ),

          Expanded(
            child: _StoreBody(
              provider: provider,
              onViewDetails: _viewDetails,
              onEdit: _editBook,
            ),
          ),
        ],
      ),
    );
  }
}

/// Search, filter and sort on one line — the Shop's toolbar, over
/// [BooksProvider]. Stateful only to own the key the overlays anchor to.
class _StoreToolbar extends StatefulWidget {
  const _StoreToolbar({required this.provider});

  final BooksProvider provider;

  @override
  State<_StoreToolbar> createState() => _StoreToolbarState();
}

class _StoreToolbarState extends State<_StoreToolbar> {
  final GlobalKey _anchor = GlobalKey();

  Future<void> _openFilters() async {
    final filters = await showAnchoredPanel<BookFilters>(
      context: context,
      anchor: _anchor,
      builder: (_) => BookFilterPanel(initial: widget.provider.filters),
    );
    if (filters != null) await widget.provider.setFilters(filters);
  }

  Future<void> _openSort() async {
    final sort = await showAnchoredPanel<BookSort>(
      context: context,
      anchor: _anchor,
      maxWidth: 280,
      builder: (_) => SortPanel<BookSort>(
        options: BookSort.values,
        selected: widget.provider.sort,
        initial: BookSort.initial,
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
      filterCount: provider.filters.activeCount,
      isSorted: provider.sort != BookSort.initial,
      onSearchChanged: provider.setSearch,
      onFilterPressed: _openFilters,
      onSortPressed: _openSort,
    );
  }
}

class _StoreBody extends StatelessWidget {
  const _StoreBody({
    required this.provider,
    required this.onViewDetails,
    required this.onEdit,
  });

  final BooksProvider provider;
  final Future<void> Function(BuildContext, Book) onViewDetails;
  final Future<void> Function(BuildContext, Book) onEdit;

  @override
  Widget build(BuildContext context) {
    // First load only: later refetches keep the list on screen and dim it, so
    // paging doesn't flash an empty page — the same as PublishingsPage.
    if (provider.status == BooksStatus.loading && provider.books.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.status == BooksStatus.error) {
      return _ErrorState(
        message: provider.errorMessage ?? 'Something went wrong.',
        onRetry: provider.refresh,
      );
    }

    if (provider.books.isEmpty) {
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
          for (final book in provider.books) ...[
            BookCard(
              book: book,
              onViewDetails: () => onViewDetails(context, book),
              onEdit: () => onEdit(context, book),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],

          const SizedBox(height: AppSpacing.xs),

          PaginationBar(
            shown: provider.books.length,
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

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------

/// The red "+ Add" pill.
class _AddButton extends StatelessWidget {
  const _AddButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.ctaBackground,
      borderRadius: AppRadius.pillAll,
      child: InkWell(
        borderRadius: AppRadius.pillAll,
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_rounded,
                size: AppSizes.iconMd,
                color: AppColors.ctaIcon,
              ),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                'Add',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.ctaText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
      child: Column(
        children: [
          Icon(
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
        ],
      ),
    );
  }
}

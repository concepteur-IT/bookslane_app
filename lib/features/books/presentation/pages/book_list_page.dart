import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bookslane_app/core/network/api_failure.dart';
import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/core/widgets/widgets.dart';
import 'package:bookslane_app/features/books/domain/entities/book.dart';
import 'package:bookslane_app/features/books/domain/entities/book_draft.dart';
import 'package:bookslane_app/features/books/domain/entities/book_form_options.dart';
import 'package:bookslane_app/features/books/domain/entities/sample_books.dart';
import 'package:bookslane_app/features/books/domain/repositories/books_repository.dart';
import 'package:bookslane_app/features/books/presentation/providers/books_provider.dart';
import 'package:bookslane_app/features/books/presentation/widgets/book_card.dart';
import 'package:bookslane_app/features/books/presentation/widgets/book_filter_bar.dart';
import 'package:bookslane_app/features/books/presentation/widgets/add_book.dart';

/// The `My Store` shelf: real data, backed by [BooksProvider] over
/// `GET /v1/books`. This is the only [source] `DashboardPage` ever routes
/// here with — `My Publishings` goes to [PublishingsPage] over `/v1/products`
/// instead, chosen there rather than here (see its comment on `_body`).
///
/// [source] still accepts [BookSource.publishings] and, if given it, falls
/// back to the old sample-data view rather than crashing: `owner_books` has
/// no column yet that says which shelf a book belongs to, so nothing here
/// could ask the API for "just the publishings" if it wanted to. That branch
/// only runs today when a test constructs this widget directly with
/// `source: BookSource.publishings` — see `books_test.dart`.
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
    return _SampleBookListPage(source: source, onBack: onBack);
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

  Future<void> _toggleActive(BuildContext context, Book book) async {
    final provider = context.read<BooksProvider>();
    final wasActive = book.isActive;

    try {
      await provider.toggleActive(book);
      if (context.mounted) {
        AppToast.info(
          context,
          '${book.title} is now ${wasActive ? 'inactive' : 'active'}.',
        );
      }
    } on ApiFailure catch (failure) {
      if (context.mounted) AppToast.error(context, failure.message);
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
        searchField: AppSearchField(
          hintText: 'Search books...',
          onChanged: provider.setSearch,
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: AppSpacing.md),

          BookFilterBar(selected: provider.filter, onChanged: provider.setFilter),

          const SizedBox(height: AppSpacing.sm),

          BookSortBar(selected: provider.sort, onChanged: provider.setSort),

          const SizedBox(height: AppSpacing.md),

          Expanded(child: _StoreBody(provider: provider, onToggleActive: _toggleActive)),
        ],
      ),
    );
  }
}

class _StoreBody extends StatelessWidget {
  const _StoreBody({required this.provider, required this.onToggleActive});

  final BooksProvider provider;
  final Future<void> Function(BuildContext, Book) onToggleActive;

  @override
  Widget build(BuildContext context) {
    // First load only: later refetches keep the list on screen and dim it, so
    // paging doesn't flash an empty page — see PublishingsPage._Body.
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
              onToggleActive: () => onToggleActive(context, book),
              onEdit: () => AppToast.info(
                context,
                'Editing ${book.title} is not built yet.',
              ),
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
// My Publishings — sample data, in memory. Unchanged until app-api can tell
// the two shelves apart.
// ---------------------------------------------------------------------------

class _SampleBookListPage extends StatefulWidget {
  const _SampleBookListPage({required this.source, this.onBack});

  final BookSource source;
  final VoidCallback? onBack;

  @override
  State<_SampleBookListPage> createState() => _SampleBookListPageState();
}

class _SampleBookListPageState extends State<_SampleBookListPage> {
  static const int _pageSize = 6;

  late List<Book> _books = [...SampleBooks.forSource(widget.source)];

  String _query = '';
  BookFilter _filter = BookFilter.all;
  BookSort _sort = BookSort.newest;
  int _page = 0;

  /// Everything matching the search box and the filter chip, in sort order.
  List<Book> get _matching {
    final query = _query.trim().toLowerCase();

    final matches = _books.where((book) {
      if (!_filter.matches(book)) return false;
      if (query.isEmpty) return true;
      return book.title.toLowerCase().contains(query) ||
          book.subtitle.toLowerCase().contains(query);
    }).toList();

    matches.sort(_sort.compare);
    return matches;
  }

  int get _pageCount => (_matching.length / _pageSize).ceil().clamp(1, 999);

  List<Book> get _visible {
    final matches = _matching;
    final start = _page * _pageSize;
    if (start >= matches.length) return const [];
    return matches.sublist(start, (start + _pageSize).clamp(0, matches.length));
  }

  /// Any change to the query, filter or sort restarts at page one — otherwise
  /// you can end up on page 3 of a two-page result and see nothing.
  void _resetPage() => _page = 0;

  void _toggleActive(Book book) {
    setState(() {
      _books = [
        for (final b in _books)
          b.id == book.id ? b.copyWith(isActive: !b.isActive) : b,
      ];
    });
    AppToast.info(
      context,
      '${book.title} is now ${book.isActive ? 'inactive' : 'active'}.',
    );
  }

  /// Opens the Add Book sheet and puts what comes back at the top of the list.
  ///
  /// No API involved — this shelf is still sample data, so the draft is
  /// turned into a [Book] locally rather than round tripped through
  /// `POST /v1/books` (see [_bookFromDraft]).
  Future<void> _addBook() async {
    final draft = await AddBookForm.show(
      context,
      source: widget.source,
      onSubmit: (draft) async {
        setState(() {
          _books = [_bookFromDraft(draft), ..._books];

          // A book you just added has to be on screen. Left on a Price sort,
          // an Inactive filter or page 3, it would save successfully and
          // appear to have vanished.
          _sort = BookSort.newest;
          _filter = BookFilter.all;
          _resetPage();
        });
      },
    );

    if (draft == null || !mounted) return;

    AppToast.success(
      context,
      '${draft.title} added to ${widget.source.label}.',
    );
  }

  /// The form produces a [BookDraft]; the list shows [Book]s.
  ///
  /// The draft's language, category, binding, discount and cover image have
  /// nowhere to go on this sample [Book] and are dropped.
  Book _bookFromDraft(BookDraft draft) => Book(
    id: 'new-${DateTime.now().microsecondsSinceEpoch}',
    title: draft.title,
    // The card's second line: the subtitle when there is one, the author
    // otherwise — the same fallback [Product.subtitle] makes.
    subtitle: draft.subtitle.isNotEmpty ? draft.subtitle : draft.author,
    // Book keeps money in minor units; the form collects major units.
    price: (draft.price * 100).round(),
    stock: draft.quantity,
    isActive: draft.status == BookStatus.active,
    addedOn: DateTime.now(),
  );

  @override
  Widget build(BuildContext context) {
    final matching = _matching;
    final visible = _visible;

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: InnerPageAppBar(
        title: widget.source.label,
        subtitle: '${matching.length} books',
        onBack: widget.onBack,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: _AddButton(onPressed: _addBook),
          ),
        ],
        searchField: AppSearchField(
          hintText: 'Search books...',
          onChanged: (value) => setState(() {
            _query = value;
            _resetPage();
          }),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const SizedBox(height: AppSpacing.md),

          BookFilterBar(
            selected: _filter,
            onChanged: (filter) => setState(() {
              _filter = filter;
              _resetPage();
            }),
          ),

          const SizedBox(height: AppSpacing.sm),

          BookSortBar(
            selected: _sort,
            onChanged: (sort) => setState(() {
              _sort = sort;
              _resetPage();
            }),
          ),

          const SizedBox(height: AppSpacing.md),

          if (visible.isEmpty)
            const _EmptyState()
          else
            for (final book in visible)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: BookCard(
                  book: book,
                  onToggleActive: () => _toggleActive(book),
                  onEdit: () => AppToast.info(
                    context,
                    'Editing ${book.title} is not built yet.',
                  ),
                ),
              ),

          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xl,
            ),
            child: PaginationBar(
              shown: visible.length,
              total: matching.length,
              page: _page + 1,
              pageCount: _pageCount,
              onPrevious: _page > 0 ? () => setState(() => _page--) : null,
              onNext: _page + 1 < _pageCount
                  ? () => setState(() => _page++)
                  : null,
            ),
          ),
        ],
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

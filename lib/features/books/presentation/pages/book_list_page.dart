import 'package:flutter/material.dart';

import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/core/widgets/widgets.dart';
import 'package:bookslane_app/features/books/domain/entities/book.dart';
import 'package:bookslane_app/features/books/domain/entities/sample_books.dart';
import 'package:bookslane_app/features/books/presentation/widgets/book_card.dart';
import 'package:bookslane_app/features/books/presentation/widgets/book_filter_bar.dart';

/// The list behind both hub buttons — same screen, different [source].
///
/// Search, filter, sort and paging all run in memory over [SampleBooks]. When
/// `/v1/books` exists they become query parameters and this keeps its shape.
class BookListPage extends StatefulWidget {
  const BookListPage({super.key, required this.source, this.onBack});

  final BookSource source;

  /// Returns to the hub. The tab keeps its own history, so the bottom bar
  /// stays put instead of a full-screen route covering it.
  final VoidCallback? onBack;

  @override
  State<BookListPage> createState() => _BookListPageState();
}

class _BookListPageState extends State<BookListPage> {
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

  @override
  Widget build(BuildContext context) {
    final matching = _matching;
    final visible = _visible;

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: InnerPageAppBar(
        title: widget.source.label,
        subtitle: '${matching.length} titles',
        onBack: widget.onBack,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: _AddButton(
              onPressed: () =>
                  AppToast.info(context, 'Adding a book is not built yet.'),
            ),
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

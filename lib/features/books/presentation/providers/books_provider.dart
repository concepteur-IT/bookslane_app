import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:bookslane_app/core/network/api_failure.dart';
import 'package:bookslane_app/features/books/domain/entities/book.dart';
import 'package:bookslane_app/features/books/domain/entities/book_detail.dart';
import 'package:bookslane_app/features/books/domain/entities/book_draft.dart';
import 'package:bookslane_app/features/books/domain/repositories/books_repository.dart';

/// What the list is doing right now.
enum BooksStatus { initial, loading, ready, error }

/// Holds one page of the signed-in account's real books — `My Store`, backed
/// by `/v1/books` — plus the query that produced it. [ProductsProvider] is
/// the same shape for `My Publishings` over `/v1/products`.
class BooksProvider extends ChangeNotifier {
  BooksProvider(this._repository, {this.pageSize = 10});

  final BooksRepository _repository;
  final int pageSize;

  BooksStatus _status = BooksStatus.initial;
  BookPage? _page;
  String? _errorMessage;

  String _search = '';
  BookFilters _filters = BookFilters.initial;
  BookSort _sort = BookSort.initial;
  int _currentPage = 1;

  /// Typing shouldn't fire a request per keystroke.
  Timer? _searchDebounce;

  /// Guards against an older response landing after a newer one.
  int _requestId = 0;

  BooksStatus get status => _status;
  BookPage? get page => _page;

  /// The fetched page's items. Every filter is applied server-side, so
  /// [total] and [totalPages] count exactly what's shown.
  List<Book> get books => _page?.items ?? const [];

  String? get errorMessage => _errorMessage;
  String get search => _search;
  BookFilters get filters => _filters;
  BookSort get sort => _sort;
  int get currentPage => _currentPage;
  int get totalPages => _page?.totalPages ?? 1;
  int get total => _page?.total ?? 0;
  bool get isLoading => _status == BooksStatus.loading;
  bool get hasPrevious => _currentPage > 1;
  bool get hasNext => _page?.hasNext ?? false;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> load() => _fetch();

  Future<void> refresh() => _fetch();

  void setSearch(String value) {
    if (_search == value) return;
    _search = value;

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _currentPage = 1;
      _fetch();
    });
  }

  Future<void> setFilters(BookFilters filters) {
    _filters = filters;
    // Any query change restarts at page one, or you can sit on page 3 of a
    // two-page result and see nothing.
    _currentPage = 1;
    return _fetch();
  }

  Future<void> setSort(BookSort sort) {
    if (_sort == sort) return Future.value();
    _sort = sort;
    _currentPage = 1;
    return _fetch();
  }

  Future<void> nextPage() {
    if (!hasNext) return Future.value();
    _currentPage++;
    return _fetch();
  }

  Future<void> previousPage() {
    if (!hasPrevious) return Future.value();
    _currentPage--;
    return _fetch();
  }

  /// Creates a book and brings it on screen.
  ///
  /// Search, filter and sort reset and the list is refetched from page one —
  /// a local patch could put the new row on screen faster, but only a refetch
  /// guarantees what's shown matches what the server actually persisted
  /// (server-assigned id, stored image path, ...).
  Future<Book> createBook(BookDraft draft) async {
    final book = await _repository.createBook(draft);

    _search = '';
    _filters = BookFilters.initial;
    _sort = BookSort.initial;
    _currentPage = 1;
    await _fetch();

    return book;
  }

  /// Flips a book's active flag and patches it into the current page in
  /// place — see [ProductsProvider.updateQuantity] for the same shape.
  Future<void> toggleActive(Book book) async {
    final updated = await _repository.setActive(
      id: book.id,
      isActive: !book.isActive,
    );
    _patchInPlace(updated);
  }

  /// A book's full detail, for prefilling the Edit Book form. Doesn't touch
  /// [page] — this is a one-off read, not part of the list's own state.
  Future<BookDetail> getBookDetail(String id) => _repository.getBook(id);

  /// Saves an edit and patches the result into the current page in place —
  /// same shape as [toggleActive].
  Future<void> updateBook(String id, BookDraft draft) async {
    final updated = await _repository.updateBook(id, draft);
    _patchInPlace(updated);
  }

  void _patchInPlace(Book updated) {
    final current = _page;
    if (current == null) return;

    _page = BookPage(
      items: [for (final b in current.items) b.id == updated.id ? updated : b],
      page: current.page,
      limit: current.limit,
      total: current.total,
      totalPages: current.totalPages,
      hasNext: current.hasNext,
    );
    notifyListeners();
  }

  Future<void> _fetch() async {
    final requestId = ++_requestId;
    _status = BooksStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final page = await _repository.fetchBooks(
        page: _currentPage,
        limit: pageSize,
        search: _search,
        filters: _filters,
        sort: _sort,
      );

      if (requestId != _requestId) return; // a newer request won
      _page = page;
      _status = BooksStatus.ready;
    } on ApiFailure catch (failure) {
      if (requestId != _requestId) return;
      _errorMessage = failure.message;
      _status = BooksStatus.error;
    } finally {
      if (requestId == _requestId) notifyListeners();
    }
  }
}

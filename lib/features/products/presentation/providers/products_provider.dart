import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:bookslane_app/core/network/api_failure.dart';
import 'package:bookslane_app/features/products/domain/entities/product.dart';
import 'package:bookslane_app/features/products/domain/repositories/products_repository.dart';

/// What the list is doing right now.
enum ProductsStatus { initial, loading, ready, error }

/// Holds one page of the publisher's catalogue, plus the query that produced
/// it.
///
/// Search, filter, sort and paging are all server-side — each change refetches
/// rather than filtering a local list, so the counts always match the API.
class ProductsProvider extends ChangeNotifier {
  ProductsProvider(this._repository, {this.pageSize = 10});

  final ProductsRepository _repository;
  final int pageSize;

  ProductsStatus _status = ProductsStatus.initial;
  ProductPage? _page;
  String? _errorMessage;

  String _search = '';
  ProductFilters _filters = ProductFilters.initial;
  ProductSort _sort = ProductSort.initial;

  /// Options for the category filter; empty until [loadCategories] lands.
  List<ProductCategory> _categories = const [];
  bool _categoriesFailed = false;

  /// The categories call can land after the page is closed.
  bool _disposed = false;
  int _currentPage = 1;

  /// Typing shouldn't fire a request per keystroke.
  Timer? _searchDebounce;

  /// Guards against an older response landing after a newer one.
  int _requestId = 0;

  ProductsStatus get status => _status;
  ProductPage? get page => _page;
  List<Product> get products => _page?.items ?? const [];
  String? get errorMessage => _errorMessage;
  String get search => _search;
  ProductFilters get filters => _filters;
  List<ProductCategory> get categories => _categories;

  /// True when the category list couldn't be fetched — the filter panel says
  /// so rather than showing an empty section.
  bool get categoriesFailed => _categoriesFailed;
  ProductSort get sort => _sort;
  int get currentPage => _currentPage;
  int get totalPages => _page?.totalPages ?? 1;
  int get total => _page?.total ?? 0;
  bool get isLoading => _status == ProductsStatus.loading;
  bool get hasPrevious => _currentPage > 1;
  bool get hasNext => _page?.hasNext ?? false;

  @override
  void dispose() {
    _disposed = true;
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> load() => Future.wait([_fetch(), loadCategories()]);

  /// Fetches the category filter's options. A failure here never blocks the
  /// list; it only leaves the section empty with a note.
  Future<void> loadCategories() async {
    try {
      _categories = await _repository.fetchCategories();
      _categoriesFailed = false;
    } on ApiFailure {
      _categoriesFailed = true;
    }
    if (!_disposed) notifyListeners();
  }

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

  Future<void> setFilters(ProductFilters filters) {
    _filters = filters;
    // Any query change restarts at page one, or you can sit on page 3 of a
    // two-page result and see nothing.
    _currentPage = 1;
    return _fetch();
  }

  Future<void> setSort(ProductSort sort) {
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

  /// Sets a product's stock to [newQuantity] — the **total**, not a delta.
  ///
  /// Rethrows [ApiFailure] so the form can show the message and stay open.
  Future<Product> updateQuantity({
    required int productId,
    required int newQuantity,
  }) async {
    final updated = await _repository.updateQuantity(
      productId: productId,
      quantity: newQuantity,
    );

    // Swap the row in place instead of refetching: the list keeps its scroll
    // position and the new number appears immediately.
    final current = _page;
    if (current != null) {
      _page = ProductPage(
        items: [
          for (final product in current.items)
            product.id == updated.id ? updated : product,
        ],
        page: current.page,
        limit: current.limit,
        total: current.total,
        totalPages: current.totalPages,
        hasNext: current.hasNext,
      );
      notifyListeners();
    }

    return updated;
  }

  Future<void> _fetch() async {
    final requestId = ++_requestId;
    _status = ProductsStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final page = await _repository.fetchProducts(
        page: _currentPage,
        limit: pageSize,
        search: _search,
        filters: _filters,
        sort: _sort,
      );

      if (requestId != _requestId) return; // a newer request won
      _page = page;
      _status = ProductsStatus.ready;
    } on ApiFailure catch (failure) {
      if (requestId != _requestId) return;
      _errorMessage = failure.message;
      _status = ProductsStatus.error;
    } finally {
      if (requestId == _requestId) notifyListeners();
    }
  }
}

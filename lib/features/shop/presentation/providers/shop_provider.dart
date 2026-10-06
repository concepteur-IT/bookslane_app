import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:bookslane_app/core/filters/catalog_filters.dart';
import 'package:bookslane_app/core/network/api_failure.dart';
import 'package:bookslane_app/features/shop/domain/entities/shop_book.dart';
import 'package:bookslane_app/features/shop/domain/repositories/shop_repository.dart';

/// What the list is doing right now.
enum ShopStatus { initial, loading, ready, error }

/// Holds one page of the shop catalogue plus the query that produced it. See
/// `ProductsProvider` for the same shape.
///
/// Search, filters, sort and paging all happen on the server, so the totals
/// and page count are always honest.
class ShopProvider extends ChangeNotifier {
  ShopProvider(this._repository, {this.pageSize = 20});

  /// What the Shop filter panel offers: status, price, stock, category and
  /// language — several categories and languages may be picked.
  ///
  /// It opens with **no filter on**, so the Shop lists exactly what My
  /// Publishings and My Store list together: a default such as "in stock
  /// only" would quietly hide most of an owner's books (and did).
  static const FilterSpec filterSpec = FilterSpec(
    status: true,
    price: true,
    languages: true,
    multiCategory: true,
  );

  final ShopRepository _repository;
  final int pageSize;

  ShopStatus _status = ShopStatus.initial;
  ShopBookPage? _page;
  String? _errorMessage;

  String _search = '';
  CatalogFilters _filters = filterSpec.initial;
  ShopSort _sort = ShopSort.initial;
  int _currentPage = 1;

  /// Typing shouldn't fire a request per keystroke.
  Timer? _searchDebounce;

  /// Guards against an older response landing after a newer one.
  int _requestId = 0;

  ShopStatus get status => _status;
  List<ShopBook> get books => _page?.items ?? const [];
  String? get errorMessage => _errorMessage;
  String get search => _search;
  CatalogFilters get filters => _filters;
  ShopSort get sort => _sort;
  int get currentPage => _currentPage;
  int get totalPages => _page?.totalPages ?? 1;
  int get total => _page?.total ?? 0;
  bool get isLoading => _status == ShopStatus.loading;
  bool get hasPrevious => _currentPage > 1;
  bool get hasNext => _page?.hasNext ?? false;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> load() => _fetch();

  Future<void> refresh() => _fetch();

  /// What the filter panel can offer if the user keeps [draft] — counts per
  /// option, the price range and the total it would leave, for the current
  /// search. Throws [ApiFailure]. The panel calls this on every change.
  Future<FilterFacets> loadFacets(CatalogFilters draft) =>
      _repository.fetchFilters(draft, search: _search);

  void setSearch(String value) {
    if (_search == value) return;
    _search = value;

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _currentPage = 1;
      _fetch();
    });
  }

  Future<void> setFilters(CatalogFilters filters) {
    _filters = filters;
    // Any query change restarts at page one, or you can sit on page 3 of a
    // two-page result and see nothing.
    _currentPage = 1;
    return _fetch();
  }

  Future<void> setSort(ShopSort sort) {
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

  Future<void> _fetch() async {
    final requestId = ++_requestId;
    _status = ShopStatus.loading;
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
      _status = ShopStatus.ready;
    } on ApiFailure catch (failure) {
      if (requestId != _requestId) return;
      _errorMessage = failure.message;
      _status = ShopStatus.error;
    } finally {
      if (requestId == _requestId) notifyListeners();
    }
  }
}

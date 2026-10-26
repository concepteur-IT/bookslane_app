import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:bookslane_app/core/network/api_failure.dart';
import 'package:bookslane_app/features/orders/domain/entities/order_record.dart';
import 'package:bookslane_app/features/orders/domain/repositories/orders_repository.dart';

enum OrdersStatus { initial, loading, ready, error }

/// The Orders tab's list: search, filters, sort and paging all run on the
/// server (`GET /v1/orders`), so totals and page counts are always honest.
class OrdersListProvider extends ChangeNotifier {
  OrdersListProvider(this._repository, {this.pageSize = 20});

  final OrdersRepository _repository;
  final int pageSize;

  OrdersStatus _status = OrdersStatus.initial;
  OrderPage? _page;
  String? _errorMessage;

  String _search = '';
  OrderFilters _filters = OrderFilters.initial;
  OrderSort _sort = OrderSort.initial;
  int _currentPage = 1;

  /// Typing shouldn't fire a request per keystroke.
  Timer? _searchDebounce;

  /// Guards against an older response landing after a newer one.
  int _requestId = 0;

  OrdersStatus get status => _status;
  List<OrderRecord> get orders => _page?.items ?? const [];
  String? get errorMessage => _errorMessage;
  OrderFilters get filters => _filters;
  OrderSort get sort => _sort;
  int get currentPage => _currentPage;
  int get totalPages => _page?.totalPages ?? 1;
  int get total => _page?.total ?? 0;
  bool get isLoading => _status == OrdersStatus.loading;
  bool get hasPrevious => _currentPage > 1;
  bool get hasNext => _page?.hasNext ?? false;

  /// True when a search or filter is narrowing the list — an empty result
  /// then means "nothing matches", not "no orders yet".
  bool get isNarrowed => _search.trim().isNotEmpty || !_filters.isInitial;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> load() => _fetch();

  Future<void> refresh() => _fetch();

  /// What the filter panel can offer if the user keeps [draft], for the
  /// current search. Throws [ApiFailure].
  Future<OrderFacets> loadFacets(OrderFilters draft) =>
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

  Future<void> setFilters(OrderFilters filters) {
    _filters = filters;
    _currentPage = 1;
    return _fetch();
  }

  Future<void> setSort(OrderSort sort) {
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
    _status = OrdersStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final page = await _repository.fetchOrders(
        page: _currentPage,
        limit: pageSize,
        search: _search,
        filters: _filters,
        sort: _sort,
      );

      if (requestId != _requestId) return; // a newer request won
      _page = page;
      _status = OrdersStatus.ready;
    } on ApiFailure catch (failure) {
      if (requestId != _requestId) return;
      _errorMessage = failure.message;
      _status = OrdersStatus.error;
    } finally {
      if (requestId == _requestId) notifyListeners();
    }
  }
}

import 'package:dio/dio.dart';

import 'package:bookslane_app/core/network/api_failure.dart';
import 'package:bookslane_app/features/orders/data/datasources/orders_remote_datasource.dart';
import 'package:bookslane_app/features/orders/domain/entities/order.dart';
import 'package:bookslane_app/features/orders/domain/entities/order_record.dart';
import 'package:bookslane_app/features/orders/domain/repositories/orders_repository.dart';

class OrdersRepositoryImpl implements OrdersRepository {
  const OrdersRepositoryImpl({required this.remoteDataSource});

  final OrdersRemoteDataSource remoteDataSource;

  @override
  Future<String> saveCustomer(CustomerDetails customer) =>
      _guarded(() => remoteDataSource.saveCustomer(customer));

  @override
  Future<PlacedOrder> placeOrder(
    List<OrderItemRequest> items, {
    required String customerId,
    double discount = 0,
  }) => _guarded(
    () => remoteDataSource.placeOrder(
      items,
      customerId: customerId,
      discount: discount,
    ),
  );

  @override
  Future<OrderPage> fetchOrders({
    required int page,
    int limit = 20,
    String? search,
    OrderFilters filters = OrderFilters.initial,
    OrderSort sort = OrderSort.initial,
  }) => _guarded(
    () => remoteDataSource.list(
      page: page,
      limit: limit,
      search: search,
      filters: filters,
      sort: sort,
    ),
  );

  @override
  Future<OrderFacets> fetchFilters(OrderFilters filters, {String? search}) =>
      _guarded(
        () => remoteDataSource.filterFacets(filters: filters, search: search),
      );

  Future<T> _guarded<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (error) {
      throw mapDioException(error);
    } on FormatException {
      throw const ApiFailure(
        'The server sent something unexpected. Please try again.',
      );
    }
  }
}

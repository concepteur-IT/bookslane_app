import 'package:bookslane_app/core/config/api_endpoints.dart';
import 'package:bookslane_app/core/network/api_client.dart';
import 'package:bookslane_app/core/network/json_coerce.dart';
import 'package:bookslane_app/features/orders/data/models/order_models.dart';
import 'package:bookslane_app/features/orders/domain/entities/order.dart';
import 'package:bookslane_app/features/orders/domain/entities/order_record.dart';

/// Talks to `/v1/orders`. Knows about HTTP and JSON only.
class OrdersRemoteDataSource {
  const OrdersRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Future<String> saveCustomer(CustomerDetails customer) async {
    final response = await apiClient.dio.post<dynamic>(
      ApiEndpoints.customers,
      data: customer.toJson(),
    );
    return jsonString(_asJsonObject(response.data)['id']);
  }

  Future<PlacedOrder> placeOrder(
    List<OrderItemRequest> items, {
    required String customerId,
    double discount = 0,
  }) async {
    final response = await apiClient.dio.post<dynamic>(
      ApiEndpoints.orders,
      data: {
        'customer_id': customerId,
        'items': [for (final item in items) item.toJson()],
        // The API takes at most two decimals.
        'discount_amount': double.parse(discount.toStringAsFixed(2)),
      },
    );
    return placedOrderFromJson(_asJsonObject(response.data));
  }

  Future<OrderPage> list({
    required int page,
    required int limit,
    String? search,
    OrderFilters filters = OrderFilters.initial,
    OrderSort sort = OrderSort.initial,
  }) async {
    final response = await apiClient.dio.get<dynamic>(
      ApiEndpoints.orders,
      queryParameters: <String, dynamic>{
        'page': page,
        'limit': limit,
        'sort': sort.value,
        ..._searchQuery(search),
        ...filters.toQuery(),
      },
    );
    return orderPageFromJson(_asJsonObject(response.data));
  }

  Future<OrderFacets> filterFacets({
    required OrderFilters filters,
    String? search,
  }) async {
    final response = await apiClient.dio.get<dynamic>(
      ApiEndpoints.orderFilters,
      queryParameters: <String, dynamic>{
        ..._searchQuery(search),
        ...filters.toQuery(),
      },
    );
    return orderFacetsFromJson(_asJsonObject(response.data));
  }

  /// Omitted rather than sent empty — the API rejects blank values.
  Map<String, dynamic> _searchQuery(String? search) => {
    if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
  };

  Map<String, dynamic> _asJsonObject(Object? body) {
    if (body is! Map<String, dynamic>) {
      throw const FormatException('Expected a JSON object from the API.');
    }
    return body;
  }
}

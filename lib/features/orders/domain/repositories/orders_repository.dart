import 'package:bookslane_app/features/orders/domain/entities/order.dart';
import 'package:bookslane_app/features/orders/domain/entities/order_record.dart';

/// Placing orders, stated without reference to HTTP or JSON.
///
/// Throws [ApiFailure] and nothing else. `errorCode`s to expect:
/// `INSUFFICIENT_STOCK`, `BOOK_UNAVAILABLE`, `BOOK_NOT_FOUND`,
/// `DISCOUNT_INVALID`, `CATALOGUE_UNAVAILABLE`, `CUSTOMER_NOT_FOUND`,
/// `EMAIL_IN_USE`.
abstract interface class OrdersRepository {
  /// Saves the customer and returns their id. The same mobile (or email)
  /// saved before gives the existing customer's id back.
  Future<String> saveCustomer(CustomerDetails customer);

  /// Places the order for [customerId]. [discount] is the flat amount
  /// (rupees) taken off.
  Future<PlacedOrder> placeOrder(
    List<OrderItemRequest> items, {
    required String customerId,
    double discount,
  });

  /// One page of the signed-in account's orders, narrowed and ordered on the
  /// server.
  Future<OrderPage> fetchOrders({
    required int page,
    int limit,
    String? search,
    OrderFilters filters,
    OrderSort sort,
  });

  /// What the filter panel can offer if the user keeps [filters] and the
  /// current [search].
  Future<OrderFacets> fetchFilters(OrderFilters filters, {String? search});
}

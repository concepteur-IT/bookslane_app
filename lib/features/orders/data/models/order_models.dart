import 'package:bookslane_app/core/network/json_coerce.dart';
import 'package:bookslane_app/features/orders/domain/entities/order.dart';
import 'package:bookslane_app/features/orders/domain/entities/order_record.dart';

/// Wire format of app-api's `OrderDto`.
PlacedOrder placedOrderFromJson(Map<String, dynamic> json) => PlacedOrder(
  id: jsonString(json['id']),
  orderNumber: jsonString(json['order_number']),
  subtotal: jsonDouble(json['subtotal']),
  discountAmount: jsonDouble(json['discount_amount']),
  total: jsonDouble(json['total']),
);

DateTime _date(Object? value) =>
    DateTime.tryParse(jsonString(value))?.toLocal() ?? DateTime.now();

OrderLine _lineFromJson(Map<String, dynamic> json) => OrderLine(
  bookId: jsonString(json['book_id']),
  title: jsonString(json['title']).trim(),
  unitPrice: jsonDouble(json['unit_price']),
  quantity: jsonInt(json['quantity']),
  lineTotal: jsonDouble(json['line_total']),
  isStore: switch (json['source']) {
    'store' => true,
    'publishing' => false,
    _ => null,
  },
);

/// Wire format of one row of `GET /v1/orders`.
OrderRecord orderRecordFromJson(Map<String, dynamic> json) {
  final items = json['items'];
  final customer = json['customer'];
  return OrderRecord(
    id: jsonString(json['id']),
    orderNumber: jsonString(json['order_number']),
    status: jsonString(json['status']),
    subtotal: jsonDouble(json['subtotal']),
    discountAmount: jsonDouble(json['discount_amount']),
    total: jsonDouble(json['total']),
    itemCount: jsonInt(json['item_count']),
    placedAt: _date(json['placed_at']),
    paymentMethod: json['payment_method'] as String?,
    customer: customer is Map<String, dynamic>
        ? OrderCustomer(
            name: jsonString(customer['name']).trim(),
            mobile: jsonString(customer['mobile']).trim(),
            email: jsonString(customer['email']).trim(),
            address: jsonString(customer['address']).trim(),
          )
        : null,
    items: [
      if (items is List)
        for (final line in items)
          if (line is Map<String, dynamic>) _lineFromJson(line),
    ],
  );
}

OrderPage orderPageFromJson(Map<String, dynamic> json) {
  final data = json['data'];
  if (data is! List) {
    throw const FormatException('Order list is missing "data".');
  }
  final pagination = json['pagination'] is Map<String, dynamic>
      ? json['pagination'] as Map<String, dynamic>
      : const <String, dynamic>{};

  return OrderPage(
    items: [
      for (final row in data)
        if (row is Map<String, dynamic>) orderRecordFromJson(row),
    ],
    page: jsonInt(pagination['page']),
    limit: jsonInt(pagination['limit']),
    total: jsonInt(pagination['total']),
    totalPages: jsonInt(pagination['total_pages']),
    hasNext: pagination['has_next'] == true,
  );
}

/// Wire format of `GET /v1/orders/filters`.
OrderFacets orderFacetsFromJson(Map<String, dynamic> json) {
  Map<String, dynamic>? object(Object? v) =>
      v is Map<String, dynamic> ? v : null;

  final total = object(json['total_range']);
  final placed = object(json['placed_range']);
  final discount = object(json['discount']);
  final statuses = json['statuses'];

  return OrderFacets(
    total: jsonInt(json['total']),
    statuses: [
      if (statuses is List)
        for (final s in statuses)
          if (s is Map<String, dynamic>)
            (value: jsonString(s['value']), count: jsonInt(s['count'])),
    ],
    totalRange: total == null
        ? null
        : (min: jsonDouble(total['min']), max: jsonDouble(total['max'])),
    withDiscount: jsonInt(discount?['with']),
    withoutDiscount: jsonInt(discount?['without']),
    placedRange: placed == null
        ? null
        : DayRange(start: _date(placed['from']), end: _date(placed['to'])),
  );
}

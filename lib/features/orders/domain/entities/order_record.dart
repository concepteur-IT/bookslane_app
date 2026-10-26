/// One line of an order as it was bought — title and price are the ones at
/// purchase time, not today's catalogue.
class OrderLine {
  const OrderLine({
    required this.bookId,
    required this.title,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
    this.isStore,
  });

  final String bookId;
  final String title;
  final double unitPrice;
  final int quantity;
  final double lineTotal;

  /// True for a My Store book, false for a My Publishings one, null if unknown.
  final bool? isStore;
}

/// Who an order was for, as saved at checkout. Blank fields were not given.
class OrderCustomer {
  const OrderCustomer({
    required this.name,
    this.mobile = '',
    this.email = '',
    this.address = '',
  });

  final String name;
  final String mobile;
  final String email;
  final String address;
}

/// An order in the listing: the header, the money, and every line.
class OrderRecord {
  const OrderRecord({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.subtotal,
    required this.discountAmount,
    required this.total,
    required this.itemCount,
    required this.placedAt,
    required this.items,
    this.paymentMethod,
    this.customer,
  });

  final String id;
  final String orderNumber;

  /// As stored — `placed`, `cancelled`, … Use [statusLabel] to show it.
  final String status;
  final double subtotal;
  final double discountAmount;
  final double total;

  /// Units across all lines.
  final int itemCount;

  /// Local time.
  final DateTime placedAt;
  final List<OrderLine> items;
  final String? paymentMethod;

  /// Null for an order placed before customers were captured.
  final OrderCustomer? customer;

  bool get hasDiscount => discountAmount > 0;

  String get statusLabel => OrderRecord.labelForStatus(status);

  /// "placed" → "Placed". Unknown statuses are shown capitalised rather
  /// than hidden, since the table's status is free text.
  static String labelForStatus(String status) => status.isEmpty
      ? 'Unknown'
      : status[0].toUpperCase() + status.substring(1).replaceAll('_', ' ');

  /// "UPI QR" for `qr`, else the stored word capitalised; null when none.
  String? get paymentLabel => switch (paymentMethod) {
    null || '' => null,
    'qr' => 'QR code',
    final other => labelForStatus(other),
  };
}

class OrderPage {
  const OrderPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNext,
  });

  final List<OrderRecord> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNext;
}

/// Maps onto app-api's `sort` param.
enum OrderSort {
  newest('Newest first', 'newest'),
  oldest('Oldest first', 'oldest'),
  totalHigh('Total: high to low', 'total_high'),
  totalLow('Total: low to high', 'total_low'),
  discountHigh('Biggest discount', 'discount_high');

  const OrderSort(this.label, this.value);

  /// What Clear goes back to.
  static const OrderSort initial = OrderSort.newest;

  final String label;
  final String value;
}

/// What the user has selected in the Orders filter panel. Immutable.
class OrderFilters {
  const OrderFilters({
    this.statuses = const {},
    this.dateRange,
    this.totalRange,
    this.hasDiscount,
  });

  /// Status values (`placed`, …); empty = any.
  final Set<String> statuses;

  /// Inclusive of both days, local time. Null = any date.
  final DayRange? dateRange;

  /// Order total in whole rupees. Null = no limit.
  final ({double min, double max})? totalRange;

  /// True = only orders with a discount, false = only without, null = either.
  final bool? hasDiscount;

  static const OrderFilters initial = OrderFilters();

  /// Filter groups in use — the badge on the filter button.
  int get activeCount =>
      (statuses.isNotEmpty ? 1 : 0) +
      (dateRange != null ? 1 : 0) +
      (totalRange != null ? 1 : 0) +
      (hasDiscount != null ? 1 : 0);

  bool get isInitial => activeCount == 0;

  OrderFilters copyWith({
    Set<String>? statuses,
    DayRange? dateRange,
    bool clearDateRange = false,
    ({double min, double max})? totalRange,
    bool clearTotalRange = false,
    bool? hasDiscount,
    bool clearHasDiscount = false,
  }) => OrderFilters(
    statuses: statuses ?? this.statuses,
    dateRange: clearDateRange ? null : dateRange ?? this.dateRange,
    totalRange: clearTotalRange ? null : totalRange ?? this.totalRange,
    hasDiscount: clearHasDiscount ? null : hasDiscount ?? this.hasDiscount,
  );

  /// The query params the list and `/filters` endpoints share. Anything not
  /// selected is left out — the API rejects empty values.
  ///
  /// Dates go as instants: local midnight of the first day, and local
  /// midnight *after* the last day (exclusive), so "6 Oct – 6 Oct" is the
  /// whole of the 6th in the user's own zone.
  Map<String, dynamic> toQuery() => {
    if (statuses.isNotEmpty) 'status': (statuses.toList()..sort()).join(','),
    if (dateRange != null) ...{
      'placed_from': DateTime(
        dateRange!.start.year,
        dateRange!.start.month,
        dateRange!.start.day,
      ).toUtc().toIso8601String(),
      'placed_before': DateTime(
        dateRange!.end.year,
        dateRange!.end.month,
        dateRange!.end.day + 1,
      ).toUtc().toIso8601String(),
    },
    if (totalRange != null) ...{
      'min_total': totalRange!.min.floor(),
      'max_total': totalRange!.max.ceil(),
    },
    if (hasDiscount != null) 'has_discount': hasDiscount! ? 1 : 0,
  };
}

/// A pair of days. (Flutter's own is in material.dart; the domain layer
/// keeps its own so it needs no widgets.)
class DayRange {
  const DayRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

/// What the filter panel can offer for the current selection.
class OrderFacets {
  const OrderFacets({
    required this.total,
    this.statuses = const [],
    this.totalRange,
    this.withDiscount = 0,
    this.withoutDiscount = 0,
    this.placedRange,
  });

  final int total;
  final List<({String value, int count})> statuses;
  final ({double min, double max})? totalRange;
  final int withDiscount;
  final int withoutDiscount;

  /// Earliest and latest order, local time.
  final DayRange? placedRange;
}

import 'package:bookslane_app/core/network/api_failure.dart';

/// The Home tab's figures, from `GET /v1/dashboard/summary`.
class DashboardSummary {
  const DashboardSummary({
    required this.name,
    required this.greeting,
    required this.ordersToday,
    required this.revenueToday,
    required this.totalProducts,
  });

  final String name;

  /// "Good morning" … chosen by the server from the time in IST, so it is
  /// right whatever zone the phone is set to.
  final String greeting;
  final int ordersToday;

  /// Rupees.
  final double revenueToday;
  final int totalProducts;
}

/// Throws [ApiFailure] and nothing else.
abstract interface class DashboardRepository {
  Future<DashboardSummary> fetchSummary();
}

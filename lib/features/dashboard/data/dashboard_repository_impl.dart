import 'package:dio/dio.dart';

import 'package:bookslane_app/core/config/api_endpoints.dart';
import 'package:bookslane_app/core/network/api_client.dart';
import 'package:bookslane_app/core/network/api_failure.dart';
import 'package:bookslane_app/core/network/json_coerce.dart';
import 'package:bookslane_app/features/dashboard/domain/dashboard_summary.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  const DashboardRepositoryImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<DashboardSummary> fetchSummary() async {
    try {
      final response = await apiClient.dio.get<dynamic>(
        ApiEndpoints.dashboardSummary,
      );
      final json = response.data;
      if (json is! Map<String, dynamic>) throw const FormatException();

      return DashboardSummary(
        name: jsonString(json['name']).trim(),
        greeting: jsonString(json['greeting']).trim(),
        ordersToday: jsonInt(json['orders_today']),
        revenueToday: jsonDouble(json['revenue_today']),
        totalProducts: jsonInt(json['total_products']),
      );
    } on DioException catch (error) {
      throw mapDioException(error);
    } on FormatException {
      throw const ApiFailure(
        'The server sent something unexpected. Please try again.',
      );
    }
  }
}

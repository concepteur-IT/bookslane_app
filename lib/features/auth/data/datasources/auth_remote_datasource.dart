import 'package:bookslane_app/core/config/config.dart';
import 'package:bookslane_app/core/network/api_client.dart';
import 'package:bookslane_app/features/auth/data/models/login_request.dart';
import 'package:bookslane_app/features/auth/data/models/login_response.dart';

/// Talks to `/v1/auth/*`. Knows about HTTP and JSON, and nothing else.
class AuthRemoteDataSource {
  const AuthRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Future<LoginResponse> login(LoginRequest request) async {
    final response = await apiClient.dio.post<dynamic>(
      ApiEndpoints.login,
      data: request.toJson(),
    );

    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw const FormatException('Login response was not a JSON object.');
    }

    return LoginResponse.fromJson(body);
  }
}

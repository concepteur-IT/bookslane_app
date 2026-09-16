import 'package:bookslane_app/core/config/config.dart';
import 'package:bookslane_app/core/network/api_client.dart';
import 'package:bookslane_app/features/auth/data/models/login_request.dart';
import 'package:bookslane_app/features/auth/data/models/login_response.dart';
import 'package:bookslane_app/features/auth/data/models/user_model.dart';

/// Talks to `/v1/auth/*`. Knows about HTTP and JSON, and nothing else.
class AuthRemoteDataSource {
  const AuthRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Future<LoginResponse> login(LoginRequest request) async {
    final response = await apiClient.dio.post<dynamic>(
      ApiEndpoints.login,
      data: request.toJson(),
    );

    return LoginResponse.fromJson(_asJsonObject(response.data));
  }

  /// The user behind the current access token. 401 here means the session is
  /// gone for good — `AuthInterceptor` will already have tried a refresh.
  Future<UserModel> me() async {
    final response = await apiClient.dio.get<dynamic>(ApiEndpoints.me);

    return UserModel.fromJson(_asJsonObject(response.data));
  }

  /// Server-side sign-out. Returns 204 with no body.
  Future<void> logout() async {
    await apiClient.dio.post<dynamic>(ApiEndpoints.logout);
  }

  Map<String, dynamic> _asJsonObject(Object? body) {
    if (body is! Map<String, dynamic>) {
      throw const FormatException('Expected a JSON object from the API.');
    }
    return body;
  }
}

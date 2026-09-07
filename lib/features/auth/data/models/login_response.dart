import 'package:bookslane_app/features/auth/data/models/user_model.dart';

/// app-api's `LoginResponseDto`, returned by both `/v1/auth/login` and
/// `/v1/auth/refresh`:
///
/// ```json
/// {
///   "access_token": "...",
///   "refresh_token": "...",
///   "token_type": "Bearer",
///   "expires_in": 900,
///   "user": { "id": "...", "email": "..." }
/// }
/// ```
///
/// Note the fields are snake_case and the object is flat — there is no `data`
/// envelope around it.
class LoginResponse {
  const LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    this.tokenType = 'Bearer',
    this.expiresIn,
  });

  final String accessToken;
  final String refreshToken;
  final UserModel user;
  final String tokenType;

  /// Access-token lifetime in seconds. Useful later for refreshing early
  /// rather than waiting for a 401.
  final int? expiresIn;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    if (user is! Map<String, dynamic>) {
      throw const FormatException('Login response is missing "user".');
    }

    return LoginResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      tokenType: json['token_type'] as String? ?? 'Bearer',
      expiresIn: json['expires_in'] as int?,
      user: UserModel.fromJson(user),
    );
  }
}

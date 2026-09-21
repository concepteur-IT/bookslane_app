/// Paths for the mobile API (`bookslane-api/apps/app-api`).
///
/// Relative to [AppConfig.apiRoot], which already carries the origin and the
/// `/v1` version segment — so these must not repeat either:
///
/// ```dart
/// final uri = Uri.parse('${AppConfig.current.apiRoot}${ApiEndpoints.login}');
/// // http://localhost:3002/v1/auth/login
/// ```
abstract final class ApiEndpoints {
  // ---------------------------------------------------------------------------
  // Auth — app-api/src/auth/auth.controller.ts
  // The API issues bearer tokens (no cookies), so every authenticated request
  // needs an `Authorization: Bearer <accessToken>` header.
  // ---------------------------------------------------------------------------
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  // ---------------------------------------------------------------------------
  // Books — app-api/src/books/books.controller.ts
  // ---------------------------------------------------------------------------
  static const String books = '/books';
  static String book(String id) => '/books/$id';
}

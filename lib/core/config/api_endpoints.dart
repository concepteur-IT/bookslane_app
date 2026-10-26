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

  /// What the My Store filter panel can offer for a selection — takes the
  /// list's filter params.
  static const String bookFilters = '/books/filters';

  // ---------------------------------------------------------------------------
  // Categories — app-api/src/categories/categories.controller.ts
  // Every category a book can be filed under; shared by both shelves.
  // ---------------------------------------------------------------------------
  static const String categories = '/categories';

  // ---------------------------------------------------------------------------
  // Shop — app-api/src/shop/shop.controller.ts
  // thinkerslane's public catalogue; the filters endpoint takes the list's
  // filter params and returns what the panel can offer.
  // ---------------------------------------------------------------------------
  static const String shopBooks = '/shop/books';
  static const String shopFilters = '/shop/filters';

  // ---------------------------------------------------------------------------
  // Orders — app-api/src/orders/orders.controller.ts
  // POST places an order (book ids, quantities, a flat discount; the server
  // prices every line and takes publishing stock off thinkerslane). GET lists
  // the caller's orders.
  // ---------------------------------------------------------------------------
  static const String orders = '/orders';

  /// Saves the customer an order is for (users, role 7); returns their id.
  static const String customers = '/customers';

  /// What the Orders filter panel can offer for a selection — takes the
  /// list's filter params.
  static const String orderFilters = '/orders/filters';

  // ---------------------------------------------------------------------------
  // Profile — app-api/src/profile/profile.controller.ts
  // The signed-in owner's own `users` row (no password).
  // ---------------------------------------------------------------------------
  static const String profile = '/profile';

  // ---------------------------------------------------------------------------
  // Dashboard — app-api/src/dashboard/dashboard.controller.ts
  // The Home tab: name, an IST greeting, today's orders and revenue, products.
  // ---------------------------------------------------------------------------
  static const String dashboardSummary = '/dashboard/summary';
}

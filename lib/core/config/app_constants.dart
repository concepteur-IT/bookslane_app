/// Non-visual constants that aren't environment specific.
///
/// Anything that changes per environment belongs in `AppConfig`; anything
/// visual belongs in `core/theme`.
abstract final class AppConstants {
  static const String appName = 'Bookslane';

  // ---------------------------------------------------------------------------
  // Secure storage / preferences keys
  // Constants, never string literals at the call site — a typo'd key fails
  // silently at runtime.
  // ---------------------------------------------------------------------------
  static const String accessTokenKey = 'auth.access_token';
  static const String refreshTokenKey = 'auth.refresh_token';
  static const String onboardingSeenKey = 'app.onboarding_seen';

  // ---------------------------------------------------------------------------
  // Networking behaviour
  // ---------------------------------------------------------------------------
  static const String authorizationHeader = 'Authorization';
  static const String bearerPrefix = 'Bearer ';
  static const int maxRetries = 2;

  // ---------------------------------------------------------------------------
  // Lists
  // ---------------------------------------------------------------------------
  static const int defaultPageSize = 20;

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------
  static const int minPasswordLength = 8;
  static final RegExp emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
}

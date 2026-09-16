import 'package:bookslane_app/features/auth/domain/entities/user.dart';

/// What the app can do with authentication, stated without reference to HTTP,
/// JSON or storage — those are the data layer's business.
///
/// The presentation layer depends on this, never on the implementation, so a
/// screen can be tested against a fake in a few lines.
///
/// Every method throws [AuthFailure] and nothing else: callers show
/// `failure.message` and never inspect status codes.
abstract interface class AuthRepository {
  /// Signs in and persists the session.
  ///
  /// Returns the signed-in [User]. The token pair is stored on the way through
  /// rather than returned: nothing above this layer should be handling tokens.
  Future<User> login({required String email, required String password});

  /// Ends the session.
  ///
  /// Tells the API first, then clears the local tokens — and clears them even
  /// if the API call fails, so a user can always get out.
  Future<void> logout();

  /// The user for the stored token, or `null` when there is no usable session.
  ///
  /// Called once at startup to decide which screen to open. An expired access
  /// token is refreshed transparently by `AuthInterceptor`; only when that
  /// fails too does this return `null`.
  Future<User?> restoreSession();
}

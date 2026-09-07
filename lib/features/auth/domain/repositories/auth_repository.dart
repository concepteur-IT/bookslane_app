import 'package:bookslane_app/features/auth/domain/entities/user.dart';

/// What the app can do with authentication, stated without reference to HTTP,
/// JSON or storage — those are the data layer's business.
///
/// The presentation layer depends on this, never on the implementation, so a
/// screen can be tested against a fake in a few lines.
abstract interface class AuthRepository {
  /// Signs in and persists the session.
  ///
  /// Returns the signed-in [User]. The token pair is stored on the way through
  /// rather than returned: nothing above this layer should be handling tokens.
  ///
  /// Throws a [DioException] on a network or credential failure — a 401 here
  /// means "wrong email or password".
  Future<User> login({required String email, required String password});
}

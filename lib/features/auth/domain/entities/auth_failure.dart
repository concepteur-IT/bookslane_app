/// A sign-in problem, already phrased for a human.
///
/// The data layer catches `DioException` and throws one of these instead, so
/// no widget ever has to know what a status code is — it just shows
/// [message].
class AuthFailure implements Exception {
  const AuthFailure(this.message, {this.kind = AuthFailureKind.unknown});

  /// Safe to put in front of the user.
  final String message;

  final AuthFailureKind kind;

  @override
  String toString() => 'AuthFailure(${kind.name}): $message';
}

enum AuthFailureKind {
  /// Wrong email or password — a 401 from `/auth/login`.
  invalidCredentials,

  /// The server could not be reached, or took too long.
  network,

  /// The server answered, but not with something we can use.
  server,

  unknown,
}

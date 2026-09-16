import 'package:flutter/foundation.dart';

import 'package:bookslane_app/features/auth/domain/entities/auth_failure.dart';
import 'package:bookslane_app/features/auth/domain/entities/user.dart';
import 'package:bookslane_app/features/auth/domain/repositories/auth_repository.dart';

/// Whether anyone is signed in.
enum AuthStatus {
  /// Startup: the stored token has not been checked yet. The splash screen
  /// stays up while this is the case.
  unknown,

  authenticated,
  unauthenticated,
}

/// The single source of truth for "is someone signed in, and who".
///
/// Widgets never call the repository directly — they read this, and the whole
/// app reacts to one status change. That is what makes the redirects work in
/// both directions without any screen pushing routes at another screen.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repository);

  final AuthRepository _repository;

  AuthStatus _status = AuthStatus.unknown;
  User? _user;
  bool _isSubmitting = false;

  AuthStatus get status => _status;

  /// The signed-in user, or null when [status] is not
  /// [AuthStatus.authenticated].
  User? get user => _user;

  /// True while a sign-in or sign-out request is in flight — the button shows
  /// a spinner and ignores taps.
  bool get isSubmitting => _isSubmitting;

  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Decides the opening screen. Called once, from `main`.
  ///
  /// Never throws: a failure at startup simply means "not signed in", because
  /// there is no screen yet on which to show an error.
  Future<void> bootstrap() async {
    try {
      final user = await _repository.restoreSession();
      _setSession(user);
    } on AuthFailure {
      // Offline, or the server is down. Sign-in will report it properly.
      _setSession(null);
    }
  }

  /// Signs in.
  ///
  /// Throws [AuthFailure] with a message for the user; the caller catches it
  /// and shows a toast. On success [status] flips and the gate swaps screens —
  /// the caller does not navigate.
  Future<void> login({
    required String email,
    required String password,
  }) async {
    if (_isSubmitting) return; // guards a double tap
    _setSubmitting(true);

    try {
      final user = await _repository.login(email: email, password: password);
      _setSession(user);
    } finally {
      // finally, not a success-only path: the button must come back even when
      // the credentials were wrong.
      _setSubmitting(false);
    }
  }

  /// Signs out. Always ends unauthenticated, even if the API call fails.
  Future<void> logout() async {
    if (_isSubmitting) return;
    _setSubmitting(true);

    try {
      await _repository.logout();
    } finally {
      _setSession(null);
      _setSubmitting(false);
    }
  }

  /// Called by the network layer when a token refresh fails mid-session.
  void onSessionExpired() {
    if (_status == AuthStatus.unauthenticated) return;
    _setSession(null);
  }

  void _setSession(User? user) {
    _user = user;
    _status = user == null
        ? AuthStatus.unauthenticated
        : AuthStatus.authenticated;
    notifyListeners();
  }

  void _setSubmitting(bool value) {
    if (_isSubmitting == value) return;
    _isSubmitting = value;
    notifyListeners();
  }
}

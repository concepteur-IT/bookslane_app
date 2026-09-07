import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:bookslane_app/core/config/config.dart';

/// Where the auth tokens live.
///
/// An interface rather than a concrete class so tests (and any future backend
/// like an in-memory store for widget previews) can stand in for the real
/// keychain without touching platform channels.
abstract interface class TokenStorage {
  Future<String?> readAccessToken();

  Future<String?> readRefreshToken();

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });

  /// Called on sign-out and whenever a refresh fails.
  Future<void> clear();
}

/// Tokens in the platform's secure store: Keychain on iOS/macOS,
/// EncryptedSharedPreferences on Android.
///
/// Never `shared_preferences` — a refresh token in plaintext is readable on a
/// rooted or jailbroken device, and it is a long-lived credential.
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readAccessToken() =>
      _storage.read(key: AppConstants.accessTokenKey);

  @override
  Future<String?> readRefreshToken() =>
      _storage.read(key: AppConstants.refreshTokenKey);

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(
      key: AppConstants.accessTokenKey,
      value: accessToken,
    );
    await _storage.write(
      key: AppConstants.refreshTokenKey,
      value: refreshToken,
    );
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: AppConstants.accessTokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
  }
}

import 'package:flutter/foundation.dart';

import 'app_environment.dart';

/// Global runtime configuration — one resolved instance per build.
///
/// ```dart
/// final url = '${AppConfig.current.apiRoot}${ApiEndpoints.login}';
/// ```
///
/// **Never put secrets here.** Anything compiled into the app ships to every
/// device and can be read out of the binary. API keys and client secrets belong
/// on the server; the app only ever holds the tokens the login call returns.
@immutable
class AppConfig {
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.apiVersion,
    required this.connectTimeout,
    required this.receiveTimeout,
    required this.enableLogging,
  });

  final AppEnvironment environment;

  /// Origin only — no version, no trailing slash. e.g. `https://api.example.com`
  final String apiBaseUrl;

  /// app-api uses URI versioning, so every route is prefixed with this.
  final String apiVersion;

  final Duration connectTimeout;
  final Duration receiveTimeout;

  /// Verbose network/log output. Off in production.
  final bool enableLogging;

  /// The configuration this build runs on.
  static final AppConfig current = _resolve();

  /// Base for every request: `<origin>/<version>`.
  String get apiRoot => '$apiBaseUrl/$apiVersion';

  bool get isProduction => environment.isProduction;

  // ---------------------------------------------------------------------------
  // Resolution
  // ---------------------------------------------------------------------------

  /// Escape hatch for pointing a build at any host without editing code:
  /// `--dart-define=API_BASE_URL=https://pr-42.api.bookslane.dev`
  static const String _baseUrlOverride = String.fromEnvironment('API_BASE_URL');

  static AppConfig _resolve() {
    final env = AppEnvironment.current;

    final config = switch (env) {
      AppEnvironment.dev => AppConfig(
        environment: env,
        apiBaseUrl: _localApiBaseUrl,
        apiVersion: 'v1',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        enableLogging: true,
      ),
      // TODO: replace with the real hosts once they exist. Until then pass
      // --dart-define=API_BASE_URL=... to point a build somewhere real.
      AppEnvironment.staging => AppConfig(
        environment: env,
        apiBaseUrl: 'https://staging-api.bookslane.com',
        apiVersion: 'v1',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        enableLogging: true,
      ),
      AppEnvironment.production => AppConfig(
        environment: env,
        apiBaseUrl: 'https://api.bookslane.com',
        apiVersion: 'v1',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
        enableLogging: false,
      ),
    };

    return _baseUrlOverride.isEmpty
        ? config
        : config.copyWith(apiBaseUrl: _baseUrlOverride);
  }

  /// app-api listens on :3002 (APP_API_PORT). An Android emulator reaches the
  /// host machine through 10.0.2.2 — `localhost` there is the emulator itself.
  static String get _localApiBaseUrl {
    const port = 3002;
    final isAndroidEmulator =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    return isAndroidEmulator
        ? 'http://10.0.2.2:$port'
        : 'http://localhost:$port';
  }

  AppConfig copyWith({
    AppEnvironment? environment,
    String? apiBaseUrl,
    String? apiVersion,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    bool? enableLogging,
  }) {
    return AppConfig(
      environment: environment ?? this.environment,
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      apiVersion: apiVersion ?? this.apiVersion,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      enableLogging: enableLogging ?? this.enableLogging,
    );
  }

  @override
  String toString() => 'AppConfig(${environment.name}, $apiRoot)';
}

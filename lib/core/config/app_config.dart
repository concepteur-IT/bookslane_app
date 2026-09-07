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
  ///
  /// Wins over everything else, in any environment.
  static const String _baseUrlOverride = String.fromEnvironment('API_BASE_URL');

  /// Dev-only host override — just the host, no scheme or port:
  /// `--dart-define=DEV_HOST=192.168.1.4`
  ///
  /// This is what makes a physical device work. The app cannot discover your
  /// machine's address by itself (it runs on the phone, not on your Mac), so
  /// the address is baked in at build time. `scripts/run_dev.sh` fills it in
  /// automatically from the Mac's current Wi-Fi address.
  static const String _devHostOverride = String.fromEnvironment('DEV_HOST');

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

  /// Port app-api is served on locally — `APP_API_PORT` in bookslane-api,
  /// which defaults to 3002. (3001 is web-api, the admin panel's `/admin/*`.)
  static const int _devPort = 3002;

  /// Host for a locally running API, per platform.
  ///
  /// | Where the app runs        | Host reaching your Mac |
  /// |---------------------------|------------------------|
  /// | Android emulator          | `10.0.2.2`             |
  /// | iOS simulator, desktop, web | `localhost`          |
  /// | Physical phone (same Wi-Fi) | your LAN IP          |
  ///
  /// An Android emulator is a separate virtual machine: `localhost` there is
  /// the emulator itself, and 10.0.2.2 is its alias for the host's loopback.
  /// The iOS simulator shares the Mac's network stack, so `localhost` works.
  ///
  /// A real device shares neither, so its address has to be supplied — see
  /// [_devHostOverride] and `scripts/run_dev.sh`, which fills it in for you.
  static String get _localApiBaseUrl => 'http://$_devHost:$_devPort';

  static String get _devHost {
    if (_devHostOverride.isNotEmpty) return _devHostOverride;

    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    return isAndroid ? '10.0.2.2' : 'localhost';
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

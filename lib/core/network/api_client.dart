import 'package:dio/dio.dart';

import 'package:bookslane_app/core/config/config.dart';
import 'package:bookslane_app/core/network/auth_interceptor.dart';
import 'package:bookslane_app/core/storage/token_storage.dart';

/// The app's HTTP client — a [Dio] instance configured from [AppConfig].
///
/// Nothing else in the app should construct a [Dio]: base URL, timeouts,
/// logging and the bearer-token handling all follow the environment the build
/// was compiled for.
///
/// ```dart
/// final api = ApiClient(onSessionExpired: () => router.goToLogin());
/// final response = await api.dio.post(ApiEndpoints.login, data: {...});
/// await api.storage.saveTokens(accessToken: ..., refreshToken: ...);
/// ```
///
/// Build it once and share it — every instance creates its own [Dio] and its
/// own connection pool.
class ApiClient {
  /// Builds a client for the current build's configuration.
  ///
  /// [storage] and [config] exist so tests can inject fakes; app code passes
  /// neither.
  ApiClient({
    AppConfig? config,
    TokenStorage? storage,
    void Function()? onSessionExpired,
  }) : this._(
         config ?? AppConfig.current,
         storage ?? SecureTokenStorage(),
         onSessionExpired,
       );

  ApiClient._(this.config, this.storage, this.onSessionExpired)
    : dio = Dio(
        BaseOptions(
          // apiRoot, not apiBaseUrl: it carries the /v1 version segment the
          // API requires, so endpoints must not repeat it.
          baseUrl: config.apiRoot,
          connectTimeout: config.connectTimeout,
          receiveTimeout: config.receiveTimeout,
          contentType: Headers.jsonContentType,
          responseType: ResponseType.json,
          headers: const {'Accept': Headers.jsonContentType},
        ),
      ) {
    // Order is execution order: authenticate first, so the log below shows the
    // request as it actually goes out.
    dio.interceptors.add(
      AuthInterceptor(
        client: dio,
        storage: storage,
        config: config,
        onSessionExpired: onSessionExpired,
      ),
    );

    if (config.enableLogging) {
      dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }
  }

  final AppConfig config;
  final Dio dio;

  /// Where the tokens live — the sign-in flow writes them here after a
  /// successful login, and sign-out clears them.
  final TokenStorage storage;

  /// Fires when a refresh fails and the user has to sign in again.
  final void Function()? onSessionExpired;
}

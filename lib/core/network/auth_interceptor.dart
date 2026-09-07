import 'package:dio/dio.dart';

import 'package:bookslane_app/core/config/config.dart';
import 'package:bookslane_app/core/storage/token_storage.dart';

/// Attaches the bearer token to every request, and transparently refreshes it
/// when the API answers 401.
///
/// The flow, matching `app-api`'s `/v1/auth/*` contract:
///
/// 1. `onRequest` adds `Authorization: Bearer <access_token>`, except on the
///    login and refresh calls which have no token yet.
/// 2. On a 401, `onError` posts the refresh token to [ApiEndpoints.refresh],
///    stores the new pair and replays the original request — so the caller
///    never sees the failure.
/// 3. If the refresh itself fails, tokens are cleared and [onSessionExpired]
///    fires so the app can route back to sign-in.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.client,
    required this.storage,
    required AppConfig config,
    this.onSessionExpired,
    Dio? refreshClient,
  }) : // A SEPARATE client for the refresh call. Sending it through [client]
       // would run it back through this interceptor, and a failing refresh
       // would then try to refresh itself, forever.
       _refreshClient =
           refreshClient ??
           Dio(
             BaseOptions(
               baseUrl: config.apiRoot,
               connectTimeout: config.connectTimeout,
               receiveTimeout: config.receiveTimeout,
               contentType: Headers.jsonContentType,
             ),
           );

  /// The client this interceptor is installed on — used to replay a request
  /// after a refresh, so the new token gets attached on the way back through.
  final Dio client;
  final Dio _refreshClient;
  final TokenStorage storage;

  /// Fires when the session can no longer be recovered — route to sign-in.
  final void Function()? onSessionExpired;

  /// The refresh in flight, if any.
  ///
  /// Five requests failing at once must trigger one refresh, not five: the
  /// API rotates the refresh token, so the last four would fail and log the
  /// user out. Everyone awaits this same future instead.
  Future<bool>? _refreshing;

  /// Marks a request that has already been retried once, so an endlessly
  /// rejecting token can't loop.
  static const String _retriedFlag = 'auth_retried';

  bool _isAuthCall(String path) =>
      path == ApiEndpoints.login || path == ApiEndpoints.refresh;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isAuthCall(options.path)) {
      final token = await storage.readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers[AppConstants.authorizationHeader] =
            '${AppConstants.bearerPrefix}$token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    final bool isUnauthorized = err.response?.statusCode == 401;
    final bool alreadyRetried = request.extra[_retriedFlag] == true;

    // Anything that isn't a recoverable 401 passes straight through. A 401 on
    // login means "wrong password" — that belongs to the caller, not here.
    if (!isUnauthorized || alreadyRetried || _isAuthCall(request.path)) {
      return handler.next(err);
    }

    final bool refreshed = await _refreshTokens();

    if (!refreshed) {
      await storage.clear();
      onSessionExpired?.call();
      return handler.next(err);
    }

    try {
      request.extra[_retriedFlag] = true;
      // Back through [_client], so onRequest attaches the *new* token.
      handler.resolve(await client.fetch<dynamic>(request));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  /// Runs a refresh, or joins the one already running.
  Future<bool> _refreshTokens() {
    return _refreshing ??= _performRefresh().whenComplete(() {
      _refreshing = null;
    });
  }

  Future<bool> _performRefresh() async {
    final refreshToken = await storage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final response = await _refreshClient.post<dynamic>(
        ApiEndpoints.refresh,
        data: {'refresh_token': refreshToken},
      );

      final data = response.data;
      if (data is! Map) return false;

      // snake_case: the API's LoginResponseDto shape.
      final access = data['access_token'];
      final refresh = data['refresh_token'];
      if (access is! String || refresh is! String) return false;

      await storage.saveTokens(accessToken: access, refreshToken: refresh);
      return true;
    } on DioException {
      // Expired or rotated-away refresh token — the session is over.
      return false;
    }
  }
}

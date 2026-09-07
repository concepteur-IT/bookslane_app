import 'dart:convert';
import 'dart:typed_data';

import 'package:bookslane_app/core/config/config.dart';
import 'package:bookslane_app/core/network/api_client.dart';
import 'package:bookslane_app/core/network/auth_interceptor.dart';
import 'package:bookslane_app/core/storage/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tokens in a map — no platform channels, so this runs in a plain unit test.
class FakeTokenStorage implements TokenStorage {
  FakeTokenStorage({this.access, this.refresh});

  String? access;
  String? refresh;
  int clearCount = 0;

  @override
  Future<String?> readAccessToken() async => access;

  @override
  Future<String?> readRefreshToken() async => refresh;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    access = accessToken;
    refresh = refreshToken;
  }

  @override
  Future<void> clear() async {
    access = null;
    refresh = null;
    clearCount++;
  }
}

/// Stands in for the network. Records every request and answers from a script.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.respond);

  final ResponseBody Function(RequestOptions options) respond;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody json(Map<String, dynamic> body, int status) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

void main() {
  final config = AppConfig.current.copyWith(enableLogging: false);

  /// A Dio wired exactly like ApiClient's, but talking to [adapter] instead of
  /// the network. The refresh client shares the adapter so both calls are
  /// scripted from one place.
  Dio clientWith(
    FakeAdapter adapter,
    TokenStorage storage, {
    void Function()? onSessionExpired,
  }) {
    final dio = Dio(BaseOptions(baseUrl: config.apiRoot))
      ..httpClientAdapter = adapter;
    final refreshDio = Dio(BaseOptions(baseUrl: config.apiRoot))
      ..httpClientAdapter = adapter;

    dio.interceptors.add(
      AuthInterceptor(
        client: dio,
        storage: storage,
        config: config,
        refreshClient: refreshDio,
        onSessionExpired: onSessionExpired,
      ),
    );
    return dio;
  }

  test('attaches the bearer token, but not to the login call', () async {
    final storage = FakeTokenStorage(access: 'token-1', refresh: 'r-1');
    final adapter = FakeAdapter((_) => json({'ok': true}, 200));

    final api = ApiClient(config: config, storage: storage);
    api.dio.httpClientAdapter = adapter;

    await api.dio.get<dynamic>(ApiEndpoints.me);
    await api.dio.post<dynamic>(ApiEndpoints.login, data: {'email': 'a@b.c'});

    expect(
      adapter.requests[0].headers[AppConstants.authorizationHeader],
      'Bearer token-1',
    );
    expect(
      adapter.requests[1].headers.containsKey(AppConstants.authorizationHeader),
      isFalse,
    );
  });

  test('401 refreshes the token and replays the request', () async {
    final storage = FakeTokenStorage(access: 'stale', refresh: 'r-1');
    var refreshCalls = 0;

    final adapter = FakeAdapter((options) {
      if (options.path == ApiEndpoints.refresh) {
        refreshCalls++;
        return json({
          'access_token': 'fresh',
          'refresh_token': 'r-2',
          'token_type': 'Bearer',
          'expires_in': 900,
        }, 200);
      }
      // /me only accepts the refreshed token.
      final auth = options.headers[AppConstants.authorizationHeader];
      return auth == 'Bearer fresh'
          ? json({'id': 'u1', 'email': 'anna@bookslane.com'}, 200)
          : json({'message': 'Unauthorized'}, 401);
    });

    final dio = clientWith(adapter, storage);

    final response = await dio.get<dynamic>(ApiEndpoints.me);

    expect(response.statusCode, 200);
    expect(response.data['email'], 'anna@bookslane.com');
    expect(refreshCalls, 1);
    expect(storage.access, 'fresh'); // new pair persisted
    expect(storage.refresh, 'r-2');
  });

  test('a failed refresh clears tokens and reports the expired session',
      () async {
    final storage = FakeTokenStorage(access: 'stale', refresh: 'dead');
    var expired = false;

    final adapter = FakeAdapter((options) {
      return options.path == ApiEndpoints.refresh
          ? json({'message': 'Invalid refresh token'}, 401)
          : json({'message': 'Unauthorized'}, 401);
    });

    final dio = clientWith(
      adapter,
      storage,
      onSessionExpired: () => expired = true,
    );

    await expectLater(
      dio.get<dynamic>(ApiEndpoints.me),
      throwsA(isA<DioException>()),
    );

    expect(expired, isTrue);
    expect(storage.clearCount, 1);
    expect(storage.access, isNull);
  });

  test('concurrent 401s trigger exactly one refresh', () async {
    final storage = FakeTokenStorage(access: 'stale', refresh: 'r-1');
    var refreshCalls = 0;

    final adapter = FakeAdapter((options) {
      if (options.path == ApiEndpoints.refresh) {
        refreshCalls++;
        return json({
          'access_token': 'fresh',
          'refresh_token': 'r-2',
        }, 200);
      }
      final auth = options.headers[AppConstants.authorizationHeader];
      return auth == 'Bearer fresh'
          ? json({'ok': true}, 200)
          : json({'message': 'Unauthorized'}, 401);
    });

    final dio = clientWith(adapter, storage);

    final responses = await Future.wait([
      dio.get<dynamic>(ApiEndpoints.me),
      dio.get<dynamic>('/books'),
      dio.get<dynamic>('/orders'),
    ]);

    expect(responses.every((r) => r.statusCode == 200), isTrue);
    expect(refreshCalls, 1, reason: 'parallel 401s must share one refresh');
  });
}

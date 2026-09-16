import 'dart:convert';
import 'dart:typed_data';

import 'package:bookslane_app/core/config/config.dart';
import 'package:bookslane_app/core/network/api_client.dart';
import 'package:bookslane_app/core/storage/token_storage.dart';
import 'package:bookslane_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:bookslane_app/features/auth/data/models/login_response.dart';
import 'package:bookslane_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bookslane_app/features/auth/domain/entities/auth_failure.dart';
import 'package:bookslane_app/features/auth/domain/entities/user.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeTokenStorage implements TokenStorage {
  String? access;
  String? refresh;

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
  }
}

class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.body, {this.status = 200});

  final Map<String, dynamic> body;
  final int status;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// The exact payload apps/app-api returns (LoginResponseDto).
Map<String, dynamic> loginPayload({Object id = 'c7f1-8a2b-uuid'}) => {
  'access_token': 'access-1',
  'refresh_token': 'refresh-1',
  'token_type': 'Bearer',
  'expires_in': 900,
  'user': {'id': id, 'email': 'anna@bookslane.com'},
};

void main() {
  ({AuthRepositoryImpl repo, FakeTokenStorage store, FakeAdapter adapter})
  build(Map<String, dynamic> body, {int status = 200}) {
    final store = FakeTokenStorage();
    final adapter = FakeAdapter(body, status: status);
    final api = ApiClient(
      config: AppConfig.current.copyWith(enableLogging: false),
      storage: store,
    );
    api.dio.httpClientAdapter = adapter;

    return (
      repo: AuthRepositoryImpl(
        remoteDataSource: AuthRemoteDataSource(apiClient: api),
        tokenStorage: store,
      ),
      store: store,
      adapter: adapter,
    );
  }

  group('login', () {
    test('parses the real app-api payload and returns the user', () async {
      final t = build(loginPayload());

      final user = await t.repo.login(
        email: 'anna@bookslane.com',
        password: 'hunter2',
      );

      expect(user.id, 'c7f1-8a2b-uuid');
      expect(user.email, 'anna@bookslane.com');
      expect(user.name, isNull); // AppUserDto has no name
      expect(user.displayName, 'anna@bookslane.com');
    });

    test('persists the token pair', () async {
      final t = build(loginPayload());

      await t.repo.login(email: 'anna@bookslane.com', password: 'hunter2');

      expect(t.store.access, 'access-1');
      expect(t.store.refresh, 'refresh-1');
    });

    test('posts the credentials to /auth/login', () async {
      final t = build(loginPayload());

      await t.repo.login(email: 'anna@bookslane.com', password: 'hunter2');

      final request = t.adapter.requests.single;
      expect(request.path, ApiEndpoints.login);
      expect(request.data, {
        'email': 'anna@bookslane.com',
        'password': 'hunter2',
      });
    });

    test('maps a 401 to a friendly failure and stores nothing', () async {
      final t = build({'message': 'Invalid credentials'}, status: 401);

      await expectLater(
        t.repo.login(email: 'anna@bookslane.com', password: 'wrong'),
        throwsA(
          isA<AuthFailure>()
              .having((f) => f.kind, 'kind',
                  AuthFailureKind.invalidCredentials)
              .having((f) => f.message, 'message',
                  'Incorrect email or password.'),
        ),
      );
      expect(t.store.access, isNull);
    });

    test('maps a 500 to a server failure', () async {
      final t = build({'message': 'boom'}, status: 500);

      await expectLater(
        t.repo.login(email: 'anna@bookslane.com', password: 'hunter2'),
        throwsA(
          isA<AuthFailure>()
              .having((f) => f.kind, 'kind', AuthFailureKind.server),
        ),
      );
    });
  });

  group('user id accepts either type', () {
    test('string id passes through', () async {
      final t = build(loginPayload(id: 'c7f1-8a2b-uuid'));
      final user = await t.repo.login(email: 'a@b.c', password: 'hunter2');
      expect(user.id, 'c7f1-8a2b-uuid');
    });

    test('numeric id is normalised to its digits', () async {
      final t = build(loginPayload(id: 7));
      final user = await t.repo.login(email: 'a@b.c', password: 'hunter2');
      expect(user.id, '7');
    });

    test('7 and "7" produce equal users', () {
      expect(
        User(id: User.parseId(7), email: 'a@b.c'),
        User(id: User.parseId('7'), email: 'a@b.c'),
      );
    });

    test('an unusable id fails loudly at the edge', () {
      expect(() => User.parseId(null), throwsFormatException);
      expect(() => User.parseId({'nested': 1}), throwsFormatException);
    });
  });

  group('LoginResponse', () {
    test('tolerates a missing token_type and expires_in', () {
      final response = LoginResponse.fromJson({
        'access_token': 'a',
        'refresh_token': 'r',
        'user': {'id': 1, 'email': 'a@b.c'},
      });

      expect(response.tokenType, 'Bearer');
      expect(response.expiresIn, isNull);
      expect(response.user.id, '1');
    });

    test('rejects a payload with no user', () {
      expect(
        () => LoginResponse.fromJson({
          'access_token': 'a',
          'refresh_token': 'r',
        }),
        throwsFormatException,
      );
    });
  });
}

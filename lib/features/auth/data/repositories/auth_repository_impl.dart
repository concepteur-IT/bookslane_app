import 'package:dio/dio.dart';

import 'package:bookslane_app/core/storage/token_storage.dart';
import 'package:bookslane_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:bookslane_app/features/auth/data/models/login_request.dart';
import 'package:bookslane_app/features/auth/domain/entities/auth_failure.dart';
import 'package:bookslane_app/features/auth/domain/entities/user.dart';
import 'package:bookslane_app/features/auth/domain/repositories/auth_repository.dart';

/// Implements [AuthRepository] against the API and the device's token store.
///
/// Lives in `data/` because it depends on both — the domain layer only ever
/// sees the interface. It is also where `DioException` stops: everything above
/// gets an [AuthFailure] with a message meant for a person.
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.tokenStorage,
  });

  final AuthRemoteDataSource remoteDataSource;
  final TokenStorage tokenStorage;

  @override
  Future<User> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await remoteDataSource.login(
        LoginRequest(email: email, password: password),
      );

      // Persist before returning: without this the sign-in "succeeds" and
      // every later request still goes out anonymous, because AuthInterceptor
      // reads the token from here.
      await tokenStorage.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );

      return response.user.toEntity();
    } on DioException catch (error) {
      throw _mapDioError(error, on401: 'Incorrect email or password.');
    } on FormatException {
      throw const AuthFailure(
        'The server sent something unexpected. Please try again.',
        kind: AuthFailureKind.server,
      );
    }
  }

  @override
  Future<void> logout() async {
    try {
      await remoteDataSource.logout();
    } on DioException {
      // Deliberately swallowed. A user who taps "Log out" must end up logged
      // out of this device even with no connection, or an already-dead token.
    } finally {
      await tokenStorage.clear();
    }
  }

  @override
  Future<User?> restoreSession() async {
    final token = await tokenStorage.readAccessToken();
    if (token == null || token.isEmpty) return null;

    try {
      final user = await remoteDataSource.me();
      return user.toEntity();
    } on DioException catch (error) {
      // 401 here means even the refresh failed: the session is unrecoverable,
      // so drop the tokens and start clean.
      if (error.response?.statusCode == 401) {
        await tokenStorage.clear();
        return null;
      }
      // Offline at startup is not a reason to sign someone out — let the
      // caller decide (it keeps them on the sign-in screen for now).
      throw _mapDioError(error, on401: 'Your session has expired.');
    } on FormatException {
      await tokenStorage.clear();
      return null;
    }
  }

  AuthFailure _mapDioError(DioException error, {required String on401}) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const AuthFailure(
          'The server took too long to respond. Please try again.',
          kind: AuthFailureKind.network,
        );
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return const AuthFailure(
          'Cannot reach the server. Check your connection and try again.',
          kind: AuthFailureKind.network,
        );
      case DioExceptionType.cancel:
        return const AuthFailure('The request was cancelled.');
      case DioExceptionType.badCertificate:
        return const AuthFailure(
          'The server could not be verified.',
          kind: AuthFailureKind.network,
        );
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        if (status == 401) {
          return AuthFailure(on401, kind: AuthFailureKind.invalidCredentials);
        }
        final message = _serverMessage(error.response?.data);
        if (status != null && status >= 500) {
          return AuthFailure(
            message ?? 'Something went wrong on our side. Please try again.',
            kind: AuthFailureKind.server,
          );
        }
        return AuthFailure(
          message ?? 'That request could not be completed.',
          kind: AuthFailureKind.server,
        );
    }
  }

  /// NestJS puts validation problems in `message`, as a string or a list.
  String? _serverMessage(Object? body) {
    if (body is! Map) return null;
    final message = body['message'];
    if (message is String && message.isNotEmpty) return message;
    if (message is List && message.isNotEmpty) return message.first.toString();
    return null;
  }
}

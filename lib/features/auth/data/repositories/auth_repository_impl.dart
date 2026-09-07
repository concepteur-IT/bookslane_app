import 'package:bookslane_app/core/storage/token_storage.dart';
import 'package:bookslane_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:bookslane_app/features/auth/data/models/login_request.dart';
import 'package:bookslane_app/features/auth/domain/entities/user.dart';
import 'package:bookslane_app/features/auth/domain/repositories/auth_repository.dart';

/// Implements [AuthRepository] against the API and the device's token store.
///
/// Lives in `data/` because it depends on both — the domain layer only ever
/// sees the interface.
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
    final response = await remoteDataSource.login(
      LoginRequest(email: email, password: password),
    );

    // Persist before returning: without this the sign-in "succeeds" and every
    // later request still goes out anonymous, because AuthInterceptor reads
    // the token from here.
    await tokenStorage.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );

    return response.user.toEntity();
  }
}

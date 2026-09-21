import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bookslane_app/core/config/config.dart';
import 'package:bookslane_app/core/network/api_client.dart';
import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:bookslane_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bookslane_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:bookslane_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:bookslane_app/features/auth/presentation/widgets/auth_gate.dart';
import 'package:bookslane_app/features/books/data/datasources/books_remote_datasource.dart';
import 'package:bookslane_app/features/books/data/repositories/books_repository_impl.dart';
import 'package:bookslane_app/features/books/domain/repositories/books_repository.dart';
import 'package:bookslane_app/features/products/data/datasources/products_remote_datasource.dart';
import 'package:bookslane_app/features/products/data/repositories/products_repository_impl.dart';
import 'package:bookslane_app/features/products/domain/repositories/products_repository.dart';

void main() {
  runApp(const BooksLane());
}

class BooksLane extends StatefulWidget {
  const BooksLane({super.key});

  @override
  State<BooksLane> createState() => _BooksLaneState();
}

class _BooksLaneState extends State<BooksLane> {
  late final AuthProvider _authProvider;
  late final ApiClient _apiClient;
  late final ProductsRepository _productsRepository;
  late final BooksRepository _booksRepository;

  @override
  void initState() {
    super.initState();

    // Built once for the life of the app: each ApiClient carries its own Dio
    // and connection pool.
    //
    // onSessionExpired fires when a token refresh fails mid-session. It flips
    // the provider, and AuthGate swaps to the login screen from wherever the
    // user happened to be.
    _apiClient = ApiClient(
      onSessionExpired: () => _authProvider.onSessionExpired(),
    );

    final AuthRepository repository = AuthRepositoryImpl(
      remoteDataSource: AuthRemoteDataSource(apiClient: _apiClient),
      tokenStorage: _apiClient.storage,
    );

    // Shares the one ApiClient, so products ride the same bearer token and
    // refresh handling as everything else.
    _productsRepository = ProductsRepositoryImpl(
      remoteDataSource: ProductsRemoteDataSource(apiClient: _apiClient),
    );

    _booksRepository = BooksRepositoryImpl(
      remoteDataSource: BooksRemoteDataSource(apiClient: _apiClient),
    );

    _authProvider = AuthProvider(repository);
    // Checks the stored token; the splash stays up until it answers.
    _authProvider.bootstrap();
  }

  @override
  void dispose() {
    _authProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),
        Provider<ProductsRepository>.value(value: _productsRepository),
        Provider<BooksRepository>.value(value: _booksRepository),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        // Every colour, type style, radius and motion token lives in
        // lib/core/theme - never style a widget with a raw value.
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.light,
        // Not a fixed home screen: the gate derives it from the auth status.
        home: const AuthGate(),
      ),
    );
  }
}

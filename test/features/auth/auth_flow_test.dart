import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/core/widgets/widgets.dart';
import 'package:bookslane_app/features/auth/domain/entities/auth_failure.dart';
import 'package:bookslane_app/features/auth/domain/entities/user.dart';
import 'package:bookslane_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:bookslane_app/features/auth/presentation/pages/login_page.dart';
import 'package:bookslane_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:bookslane_app/features/auth/presentation/widgets/auth_gate.dart';
import 'package:bookslane_app/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:bookslane_app/features/splash/presentation/pages/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

const _user = User(id: '7', email: 'anna@bookslane.com', name: 'Anna');

/// Stands in for the network + keychain.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.storedUser, this.failure});

  /// What restoreSession() finds — null means "no session".
  User? storedUser;

  /// Thrown by login() when set.
  AuthFailure? failure;

  int loginCalls = 0;
  int logoutCalls = 0;

  @override
  Future<User> login({required String email, required String password}) async {
    loginCalls++;
    await Future<void>.delayed(const Duration(milliseconds: 10));
    if (failure != null) throw failure!;
    return _user;
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
    storedUser = null;
  }

  @override
  Future<User?> restoreSession() async => storedUser;
}

Widget app(AuthProvider provider) => ChangeNotifierProvider.value(
  value: provider,
  child: MaterialApp(theme: AppTheme.light, home: const AuthGate()),
);

Future<void> signIn(WidgetTester tester) async {
  await tester.enterText(
    find.byType(AppTextField).first,
    'anna@bookslane.com',
  );
  await tester.enterText(find.byType(AppTextField).last, 'hunter2');
  await tester.tap(find.text('SIGN IN'));
}

void main() {
  Future<void> pumpApp(WidgetTester tester, AuthProvider provider) async {
    tester.view.physicalSize = const Size(390 * 3, 1400 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(provider));
  }

  group('startup', () {
    testWidgets('shows the splash while the session is being checked',
        (tester) async {
      final provider = AuthProvider(FakeAuthRepository());
      await pumpApp(tester, provider);

      expect(find.byType(SplashPage), findsOneWidget);
      expect(provider.status, AuthStatus.unknown);
    });

    testWidgets('no stored session opens the login page', (tester) async {
      final provider = AuthProvider(FakeAuthRepository())..bootstrap();
      await pumpApp(tester, provider);
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.byType(DashboardPage), findsNothing);
    });

    testWidgets('a stored session opens the dashboard directly',
        (tester) async {
      final provider = AuthProvider(FakeAuthRepository(storedUser: _user))
        ..bootstrap();
      await pumpApp(tester, provider);
      await tester.pumpAndSettle();

      expect(find.byType(DashboardPage), findsOneWidget);
      expect(find.byType(LoginPage), findsNothing);
      // Greets the real user rather than a placeholder.
      expect(find.text('Good morning, Anna'), findsOneWidget);
    });
  });

  group('login', () {
    testWidgets('valid credentials land on the dashboard', (tester) async {
      final repository = FakeAuthRepository();
      final provider = AuthProvider(repository)..bootstrap();
      await pumpApp(tester, provider);
      await tester.pumpAndSettle();

      await signIn(tester);
      await tester.pumpAndSettle();

      expect(repository.loginCalls, 1);
      expect(find.byType(DashboardPage), findsOneWidget);
      expect(provider.user, _user);
    });

    testWidgets('the button shows a spinner while the request is in flight',
        (tester) async {
      final provider = AuthProvider(FakeAuthRepository())..bootstrap();
      await pumpApp(tester, provider);
      await tester.pumpAndSettle();

      await signIn(tester);
      await tester.pump(); // request started, not finished

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('a rejected sign-in shows a toast and stays put',
        (tester) async {
      final repository = FakeAuthRepository(
        failure: const AuthFailure(
          'Incorrect email or password.',
          kind: AuthFailureKind.invalidCredentials,
        ),
      );
      final provider = AuthProvider(repository)..bootstrap();
      await pumpApp(tester, provider);
      await tester.pumpAndSettle();

      await signIn(tester);
      await tester.pumpAndSettle();

      expect(find.text('Incorrect email or password.'), findsOneWidget);
      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.byType(DashboardPage), findsNothing);
      expect(provider.isSubmitting, isFalse, reason: 'button must recover');
    });

    testWidgets('invalid input never reaches the API', (tester) async {
      final repository = FakeAuthRepository();
      final provider = AuthProvider(repository)..bootstrap();
      await pumpApp(tester, provider);
      await tester.pumpAndSettle();

      await tester.tap(find.text('SIGN IN')); // empty form
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email'), findsOneWidget);
      expect(repository.loginCalls, 0);
    });
  });

  group('logout', () {
    testWidgets('confirming returns to the login page', (tester) async {
      final repository = FakeAuthRepository(storedUser: _user);
      final provider = AuthProvider(repository)..bootstrap();
      await pumpApp(tester, provider);
      await tester.pumpAndSettle();
      expect(find.byType(DashboardPage), findsOneWidget);

      await tester.tap(find.byTooltip('Log out'));
      await tester.pumpAndSettle();
      expect(find.text('Log out?'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Log out'));
      await tester.pumpAndSettle();

      expect(repository.logoutCalls, 1);
      expect(find.byType(LoginPage), findsOneWidget);
      expect(provider.user, isNull);
    });

    testWidgets('cancelling keeps the session', (tester) async {
      final repository = FakeAuthRepository(storedUser: _user);
      final provider = AuthProvider(repository)..bootstrap();
      await pumpApp(tester, provider);
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Log out'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(repository.logoutCalls, 0);
      expect(find.byType(DashboardPage), findsOneWidget);
    });
  });

  group('session expiry', () {
    testWidgets('a failed refresh mid-session bounces to login',
        (tester) async {
      final provider = AuthProvider(FakeAuthRepository(storedUser: _user))
        ..bootstrap();
      await pumpApp(tester, provider);
      await tester.pumpAndSettle();
      expect(find.byType(DashboardPage), findsOneWidget);

      // What ApiClient(onSessionExpired:) calls from the interceptor.
      provider.onSessionExpired();
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
    });
  });
}

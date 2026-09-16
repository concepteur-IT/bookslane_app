import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bookslane_app/features/auth/presentation/pages/login_page.dart';
import 'package:bookslane_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:bookslane_app/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:bookslane_app/features/splash/presentation/pages/splash_page.dart';

/// Decides which screen the app is on, from [AuthProvider.status].
///
/// This is the whole redirect mechanism. Because the screen is *derived* from
/// the status rather than pushed onto a stack:
///
/// * signing in swaps to the dashboard with no `Navigator.push`,
/// * signing out swaps back to sign-in from anywhere,
/// * a signed-in user cannot land on the login page, and a signed-out one
///   cannot land on the dashboard — there is no route to get there.
///
/// It also means no stale screens are left underneath: the previous tree is
/// disposed rather than parked on the navigator stack.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.select<AuthProvider, AuthStatus>((p) => p.status);

    return switch (status) {
      // Startup, while the stored token is checked.
      AuthStatus.unknown => const SplashPage(),
      AuthStatus.authenticated => const DashboardPage(),
      AuthStatus.unauthenticated => const LoginPage(),
    };
  }
}

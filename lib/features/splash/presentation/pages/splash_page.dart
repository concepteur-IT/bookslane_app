import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:bookslane_app/core/config/config.dart';
import 'package:bookslane_app/core/theme/theme.dart';

/// Brand screen shown while the app works out whether anyone is signed in.
///
/// It no longer navigates anywhere itself: [AuthGate] shows it for exactly as
/// long as `AuthProvider.status` is `unknown`, which removes the old race
/// between a fixed timer and however long the session check actually takes.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    final isApple =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;

    if (isApple) {
      // CupertinoPageScaffold provides no Material ancestor, so Text would
      // fall back to WidgetsApp's error style (red, yellow double underline).
      // A transparent Material supplies the text defaults without painting.
      return const CupertinoPageScaffold(
        backgroundColor: CupertinoColors.white,
        child: Material(
          type: MaterialType.transparency,
          child: _SplashContent(),
        ),
      );
    }

    return const Scaffold(
      backgroundColor: AppColors.surfaceBackground,
      body: _SplashContent(),
    );
  }
}

class _SplashContent extends StatelessWidget {
  const _SplashContent();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            AppAssets.logo,
            width: 120,
            height: 120,
            fit: BoxFit.contain,
          ),

          const SizedBox(height: AppSpacing.lg),

          Text(
            'Your book, your business',
            style: AppTypography.headlineLarge.copyWith(
              color: AppColors.ctaBackground,
            ),
          ),
        ],
      ),
    );
  }
}

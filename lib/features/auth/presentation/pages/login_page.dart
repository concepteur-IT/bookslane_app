import 'package:flutter/material.dart';

import 'package:bookslane_app/core/config/config.dart';
import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/features/auth/presentation/widgets/login_form.dart';
import 'package:bookslane_app/features/dashboard/presentation/pages/dashboard_page.dart';

/// Sign-in screen: purple brand header with the logo, and a white sheet
/// carrying the form.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      // Light status bar icons over the purple header.
      value: AppTheme.brandOverlay,
      child: Scaffold(
        backgroundColor: AppColors.brandPrimaryDark,
        body: DecoratedBox(
          decoration: AppDecorations.brandHeader,
          child: SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // The sheet fills whatever height is left below the branding,
                // and the whole screen scrolls once the keyboard opens.
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    // IntrinsicHeight lets the sheet below take the leftover
                    // space, so it reaches the bottom edge on tall screens
                    // instead of leaving a purple strip under it.
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _Branding(),
                          Expanded(
                            child: _FormSheet(
                              child: LoginForm(
                                // TODO: authenticate against the API before
                                // routing; this only proves the flow works.
                                onSubmit: (email, password) =>
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute<void>(
                                        builder: (_) => const DashboardPage(),
                                      ),
                                    ),
                                onForgotPassword: () {},
                                // onCreateAccount: () {},
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Logo tile, app name and tagline on the purple header.
class _Branding extends StatelessWidget {
  const _Branding();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.xxxl + AppSpacing.lg,
        AppSpacing.page,
        AppSpacing.xxxl + AppSpacing.xxl,
      ),
      child: Column(
        children: [
          Container(
            width: AppSizes.logoTile,
            height: AppSizes.logoTile,
            decoration: AppDecorations.logoTile,
            // The artwork runs to the edge of its own canvas, so it fills the
            // tile edge to edge; clipping keeps it inside the tile's shape.
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              AppAssets.logo,
              fit: BoxFit.contain,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          Text(
            'Bookslane',
            textAlign: TextAlign.center,
            style: AppTypography.displayLarge.copyWith(
              color: AppColors.brandHeaderText,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(
            'Sign in to continue to your workspace',
            textAlign: TextAlign.center,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.brandHeaderSubtitleText,
            ),
          ),
        ],
      ),
    );
  }
}

/// White sheet that overlaps the brand header and holds the form.
class _FormSheet extends StatelessWidget {
  const _FormSheet({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: AppDecorations.sheet,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.xl + AppSpacing.xxs,
        AppSpacing.page,
        // Keep the sheet clear of the keyboard when it comes up.
        AppSpacing.xl + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: child,
    );
  }
}

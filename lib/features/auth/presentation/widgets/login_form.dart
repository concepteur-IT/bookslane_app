import 'package:flutter/material.dart';

import 'package:bookslane_app/core/config/config.dart';
import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/core/widgets/widgets.dart';

/// The sign-in form that sits inside the white sheet on [LoginPage].
///
/// Owns nothing but its own input state — validation, the password visibility
/// toggle and the field controllers. Navigation and the actual auth call are
/// handed back to the caller through the callbacks.
class LoginForm extends StatefulWidget {
  const LoginForm({
    super.key,
    this.onSubmit,
    this.onForgotPassword,
    this.isSubmitting = false,
    // this.onCreateAccount,
  });

  /// Called with the trimmed email and the raw password once the form passes
  /// validation.
  final void Function(String email, String password)? onSubmit;

  final VoidCallback? onForgotPassword;

  /// While true the button shows a spinner and stops accepting taps.
  final bool isSubmitting;
  // final VoidCallback? onCreateAccount;

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _submit() {
    // Dismiss the keyboard first so validation errors aren't hidden behind it.
    FocusScope.of(context).unfocus();

    if (widget.isSubmitting) return;

    // Client-side validation runs first, so an obviously bad email never
    // becomes a network round trip.
    if (!(_formKey.currentState?.validate() ?? false)) return;

    widget.onSubmit?.call(
      _emailController.text.trim(),
      _passwordController.text,
    );
  }

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return 'Please enter your email';
    if (!AppConstants.emailPattern.hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if ((value ?? '').isEmpty) return 'Please enter your password';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome back', style: AppTypography.displayMedium),

            const SizedBox(height: AppSpacing.xs),

            Text(
              'Enter your credentials to sign in',
              style: AppTypography.bodyMedium,
            ),

            const SizedBox(height: AppSpacing.xl),

            const FieldLabel('Email'),
            const SizedBox(height: AppSpacing.labelGap),
            AppTextField(
              controller: _emailController,
              hintText: 'you@example.com',
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: _validateEmail,
              onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
            ),

            const SizedBox(height: AppSpacing.fieldGap),

            const FieldLabel('Password'),
            const SizedBox(height: AppSpacing.labelGap),
            AppTextField(
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              hintText: '........',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              validator: _validatePassword,
              onFieldSubmitted: (_) => _submit(),
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: AppSizes.iconMd,
                ),
                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
              ),
            ),

            // No gap: the text button carries its own 48pt tap target.
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: widget.onForgotPassword,
                child: const Text('Forgot password?'),
              ),
            ),

            const SizedBox(height: AppSpacing.xs),

            CtaButton(
              label: 'SIGN IN',
              icon: Icons.arrow_forward_rounded,
              isLoading: widget.isSubmitting,
              onPressed: _submit,
            ),

            const SizedBox(height: AppSpacing.md),
            /*
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Don't have an account?", style: AppTypography.bodyMedium),
                TextButton(
                  onPressed: widget.onCreateAccount,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxs,
                    ),
                    textStyle: AppTypography.linkBrand,
                    foregroundColor: AppColors.linkTextBrand,
                  ),
                  child: const Text('Create account'),
                ),
              ],
            ),*/
          ],
        ),
      ),
    );
  }
}

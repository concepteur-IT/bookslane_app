import 'package:flutter/material.dart';

import 'package:bookslane_app/core/theme/theme.dart';

/// The app's standard text field.
///
/// Fill, radius, padding, hint style and the focus/error borders all come from
/// `AppTheme`'s `inputDecorationTheme` — only the per-field bits are passed in,
/// so every field in the product looks the same by construction.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.focusNode,
    this.suffixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.validator,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final FocusNode? focusNode;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      enabled: enabled,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      style: AppTypography.input,
      cursorColor: AppColors.inputCursor,
      decoration: InputDecoration(
        hintText: hintText,
        // Icon colours are left to the theme's prefix/suffix icon colours.
        prefixIcon: Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.sm,
          ),
          child: Icon(prefixIcon, size: AppSizes.iconMd),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: suffixIcon,
      ),
    );
  }
}

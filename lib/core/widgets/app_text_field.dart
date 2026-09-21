import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    this.maxLines = 1,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
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

  /// Multi-line fields (a description, an address) pass a larger value. Must
  /// stay 1 when [obscureText] is true — Flutter asserts on that pair.
  final int maxLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;

  /// Keeps unwanted characters out of numeric fields, so a price field never
  /// has to reject what it could have refused to accept.
  final List<TextInputFormatter>? inputFormatters;
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
      maxLines: maxLines,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      autofillHints: autofillHints,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      style: AppTypography.input,
      cursorColor: AppColors.inputCursor,
      decoration: InputDecoration(
        hintText: hintText,
        // Icon colours are left to the theme's prefix/suffix icon colours.
        // A multi-line field grows downwards, so its icon is pinned to the
        // first line instead of drifting to the vertical centre.
        prefixIcon: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.sm,
            bottom: maxLines > 1 ? AppSpacing.lg : 0,
          ),
          child: Icon(prefixIcon, size: AppSizes.iconMd),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: suffixIcon,
      ),
    );
  }
}

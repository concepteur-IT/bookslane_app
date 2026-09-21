import 'package:flutter/material.dart';

import 'package:bookslane_app/core/theme/theme.dart';

/// The app's standard dropdown — [AppTextField]'s sibling.
///
/// Fill, radius, padding and the focus/error borders come from `AppTheme`'s
/// `inputDecorationTheme`, exactly as they do for a text field, so a dropdown
/// and a text field sitting next to each other line up.
///
/// [T] is whatever the caller keeps in state — usually one of the option enums
/// in `book_form_options.dart`, not a string.
class AppDropdownField<T> extends StatelessWidget {
  const AppDropdownField({
    super.key,
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.hintText,
    required this.prefixIcon,
    required this.onChanged,
    this.validator,
    this.enabled = true,
  });

  /// The current selection, or null when nothing has been picked yet.
  final T? value;

  final List<T> items;

  /// What each option reads as in the menu.
  final String Function(T item) labelBuilder;

  final String hintText;
  final IconData prefixIcon;
  final ValueChanged<T?> onChanged;
  final FormFieldValidator<T>? validator;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      // Guards against a stale value that is no longer in `items` — once the
      // lists come from the API an option can disappear between builds.
      initialValue: items.contains(value) ? value : null,
      isExpanded: true,
      validator: validator,
      onChanged: enabled ? onChanged : null,
      style: AppTypography.input.copyWith(color: AppColors.inputText),
      hint: Text(hintText, style: AppTypography.hint),
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        size: AppSizes.iconLg,
        color: AppColors.inputSuffixIcon,
      ),
      dropdownColor: AppColors.surfaceBackground,
      borderRadius: AppRadius.mdAll,
      decoration: InputDecoration(
        enabled: enabled,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.sm,
          ),
          child: Icon(prefixIcon, size: AppSizes.iconMd),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        // The dropdown draws its own trailing arrow, so the theme's right-hand
        // padding would double up.
        contentPadding: const EdgeInsets.only(right: AppSpacing.sm),
      ),
      items: [
        for (final item in items)
          DropdownMenuItem<T>(
            value: item,
            child: Text(
              labelBuilder(item),
              style: AppTypography.input,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}

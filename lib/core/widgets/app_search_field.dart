import 'package:flutter/material.dart';

import 'package:bookslane_app/core/theme/theme.dart';

/// Search box used at the top of list screens.
///
/// Sits on the grey page canvas, so it overrides the theme's grey input fill
/// with the card surface to stay legible.
class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    this.controller,
    this.onChanged,
    this.hintText = 'Search stores, orders, products...',
  });

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: AppTypography.input,
      cursorColor: AppColors.inputCursor,
      decoration: InputDecoration(
        hintText: hintText,
        fillColor: AppColors.surfaceBackground,
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.sm),
          child: Icon(Icons.search_rounded, size: AppSizes.iconLg),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      ),
    );
  }
}

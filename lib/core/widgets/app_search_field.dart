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
    this.dense = false,
  });

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String hintText;

  /// Trims the field to [AppSizes.minTapTarget] tall, so it lines up with
  /// square icon buttons on the same row.
  final bool dense;

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
        contentPadding: dense
            ? const EdgeInsets.symmetric(
                vertical: AppSpacing.sm + 2,
                horizontal: AppSpacing.xxs,
              )
            : null,
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

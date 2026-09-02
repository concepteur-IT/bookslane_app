import 'package:flutter/material.dart';

import 'package:bookslane_app/core/theme/theme.dart';

/// Uppercase label that sits above a form field — "EMAIL", "PASSWORD".
///
/// Pair it with [AppSpacing.labelGap] before the field it describes.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTypography.fieldLabel);
  }
}

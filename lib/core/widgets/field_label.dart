import 'package:flutter/material.dart';

import 'package:bookslane_app/core/theme/theme.dart';

/// Uppercase label that sits above a form field — "EMAIL", "PASSWORD".
///
/// Pair it with [AppSpacing.labelGap] before the field it describes. Set
/// [isRequired] to mark the field with an asterisk; the label also carries the
/// fact in its semantics, so a screen reader announces "Title, required"
/// rather than reading the asterisk as punctuation.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.isRequired = false});

  final String text;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    if (!isRequired) return Text(text, style: AppTypography.fieldLabel);

    return Semantics(
      label: '$text, required',
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          style: AppTypography.fieldLabel,
          children: [
            TextSpan(text: text),
            TextSpan(
              text: ' *',
              style: AppTypography.fieldLabel.copyWith(
                color: AppColors.inputBorderError,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

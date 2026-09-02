import 'package:flutter/material.dart';

import 'package:bookslane_app/core/theme/theme.dart';

/// Section title with an optional trailing action — "Today's visits / See all".
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onActionPressed,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Expanded so a long title ellipsizes instead of overflowing the row
        // (also matters at large text-scale settings).
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.headlineMedium,
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onActionPressed,
            child: Text(actionLabel!, maxLines: 1),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import 'package:bookslane_app/core/theme/theme.dart';

/// The gradient call-to-action button from the design system.
///
/// `ElevatedButton` renders the flat red variant; this is the gradient one,
/// which [ThemeData] cannot express. Pass a null [onPressed] to disable it, or
/// set [isLoading] while a request is in flight.
class CtaButton extends StatelessWidget {
  const CtaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null && !isLoading;

    return Container(
      height: AppSizes.buttonHeight,
      decoration: isEnabled
          ? AppDecorations.ctaButton
          : AppDecorations.ctaButtonDisabled,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.lgAll,
          onTap: isEnabled ? onPressed : null,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: AppSizes.iconLg,
                    height: AppSizes.iconLg,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.ctaText,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label, style: AppTypography.button),
                      if (icon != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Icon(
                          icon,
                          color: AppColors.ctaIcon,
                          size: AppSizes.iconMd,
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

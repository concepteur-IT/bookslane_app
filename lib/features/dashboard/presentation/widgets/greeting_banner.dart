import 'package:flutter/material.dart';

import 'package:bookslane_app/core/theme/theme.dart';

/// Purple hero card — the same brand gradient as the sign-in header.
class GreetingBanner extends StatelessWidget {
  const GreetingBanner({
    super.key,
    required this.greeting,
    required this.headline,
    required this.note,
  });

  /// "Good morning, Anna"
  final String greeting;

  /// "You have 4 visits today"
  final String headline;

  /// "Performance up 12% this week"
  final String note;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.xlAll,
      child: DecoratedBox(
        decoration: AppDecorations.brandHeader,
        child: Stack(
          children: [
            // Decorative rings bleeding off the right edge.
            Positioned(
              right: -40,
              top: -30,
              child: _Ring(size: 180, opacity: 0.06),
            ),
            const Positioned(
              right: -10,
              bottom: -60,
              child: _Ring(size: 140, opacity: 0.05),
            ),

            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.brandHeaderSubtitleText,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xs),

                  Text(
                    headline,
                    style: AppTypography.headlineLarge.copyWith(
                      color: AppColors.brandHeaderText,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  Row(
                    children: [
                      Icon(
                        Icons.trending_up_rounded,
                        size: AppSizes.iconMd,
                        color: AppColors.brandHeaderSubtitleText,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          note,
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.brandHeaderSubtitleText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.inverseText.withValues(alpha: opacity),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/core/widgets/widgets.dart';

/// Where a scheduled visit stands. Drives the pill colour and wording.
enum VisitStatus {
  done('Done'),
  active('Active'),
  upcoming('Upcoming');

  const VisitStatus(this.label);

  final String label;

  Color get color => switch (this) {
    VisitStatus.done => AppColors.successText,
    VisitStatus.active => AppColors.brandPrimary,
    VisitStatus.upcoming => AppColors.secondaryText,
  };
}

/// A store visit on the schedule.
class Visit {
  const Visit({
    required this.store,
    required this.timeRange,
    required this.address,
    required this.status,
  });

  final String store;

  /// Preformatted for display: "09:00 - 10:30".
  final String timeRange;
  final String address;
  final VisitStatus status;
}

/// One row of "Today's visits": pin tile, store, time and address, status.
class VisitCard extends StatelessWidget {
  const VisitCard({super.key, required this.visit, this.onTap});

  final Visit visit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.lgAll,
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surfaceBackground,
            borderRadius: AppRadius.lgAll,
            boxShadow: AppShadows.card,
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: AppSizes.tileLg,
                height: AppSizes.tileLg,
                decoration: const BoxDecoration(
                  color: AppColors.brandPrimary,
                  borderRadius: AppRadius.mdAll,
                ),
                child: Icon(
                  Icons.location_on_outlined,
                  size: AppSizes.iconLg,
                  color: AppColors.inverseText,
                ),
              ),

              const SizedBox(width: AppSpacing.sm),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      visit.store,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleLarge,
                    ),

                    const SizedBox(height: AppSpacing.xxs),

                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: AppSizes.iconSm,
                          color: AppColors.iconMuted,
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Flexible(
                          child: Text(
                            '${visit.timeRange} · ${visit.address}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.xs),

              StatusPill(label: visit.status.label, color: visit.status.color),
            ],
          ),
        ),
      ),
    );
  }
}

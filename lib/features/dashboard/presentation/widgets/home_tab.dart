import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/core/widgets/widgets.dart';
import 'package:bookslane_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:bookslane_app/features/dashboard/presentation/widgets/greeting_banner.dart';
import 'package:bookslane_app/features/dashboard/presentation/widgets/section_header.dart';
import 'package:bookslane_app/features/dashboard/presentation/widgets/stat_card.dart';
import 'package:bookslane_app/features/dashboard/presentation/widgets/visit_card.dart';

/// The Home tab: greeting, headline figures and today's schedule.
///
/// Just the body — the app bar and bottom bar belong to the shell.
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  // TODO: replace with data from the API once the endpoints exist.
  static const _visits = <Visit>[
    Visit(
      store: 'City Gross Malmö',
      timeRange: '09:00 - 10:30',
      address: 'Hyllie Blvd 12',
      status: VisitStatus.done,
    ),
    Visit(
      store: 'ICA Maxi Lund',
      timeRange: '11:00 - 12:00',
      address: 'St Lars väg 8',
      status: VisitStatus.active,
    ),
    Visit(
      store: 'Coop Forum',
      timeRange: '13:30 - 14:30',
      address: 'Mobilia, Malmö',
      status: VisitStatus.upcoming,
    ),
    Visit(
      store: 'Willys Svedala',
      timeRange: '15:00 - 16:00',
      address: 'Industrivägen 4',
      status: VisitStatus.upcoming,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // The signed-in user, not a placeholder. displayName falls back to the
    // email, since app-api's AppUserDto carries no name field.
    final name = context.select<AuthProvider, String>(
      (auth) => auth.user?.displayName ?? 'there',
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      children: [
        const AppSearchField(hintText: 'Search stores, orders, products...'),

        const SizedBox(height: AppSpacing.lg),

        GreetingBanner(
          greeting: 'Good morning, $name',
          headline: 'You have 4 visits today',
          note: 'Performance up 12% this week',
        ),

        const SizedBox(height: AppSpacing.lg),

        const _StatsRow(),

        const SizedBox(height: AppSpacing.sm),

        SectionHeader(
          title: "Today's visits",
          actionLabel: 'See all',
          onActionPressed: () {},
        ),

        const SizedBox(height: AppSpacing.sm),

        // Non-scrolling: the page itself is the scroll view.
        for (final visit in _visits) ...[
          VisitCard(visit: visit, onTap: () {}),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

/// The three headline figures. Equal widths, so they stay aligned whatever the
/// numbers are.
class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: StatCard(
              icon: Icons.shopping_bag_outlined,
              iconColor: AppColors.brandPrimary,
              value: '128',
              label: 'Orders',
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: StatCard(
              icon: Icons.inventory_2_outlined,
              iconColor: AppColors.ctaBackground,
              value: '1,248',
              label: 'Products',
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: StatCard(
              icon: Icons.account_balance_wallet_outlined,
              iconColor: AppColors.warningText,
              value: '84.3k',
              label: 'Revenue',
            ),
          ),
        ],
      ),
    );
  }
}

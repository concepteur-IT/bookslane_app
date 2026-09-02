import 'package:flutter/material.dart';

import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/features/dashboard/presentation/widgets/dashboard_app_bar.dart';
import 'package:bookslane_app/features/dashboard/presentation/widgets/dashboard_search_field.dart';
import 'package:bookslane_app/features/dashboard/presentation/widgets/greeting_banner.dart';
import 'package:bookslane_app/features/dashboard/presentation/widgets/section_header.dart';
import 'package:bookslane_app/features/dashboard/presentation/widgets/stat_card.dart';
import 'package:bookslane_app/features/dashboard/presentation/widgets/visit_card.dart';
import 'package:bookslane_app/features/notifications/presentation/notifications_overlay.dart';
import 'package:bookslane_app/features/notifications/presentation/widgets/app_notification.dart';

/// Home screen: greeting, headline figures and today's schedule.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _navIndex = 0;

  // TODO: replace with the notifications feed from the API.
  List<AppNotification> _notifications = const [
    AppNotification(
      id: 'n1',
      kind: NotificationKind.order,
      title: 'New order received',
      body: 'ICA Maxi Lund placed an order worth €1,240.',
      timeAgo: '5 min ago',
    ),
    AppNotification(
      id: 'n2',
      kind: NotificationKind.visit,
      title: 'Visit reminder',
      body: 'Your visit to Coop Forum starts in 30 minutes.',
      timeAgo: '25 min ago',
    ),
    AppNotification(
      id: 'n3',
      kind: NotificationKind.stock,
      title: 'Low stock alert',
      body: '"Productivity Planner" has only 4 units left.',
      timeAgo: '1 hour ago',
    ),
    AppNotification(
      id: 'n4',
      kind: NotificationKind.delivery,
      title: 'Delivery delayed',
      body: 'Shipment #SH-881 to Malmö is delayed by 2 hours.',
      timeAgo: '3 hours ago',
      isRead: true,
    ),
    AppNotification(
      id: 'n5',
      kind: NotificationKind.report,
      title: 'Weekly report ready',
      body: 'Your performance summary for last week is available.',
      timeAgo: '5 hours ago',
      isRead: true,
    ),
  ];

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  void _markAllRead() {
    setState(() {
      _notifications = [
        for (final n in _notifications) n.copyWith(isRead: true),
      ];
    });
  }

  Future<void> _openNotifications() {
    return showNotificationsPanel(
      context: context,
      notifications: _notifications,
      topOffset: DashboardAppBar.height,
      onMarkAllRead: () {
        _markAllRead();
        // Close so the cleared badge is visible straight away.
        Navigator.of(context).pop();
      },
      onViewAll: () => Navigator.of(context).pop(),
      onNotificationTap: (_) => Navigator.of(context).pop(),
    );
  }

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
    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: DashboardAppBar(
        section: 'Home',
        notificationCount: _unreadCount,
        onNotificationsPressed: _openNotifications,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.xl,
          ),
          children: [
            const DashboardSearchField(),

            const SizedBox(height: AppSpacing.lg),

            const GreetingBanner(
              greeting: 'Good morning, Anna',
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
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (index) => setState(() => _navIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.widgets_outlined),
            selectedIcon: Icon(Icons.widgets_rounded),
            label: 'Products',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
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

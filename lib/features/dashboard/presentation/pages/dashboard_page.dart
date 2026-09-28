import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/core/widgets/widgets.dart';
import 'package:bookslane_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:bookslane_app/features/books/domain/entities/book.dart';
import 'package:bookslane_app/features/books/presentation/pages/book_list_page.dart';
import 'package:bookslane_app/features/books/presentation/pages/books_hub_page.dart';
import 'package:bookslane_app/features/dashboard/presentation/widgets/coming_soon_tab.dart';
import 'package:bookslane_app/features/dashboard/presentation/widgets/dashboard_app_bar.dart';
import 'package:bookslane_app/features/dashboard/presentation/widgets/home_tab.dart';
import 'package:bookslane_app/features/notifications/presentation/notifications_overlay.dart';
import 'package:bookslane_app/features/notifications/presentation/widgets/app_notification.dart';
import 'package:bookslane_app/features/shop/presentation/pages/shop_page.dart';

/// The signed-in shell: app bar, the bottom bar, and whichever tab is open.
///
/// Tabs are bodies, not routes — the bar stays put while the content swaps,
/// and each tab keeps its own state.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _navIndex = 0;

  /// Null while the Books tab is on its hub; set once a shelf is chosen.
  /// Keeping it here (rather than pushing a route) is what leaves the bottom
  /// bar visible on the list, as in the design.
  BookSource? _bookSource;

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

  /// True while a tab is showing an inner page, which brings its own bar.
  bool get _isInnerPage => _navIndex == 1 && _bookSource != null;

  /// Shown under the app name in the bar.
  String get _section => switch (_navIndex) {
    0 => 'Home',
    1 => 'Books',
    2 => 'Shop',
    3 => 'Orders',
    _ => 'Profile',
  };

  Widget get _body => switch (_navIndex) {
    0 => const HomeTab(),
    1 => _bookSource == null
        ? BooksHubPage(
            onSourceSelected: (source) =>
                setState(() => _bookSource = source),
          )
        // BookListPage routes each shelf to its API: My Store to /v1/books,
        // My Publishings to /v1/products (the thinkerslane catalogue).
        : BookListPage(
            // A key per shelf, so switching shelves rebuilds the state
            // instead of carrying the previous search and page across.
            key: ValueKey(_bookSource),
            source: _bookSource!,
            onBack: () => setState(() => _bookSource = null),
          ),
    2 => const ShopPage(),
    3 => const ComingSoonTab(
      title: 'Orders',
      icon: Icons.receipt_long_outlined,
    ),
    _ => const ComingSoonTab(
      title: 'Profile',
      icon: Icons.person_outline_rounded,
    ),
  };

  void _onDestinationSelected(int index) {
    setState(() {
      // Tapping Books while already on a shelf goes back to the hub — the
      // usual "tap the active tab to go up a level".
      if (index == 1 && _navIndex == 1) {
        _bookSource = null;
      }
      _navIndex = index;
    });
  }

  /// Confirms, then signs out.
  ///
  /// No navigation afterwards: AuthProvider flips to unauthenticated and
  /// AuthGate replaces this screen with the sign-in page.
  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to continue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.ctaBackground,
            ),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !mounted) return;

    await context.read<AuthProvider>().logout();

    if (!mounted) return;
    AppToast.success(context, 'You have been logged out.');
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

  void _markAllRead() {
    setState(() {
      _notifications = [
        for (final n in _notifications) n.copyWith(isRead: true),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      // Inner pages (a shelf, later an order) supply their own bar with a
      // back button and their own actions — the branded one would just cost a
      // row of height.
      appBar: _isInnerPage
          ? null
          : DashboardAppBar(
              section: _section,
              notificationCount: _unreadCount,
              onNotificationsPressed: _openNotifications,
              onLogoutPressed: _confirmLogout,
            ),
      body: SafeArea(top: false, child: _body),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: 'Books',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront_rounded),
            label: 'Shop',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Orders',
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

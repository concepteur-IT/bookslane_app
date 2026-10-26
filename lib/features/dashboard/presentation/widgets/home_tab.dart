import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bookslane_app/core/network/api_failure.dart';
import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:bookslane_app/features/dashboard/domain/dashboard_summary.dart';
import 'package:bookslane_app/features/dashboard/presentation/widgets/greeting_banner.dart';
import 'package:bookslane_app/features/dashboard/presentation/widgets/stat_card.dart';

// "Today's visits" is switched off for now: it showed placeholder data and
// there is no visits API yet. visit_card.dart and section_header.dart are kept
// for when it comes back.

/// The Home tab: a greeting and today's headline figures, all from
/// `GET /v1/dashboard/summary`. Just the body — the app bar and bottom bar
/// belong to the shell.
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<_HomeController>(
      create: (_) =>
          _HomeController(context.read<DashboardRepository>())..load(),
      child: const _HomeView(),
    );
  }
}

class _HomeController extends ChangeNotifier {
  _HomeController(this._repository);

  final DashboardRepository _repository;

  DashboardSummary? summary;
  String? error;
  bool isLoading = false;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      summary = await _repository.fetchSummary();
    } on ApiFailure catch (failure) {
      error = failure.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    final home = context.watch<_HomeController>();
    final summary = home.summary;

    // Until the summary arrives (or if it can't), fall back to the signed-in
    // user's name and a neutral hello — never a wrong "Good morning".
    final fallbackName = context.select<AuthProvider, String>(
      (auth) => auth.user?.displayName ?? 'there',
    );
    final name = (summary?.name.isNotEmpty ?? false)
        ? summary!.name
        : fallbackName;

    return RefreshIndicator(
      onRefresh: home.load,
      // A scroll view whose single child fills the screen and centres its
      // content: vertically in the middle when it fits, scrolling (and
      // pull-to-refresh) when it doesn't.
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GreetingBanner(
                    greeting: '${summary?.greeting ?? 'Welcome'}, $name',
                    headline: summary == null
                        ? (home.isLoading
                              ? 'Loading your day…'
                              : 'Welcome back')
                        : _ordersHeadline(summary.ordersToday),
                    note: summary == null
                        ? ''
                        : '${_money(summary.revenueToday)} revenue today',
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  if (summary == null && home.error != null)
                    _ErrorCard(message: home.error!, onRetry: home.load)
                  else
                    _StatsRow(summary: summary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _ordersHeadline(int orders) => switch (orders) {
    0 => 'No orders yet today',
    1 => '1 order today',
    _ => '$orders orders today',
  };
}

/// The three headline figures. Equal widths, so they stay aligned whatever the
/// numbers are. `null` summary (still loading) shows dashes.
class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.summary});

  final DashboardSummary? summary;

  @override
  Widget build(BuildContext context) {
    final s = summary;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: StatCard(
              icon: Icons.shopping_bag_outlined,
              iconColor: AppColors.brandPrimary,
              value: s == null ? '—' : _count(s.ordersToday),
              label: 'Orders today',
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: StatCard(
              icon: Icons.inventory_2_outlined,
              iconColor: AppColors.ctaBackground,
              value: s == null ? '—' : _count(s.totalProducts),
              label: 'Products',
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: StatCard(
              icon: Icons.account_balance_wallet_outlined,
              iconColor: AppColors.warningText,
              value: s == null ? '—' : _compactMoney(s.revenueToday),
              label: 'Revenue today',
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceBackground,
        borderRadius: AppRadius.lgAll,
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(onPressed: onRetry, child: const Text('TRY AGAIN')),
        ],
      ),
    );
  }
}

/// 1248 → "1,248".
String _count(int value) {
  final digits = value.toString();
  final out = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return out.toString();
}

/// "₹530.70" for the banner line.
String _money(double value) => '₹${value.toStringAsFixed(2)}';

/// Fits a stat card: ₹530.7 · ₹12,450 · ₹1.2L · ₹3.4Cr.
String _compactMoney(double value) {
  String trim(double v) =>
      v.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');

  if (value >= 10000000) return '₹${trim(value / 10000000)}Cr';
  if (value >= 100000) return '₹${trim(value / 100000)}L';
  if (value >= 1000) return '₹${_count(value.round())}';
  return '₹${trim(value)}';
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/core/widgets/widgets.dart';
import 'package:bookslane_app/features/orders/domain/entities/order_record.dart';
import 'package:bookslane_app/features/orders/domain/repositories/orders_repository.dart';
import 'package:bookslane_app/features/orders/presentation/providers/orders_list_provider.dart';
import 'package:bookslane_app/features/orders/presentation/widgets/order_card.dart';
import 'package:bookslane_app/features/orders/presentation/widgets/order_details_dialog.dart';
import 'package:bookslane_app/features/orders/presentation/widgets/order_filter_panel.dart';

/// The Orders tab: the signed-in account's orders, newest first, with search
/// (order number or book title), filters (status, date, total, discount),
/// sort and paging — all on the server (`GET /v1/orders`). The branded app bar
/// and bottom bar come from DashboardPage, so this is just the body under
/// them.
class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<OrdersListProvider>(
      create: (_) =>
          OrdersListProvider(context.read<OrdersRepository>())..load(),
      child: const _OrdersView(),
    );
  }
}

class _OrdersView extends StatefulWidget {
  const _OrdersView();

  @override
  State<_OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<_OrdersView> {
  /// The filter and sort overlays drop down from under this row.
  final GlobalKey _toolbarKey = GlobalKey();

  Future<void> _openFilters() async {
    final provider = context.read<OrdersListProvider>();
    final filters = await showAnchoredPanel<OrderFilters>(
      context: context,
      anchor: _toolbarKey,
      builder: (_) => OrderFilterPanel(
        initial: provider.filters,
        loadFacets: provider.loadFacets,
      ),
    );
    if (filters != null) await provider.setFilters(filters);
  }

  Future<void> _openSort() async {
    final provider = context.read<OrdersListProvider>();
    final sort = await showAnchoredPanel<OrderSort>(
      context: context,
      anchor: _toolbarKey,
      maxWidth: 280,
      builder: (_) => SortPanel<OrderSort>(
        options: OrderSort.values,
        selected: provider.sort,
        initial: OrderSort.initial,
        labelOf: (sort) => sort.label,
      ),
    );
    if (sort != null) await provider.setSort(sort);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrdersListProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            0,
          ),
          child: ListToolbar(
            key: _toolbarKey,
            searchHint: 'Search order or book',
            filterCount: provider.filters.activeCount,
            isSorted: provider.sort != OrderSort.initial,
            onSearchChanged: provider.setSearch,
            onFilterPressed: _openFilters,
            onSortPressed: _openSort,
          ),
        ),
        Expanded(child: _Body(provider: provider)),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.provider});

  final OrdersListProvider provider;

  @override
  Widget build(BuildContext context) {
    // First load only: later refetches keep the list on screen and dim it.
    if (provider.isLoading && provider.orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.status == OrdersStatus.error) {
      return _Message(
        icon: Icons.cloud_off_rounded,
        title: provider.errorMessage ?? 'Something went wrong.',
        actionLabel: 'TRY AGAIN',
        onAction: provider.refresh,
      );
    }

    if (provider.orders.isEmpty) {
      return provider.isNarrowed
          ? _Message(
              icon: Icons.search_off_rounded,
              title: 'No orders match that.',
              subtitle: 'Try a different search or filter.',
              actionLabel: provider.filters.isInitial ? null : 'CLEAR FILTERS',
              onAction: () => provider.setFilters(OrderFilters.initial),
            )
          : const _Message(
              icon: Icons.receipt_long_outlined,
              title: 'No orders yet.',
              subtitle: 'Orders you place from the Shop appear here.',
            );
    }

    return Opacity(
      opacity: provider.isLoading ? 0.5 : 1,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.xl,
        ),
        itemCount: provider.orders.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index == provider.orders.length) {
            return PaginationBar(
              shown: provider.orders.length,
              total: provider.total,
              page: provider.currentPage,
              pageCount: provider.totalPages,
              onPrevious: provider.hasPrevious ? provider.previousPage : null,
              onNext: provider.hasNext ? provider.nextPage : null,
            );
          }
          final order = provider.orders[index];
          return OrderCard(
            order: order,
            onTap: () => OrderDetailsDialog.show(context, order),
          );
        },
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppSizes.logoTile, color: AppColors.disabledText),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.titleLarge,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

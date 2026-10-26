import 'package:flutter/material.dart';

import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/core/widgets/widgets.dart';
import 'package:bookslane_app/features/orders/domain/entities/order_record.dart';
import 'package:bookslane_app/features/orders/presentation/order_format.dart';

/// Every detail of one order: the header, each line with its price and
/// quantity, and the money breakdown. The list row already carries all of it,
/// so there is no second request. Laid out like the book dialogs.
class OrderDetailsDialog extends StatelessWidget {
  const OrderDetailsDialog({super.key, required this.order});

  final OrderRecord order;

  static Future<void> show(BuildContext context, OrderRecord order) {
    return showDialog<void>(
      context: context,
      builder: (_) => OrderDetailsDialog(order: order),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Order Details',
                        textAlign: TextAlign.center,
                        style: AppTypography.headlineMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Center(
                        child: StatusPill(
                          label: order.statusLabel,
                          color: statusColor(order.status),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const Divider(),
                      const SizedBox(height: AppSpacing.xs),

                      _InfoRow(label: 'Order Id', value: order.orderNumber),
                      _InfoRow(
                        label: 'Placed',
                        value: formatDayTime(order.placedAt),
                      ),
                      _InfoRow(
                        label: 'Payment',
                        value: order.paymentLabel ?? '—',
                      ),
                      _InfoRow(
                        label: 'Items',
                        value:
                            '${order.itemCount} '
                            '(${order.items.length} '
                            '${order.items.length == 1 ? 'title' : 'titles'})',
                      ),

                      if (order.customer != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text('Customer', style: AppTypography.titleMedium),
                        const SizedBox(height: AppSpacing.xxs),
                        _InfoRow(
                          label: 'Name',
                          value: _orDash(order.customer!.name),
                        ),
                        _InfoRow(
                          label: 'Mobile',
                          value: _orDash(order.customer!.mobile),
                        ),
                        _InfoRow(
                          label: 'Email',
                          value: _orDash(order.customer!.email),
                        ),
                        _InfoRow(
                          label: 'Address',
                          value: _orDash(order.customer!.address),
                        ),
                      ],

                      const SizedBox(height: AppSpacing.md),
                      Text('Books', style: AppTypography.titleMedium),
                      const SizedBox(height: AppSpacing.xxs),
                      for (final line in order.items) _LineRow(line: line),

                      const Divider(height: AppSpacing.lg),

                      _MoneyRow('Subtotal', formatMoney(order.subtotal)),
                      if (order.hasDiscount)
                        _MoneyRow(
                          'Discount',
                          '-${formatMoney(order.discountAmount)}',
                          color: AppColors.successText,
                        ),
                      const SizedBox(height: AppSpacing.xxs),
                      _MoneyRow(
                        'Total',
                        formatMoney(order.total),
                        emphasised: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _orDash(String value) => value.isNotEmpty ? value : '—';

class _LineRow extends StatelessWidget {
  const _LineRow({required this.line});

  final OrderLine line;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.title.isEmpty ? line.bookId : line.title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.headingText,
                  ),
                ),
                Text(
                  '${line.quantity} × ${formatMoney(line.unitPrice)}'
                  '${line.isStore == null
                      ? ''
                      : line.isStore!
                      ? ' · Store'
                      : ' · Publishing'}',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(formatMoney(line.lineTotal), style: AppTypography.titleMedium),
        ],
      ),
    );
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow(
    this.label,
    this.value, {
    this.color,
    this.emphasised = false,
  });

  final String label;
  final String value;
  final Color? color;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    final style = emphasised
        ? AppTypography.titleLarge
        : AppTypography.bodyLarge;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: style.copyWith(color: color)),
          ),
          Text(
            value,
            style: style.copyWith(
              color: color ?? (emphasised ? AppColors.ctaBackground : null),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
          ),
          Expanded(child: Text(value, style: AppTypography.bodyMedium)),
        ],
      ),
    );
  }
}

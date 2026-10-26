import 'package:flutter/material.dart';

import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/core/widgets/widgets.dart';
import 'package:bookslane_app/features/orders/domain/entities/order_record.dart';
import 'package:bookslane_app/features/orders/presentation/order_format.dart';

/// One order in the list: number and status, when it was placed, a preview of
/// what was bought, and the money. Tap anywhere (or the eye) for every line.
class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, required this.onTap});

  final OrderRecord order;
  final VoidCallback onTap;

  /// Lines shown before "+N more".
  static const int _previewLines = 2;

  @override
  Widget build(BuildContext context) {
    final preview = order.items.take(_previewLines).toList();
    final more = order.items.length - preview.length;

    return Material(
      color: AppColors.surfaceBackground,
      borderRadius: AppRadius.lgAll,
      elevation: 0,
      child: InkWell(
        borderRadius: AppRadius.lgAll,
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: AppRadius.lgAll,
            boxShadow: AppShadows.card,
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.orderNumber,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.headingText,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  StatusPill(
                    label: order.statusLabel,
                    color: statusColor(order.status),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(formatDayTime(order.placedAt), style: AppTypography.caption),

              const Divider(height: AppSpacing.lg),

              for (final line in preview)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          line.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMedium,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text('× ${line.quantity}', style: AppTypography.caption),
                    ],
                  ),
                ),
              if (more > 0)
                Text(
                  '+ $more more ${more == 1 ? 'book' : 'books'}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.brandPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),

              const SizedBox(height: AppSpacing.sm),

              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${order.itemCount} ${order.itemCount == 1 ? 'item' : 'items'}',
                          style: AppTypography.caption,
                        ),
                        if (order.hasDiscount)
                          Text(
                            '${formatMoney(order.discountAmount)} discount',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.successText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (order.hasDiscount)
                        Text(
                          formatMoney(order.subtotal),
                          style: AppTypography.caption.copyWith(
                            decoration: TextDecoration.lineThrough,
                            decorationColor: AppColors.mutedText,
                          ),
                        ),
                      Text(
                        formatMoney(order.total),
                        style: AppTypography.titleLarge.copyWith(
                          color: AppColors.ctaBackground,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

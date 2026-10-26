import 'package:flutter/material.dart';

import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/core/widgets/widgets.dart';
import 'package:bookslane_app/features/orders/domain/entities/order.dart';

/// The thank-you screen after an order is placed. Continue goes back to the
/// signed-in shell, which is still on the Shop tab.
class OrderSuccessPage extends StatelessWidget {
  const OrderSuccessPage({super.key, required this.order});

  final PlacedOrder order;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // The order is done; back must not return to a checkout that no longer
      // has a cart.
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.screenBackground,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 88,
                  color: AppColors.successText,
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Thank you!', style: AppTypography.headlineMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Your order has been placed.',
                  style: AppTypography.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Order ${order.orderNumber}',
                  style: AppTypography.titleMedium,
                ),
                Text(
                  'Total ₹${order.total.toStringAsFixed(2)}',
                  style: AppTypography.caption,
                ),
                const SizedBox(height: AppSpacing.xl),
                CtaButton(
                  label: 'Continue shopping',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

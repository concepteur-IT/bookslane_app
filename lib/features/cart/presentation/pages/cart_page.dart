import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/core/widgets/widgets.dart';
import 'package:bookslane_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:bookslane_app/features/cart/presentation/widgets/cart_book_row.dart';
import 'package:bookslane_app/features/orders/domain/repositories/orders_repository.dart';
import 'package:bookslane_app/features/orders/presentation/pages/checkout_page.dart';
import 'package:bookslane_app/features/orders/presentation/providers/checkout_provider.dart';

/// The cart: every book added from the Shop, laid out like the Shop's list
/// rows but with only title, price and a quantity stepper. There is no
/// checkout yet, so the footer just totals what is in the cart.
class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final lines = cart.lines;

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: InnerPageAppBar(
        title: 'Cart',
        subtitle: cart.isEmpty
            ? null
            : '${cart.count} ${cart.count == 1 ? 'item' : 'items'}',
        onBack: () => Navigator.of(context).pop(),
        actions: [
          if (!cart.isEmpty)
            TextButton(onPressed: cart.clear, child: const Text('Clear')),
        ],
      ),
      body: SafeArea(
        child: cart.isEmpty
            ? Center(
                child: Text(
                  'Your cart is empty.',
                  style: AppTypography.caption,
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: lines.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (_, i) => CartBookRow(
                        line: lines[i],
                        onIncrement: () {
                          if (cart.add(lines[i].book) ==
                              CartAddResult.atStockLimit) {
                            AppToast.info(
                              context,
                              'Only ${lines[i].book.stock} in stock.',
                            );
                          }
                        },
                        onDecrement: () => cart.decrement(lines[i].book),
                        onRemove: () => cart.remove(lines[i].book),
                      ),
                    ),
                  ),
                  _TotalBar(
                    total: cart.total,
                    onCheckout: () => _checkout(context),
                  ),
                ],
              ),
      ),
    );
  }
}

void _checkout(BuildContext context) {
  final cart = context.read<CartProvider>();
  final repository = context.read<OrdersRepository>();

  Navigator.of(context).push(
    MaterialPageRoute<void>(
      // A fresh CheckoutProvider per visit, so a coupon never outlives the
      // cart it was priced against.
      builder: (_) => ChangeNotifierProvider<CheckoutProvider>(
        create: (_) => CheckoutProvider(repository: repository, cart: cart),
        child: const CheckoutPage(),
      ),
    ),
  );
}

class _TotalBar extends StatelessWidget {
  const _TotalBar({required this.total, required this.onCheckout});

  final double total;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceBackground,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text('Subtotal', style: AppTypography.titleMedium),
              const Spacer(),
              Text(
                '₹${total.toStringAsFixed(2)}',
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.ctaBackground,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          CtaButton(label: 'Checkout', onPressed: onCheckout),
        ],
      ),
    );
  }
}

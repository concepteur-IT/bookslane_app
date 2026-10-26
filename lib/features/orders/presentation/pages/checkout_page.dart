import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/core/widgets/widgets.dart';
import 'package:bookslane_app/features/orders/presentation/pages/customer_details_page.dart';
import 'package:bookslane_app/features/orders/presentation/providers/checkout_provider.dart';

/// Checkout: the books being bought, a discount field, the totals, and
/// Continue — which asks for the customer's details.
///
/// Expects a [CheckoutProvider] above it.
class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final TextEditingController _discountController = TextEditingController();

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  void _continue() {
    final checkout = context.read<CheckoutProvider>();

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider<CheckoutProvider>.value(
          value: checkout,
          child: const CustomerDetailsPage(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final checkout = context.watch<CheckoutProvider>();
    final lines = checkout.cart.lines;

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: InnerPageAppBar(
        title: 'Checkout',
        subtitle:
            '${checkout.cart.count} '
            '${checkout.cart.count == 1 ? 'item' : 'items'}',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  _Card(
                    child: Column(
                      children: [
                        for (var i = 0; i < lines.length; i++) ...[
                          if (i > 0) const Divider(height: AppSpacing.md),
                          _SummaryLine(
                            title: lines[i].book.title,
                            detail:
                                '${lines[i].quantity} × ${lines[i].book.formattedPrice}',
                            amount: lines[i].book.price * lines[i].quantity,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _DiscountCard(controller: _discountController),
                  const SizedBox(height: AppSpacing.md),
                  _Card(
                    child: Column(
                      children: [
                        _TotalRow('Subtotal', checkout.subtotal),
                        if (checkout.hasDiscount) ...[
                          const SizedBox(height: AppSpacing.xs),
                          _TotalRow(
                            'Discount',
                            -checkout.discount,
                            color: AppColors.successText,
                          ),
                        ],
                        const Divider(height: AppSpacing.lg),
                        _TotalRow('Total', checkout.total, emphasised: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              color: AppColors.surfaceBackground,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: CtaButton(
                label: 'Continue',
                onPressed: lines.isEmpty ? null : _continue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceBackground,
        borderRadius: AppRadius.lgAll,
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: child,
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.title,
    required this.detail,
    required this.amount,
  });

  final String title;
  final String detail;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.headingText,
                ),
              ),
              Text(detail, style: AppTypography.caption),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text('₹${amount.toStringAsFixed(2)}', style: AppTypography.titleMedium),
      ],
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow(
    this.label,
    this.amount, {
    this.color,
    this.emphasised = false,
  });

  final String label;
  final double amount;
  final Color? color;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    final style = emphasised
        ? AppTypography.titleLarge
        : AppTypography.bodyLarge;
    final sign = amount < 0 ? '-' : '';

    return Row(
      children: [
        Expanded(
          child: Text(label, style: style.copyWith(color: color)),
        ),
        Text(
          '$sign₹${amount.abs().toStringAsFixed(2)}',
          style: style.copyWith(
            color: color ?? (emphasised ? AppColors.ctaBackground : null),
          ),
        ),
      ],
    );
  }
}

/// A rupee field and Apply; once applied, a chip with Remove instead. The
/// seller types the amount — there are no codes.
class _DiscountCard extends StatelessWidget {
  const _DiscountCard({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final checkout = context.watch<CheckoutProvider>();

    return _Card(
      child: checkout.hasDiscount
          ? Row(
              children: [
                const Icon(
                  Icons.local_offer_rounded,
                  color: AppColors.successText,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '₹${checkout.discount.toStringAsFixed(2)} discount applied',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.successText,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    controller.clear();
                    checkout.removeDiscount();
                  },
                  child: const Text('Remove'),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: controller,
                        hintText: 'Discount amount (₹)',
                        prefixIcon: Icons.currency_rupee_rounded,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.done,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                        onFieldSubmitted: checkout.applyDiscount,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    SizedBox(
                      width: 96,
                      child: CtaButton(
                        label: 'Apply',
                        onPressed: () =>
                            checkout.applyDiscount(controller.text),
                      ),
                    ),
                  ],
                ),
                if (checkout.discountError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      checkout.discountError!,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.errorText,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

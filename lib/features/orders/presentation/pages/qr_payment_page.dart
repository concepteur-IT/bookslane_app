import 'package:flutter/material.dart';

import 'package:bookslane_app/core/config/app_assets.dart';
import 'package:bookslane_app/core/network/api_failure.dart';
import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/core/widgets/widgets.dart';

/// How the customer left the QR screen. A successful Done pops with [done];
/// the page that opened it decides what each choice means.
enum QrChoice { done, cancel, clear }

/// The payment screen: a static QR image (the same code for every order — it
/// is not generated per order), the amount to pay, and Done / Cancel / Clear.
///
/// * **Done** runs [onDone] (places the order); only if that succeeds does the
///   page pop with [QrChoice.done]. A failure toasts and stays put.
/// * **Cancel** goes back to checkout.
/// * **Clear** abandons the order and the cart.
class QrPaymentPage extends StatefulWidget {
  const QrPaymentPage({super.key, required this.amount, required this.onDone});

  final double amount;
  final Future<Object?> Function() onDone;

  @override
  State<QrPaymentPage> createState() => _QrPaymentPageState();
}

class _QrPaymentPageState extends State<QrPaymentPage> {
  bool _isPlacing = false;

  Future<void> _done() async {
    setState(() => _isPlacing = true);
    try {
      await widget.onDone();
      if (mounted) Navigator.of(context).pop(QrChoice.done);
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() => _isPlacing = false);
      AppToast.error(context, failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Not while the order is being placed: leaving would orphan the request.
      canPop: !_isPlacing,
      child: Scaffold(
        backgroundColor: AppColors.screenBackground,
        appBar: InnerPageAppBar(
          title: 'Scan to pay',
          onBack: _isPlacing
              ? null
              : () => Navigator.of(context).pop(QrChoice.cancel),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Center(
                child: Text(
                  '₹${widget.amount.toStringAsFixed(2)}',
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.ctaBackground,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Center(
                child: Text(
                  'Scan the code with any UPI app, pay, then tap Done.',
                  textAlign: TextAlign.center,
                  style: AppTypography.caption,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: Container(
                  width: 280,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBackground,
                    borderRadius: AppRadius.lgAll,
                    boxShadow: AppShadows.card,
                  ),
                  child: Image.asset(
                    AppAssets.paymentQr,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const SizedBox(
                      height: 248,
                      child: Center(child: Text('QR code unavailable')),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              CtaButton(
                label: 'Done',
                icon: Icons.check_rounded,
                isLoading: _isPlacing,
                onPressed: _done,
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: _isPlacing
                    ? null
                    : () => Navigator.of(context).pop(QrChoice.cancel),
                child: const Text('Cancel'),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextButton(
                onPressed: _isPlacing
                    ? null
                    : () => Navigator.of(context).pop(QrChoice.clear),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.ctaBackground,
                ),
                child: const Text('Clear'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

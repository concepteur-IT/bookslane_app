import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bookslane_app/core/network/api_failure.dart';
import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/core/widgets/widgets.dart';
import 'package:bookslane_app/features/orders/domain/entities/order.dart';
import 'package:bookslane_app/features/orders/presentation/pages/order_success_page.dart';
import 'package:bookslane_app/features/orders/presentation/pages/qr_payment_page.dart';
import 'package:bookslane_app/features/orders/presentation/providers/checkout_provider.dart';

/// Who the order is for: name and mobile (required), email and address
/// (optional). **Place order** saves the customer, then opens the QR payment
/// screen; what happens there decides the rest:
///
/// * Done — the order is placed, thank-you screen.
/// * Cancel — back to checkout (the details are kept for next time).
/// * Clear — the cart is emptied and the Shop shows "Order cancelled".
///
/// Expects a [CheckoutProvider] above it.
class CustomerDetailsPage extends StatefulWidget {
  const CustomerDetailsPage({super.key});

  @override
  State<CustomerDetailsPage> createState() => _CustomerDetailsPageState();
}

class _CustomerDetailsPageState extends State<CustomerDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _mobile;
  late final TextEditingController _email;
  late final TextEditingController _address;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Prefilled when coming back from the QR screen's Cancel.
    final saved = context.read<CheckoutProvider>().customer;
    _name = TextEditingController(text: saved?.name);
    _mobile = TextEditingController(text: saved?.mobile);
    _email = TextEditingController(text: saved?.email);
    _address = TextEditingController(text: saved?.address);
  }

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    _email.dispose();
    _address.dispose();
    super.dispose();
  }

  /// Digits with an optional leading + once separators are dropped — the
  /// same rule as the API (7–15 digits).
  static final RegExp _mobilePattern = RegExp(r'^\+?\d{7,15}$');
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  String _cleanMobile(String raw) => raw.replaceAll(RegExp(r'[\s\-.()]'), '');

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final checkout = context.read<CheckoutProvider>();
    final navigator = Navigator.of(context);

    setState(() => _isSaving = true);
    try {
      await checkout.saveCustomer(
        CustomerDetails(
          name: _name.text.trim().replaceAll(RegExp(r'\s+'), ' '),
          mobile: _cleanMobile(_mobile.text),
          email: _email.text.trim(),
          address: _address.text.trim(),
        ),
      );
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppToast.error(context, failure.message);
      return;
    }
    if (!mounted) return;
    setState(() => _isSaving = false);

    final choice = await navigator.push<QrChoice>(
      MaterialPageRoute<QrChoice>(
        builder: (_) => QrPaymentPage(
          amount: checkout.total,
          // Runs on Done. Throwing keeps the user on the QR screen.
          onDone: checkout.placeOrder,
        ),
      ),
    );

    if (!mounted) return;

    switch (choice) {
      case QrChoice.done:
        // Thank-you replaces checkout and cart; Continue goes back to the Shop.
        await navigator.pushAndRemoveUntil(
          MaterialPageRoute<void>(
            builder: (_) => OrderSuccessPage(order: checkout.lastOrder!),
          ),
          (route) => route.isFirst,
        );
      case QrChoice.clear:
        checkout.cart.clear();
        navigator.popUntil((route) => route.isFirst);
        // The navigator's own context outlives these pages, and sits under
        // MaterialApp's ScaffoldMessenger, so the toast lands on the Shop.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (navigator.mounted) {
            AppToast.error(navigator.context, 'Order cancelled');
          }
        });
      case QrChoice.cancel || null:
        navigator.pop(); // Back to checkout.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: InnerPageAppBar(
        title: 'Customer details',
        onBack: _isSaving ? null : () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    const FieldLabel('Name', isRequired: true),
                    AppTextField(
                      controller: _name,
                      hintText: 'Customer name',
                      prefixIcon: Icons.person_outline_rounded,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      enabled: !_isSaving,
                      validator: (v) => (v ?? '').trim().isEmpty
                          ? 'Enter the customer’s name.'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.fieldGap),
                    const FieldLabel('Mobile no', isRequired: true),
                    AppTextField(
                      controller: _mobile,
                      hintText: 'Mobile number',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      enabled: !_isSaving,
                      validator: (v) {
                        final value = _cleanMobile(v ?? '');
                        if (value.isEmpty) return 'Enter a mobile number.';
                        return _mobilePattern.hasMatch(value)
                            ? null
                            : 'Enter a valid mobile number (7–15 digits).';
                      },
                    ),
                    const SizedBox(height: AppSpacing.fieldGap),
                    const FieldLabel('Email'),
                    AppTextField(
                      controller: _email,
                      hintText: 'Email (optional)',
                      prefixIcon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      enabled: !_isSaving,
                      validator: (v) {
                        final value = (v ?? '').trim();
                        if (value.isEmpty) return null;
                        return _emailPattern.hasMatch(value)
                            ? null
                            : 'Enter a valid email address.';
                      },
                    ),
                    const SizedBox(height: AppSpacing.fieldGap),
                    const FieldLabel('Address'),
                    AppTextField(
                      controller: _address,
                      hintText: 'Address (optional)',
                      prefixIcon: Icons.location_on_outlined,
                      maxLines: 3,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      enabled: !_isSaving,
                    ),
                  ],
                ),
              ),
            ),
            Container(
              color: AppColors.surfaceBackground,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: CtaButton(
                label: 'Place order',
                isLoading: _isSaving,
                onPressed: _placeOrder,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

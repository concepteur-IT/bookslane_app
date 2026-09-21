import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/core/widgets/widgets.dart';
import 'package:bookslane_app/features/products/domain/entities/product.dart';

/// The quantity-only edit form.
///
/// Shows the stock the product has now, takes an amount to add, and previews
/// the total that will be saved. The API replaces the stored quantity, so the
/// sum is what gets sent — the preview is there so that is never a surprise.
///
/// Returns the new total when the save succeeds, null when dismissed.
Future<int?> showUpdateQuantitySheet({
  required BuildContext context,
  required Product product,
  required Future<void> Function(int newQuantity) onSubmit,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      // Lifts the sheet above the keyboard.
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      // Scrollable, because what's left above the keyboard can be shorter
      // than the form — on a small phone, much shorter. Without this the
      // buttons are clipped and untappable (silently, in a release build).
      child: SingleChildScrollView(
        child: _UpdateQuantityForm(product: product, onSubmit: onSubmit),
      ),
    ),
  );
}

class _UpdateQuantityForm extends StatefulWidget {
  const _UpdateQuantityForm({required this.product, required this.onSubmit});

  final Product product;
  final Future<void> Function(int newQuantity) onSubmit;

  @override
  State<_UpdateQuantityForm> createState() => _UpdateQuantityFormState();
}

class _UpdateQuantityFormState extends State<_UpdateQuantityForm> {
  /// app-api caps quantity at 100000.
  static const int _maxQuantity = 100000;

  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  bool _isSaving = false;

  /// What the user typed, or null while it isn't a number yet.
  int? get _addition => int.tryParse(_controller.text.trim());

  /// Current stock plus the addition — the value that will be saved.
  int get _newTotal => widget.product.stock + (_addition ?? 0);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validate(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return 'Enter a quantity to add';

    final addition = int.tryParse(raw);
    if (addition == null) return 'Enter a whole number';

    final total = widget.product.stock + addition;
    if (total < 0) return 'That would leave stock below zero';
    if (total > _maxQuantity) return 'Total cannot exceed $_maxQuantity';
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_isSaving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final newTotal = _newTotal;
    setState(() => _isSaving = true);

    try {
      await widget.onSubmit(newTotal);
      if (!mounted) return;
      Navigator.of(context).pop(newTotal);
    } catch (_) {
      // Swallowed on purpose: the caller reports the failure, and the sheet
      // stays open with the typed number intact so it can be retried.
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xs,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Update quantity', style: AppTypography.headlineMedium),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                widget.product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMedium,
              ),

              const SizedBox(height: AppSpacing.lg),

              _ReadOnlyRow(
                label: 'CURRENT QUANTITY',
                value: '${widget.product.stock}',
              ),

              const SizedBox(height: AppSpacing.fieldGap),

              const FieldLabel('QUANTITY TO ADD'),
              const SizedBox(height: AppSpacing.labelGap),
              TextFormField(
                controller: _controller,
                autofocus: true,
                enabled: !_isSaving,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                ),
                // Digits and a leading minus: removing stock is the same form.
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
                ],
                textInputAction: TextInputAction.done,
                style: AppTypography.input,
                cursorColor: AppColors.inputCursor,
                validator: _validate,
                onChanged: (_) => setState(() {}),
                onFieldSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  hintText: 'e.g. 25',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(
                      left: AppSpacing.md,
                      right: AppSpacing.sm,
                    ),
                    child: Icon(Icons.add_rounded, size: AppSizes.iconMd),
                  ),
                  prefixIconConstraints: BoxConstraints(
                    minWidth: 0,
                    minHeight: 0,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              _TotalPreview(
                total: _newTotal,
                isValid: _addition != null && _newTotal >= 0,
              ),

              const SizedBox(height: AppSpacing.lg),

              CtaButton(
                label: 'SAVE QUANTITY',
                icon: Icons.check_rounded,
                isLoading: _isSaving,
                onPressed: _submit,
              ),

              const SizedBox(height: AppSpacing.xs),

              Center(
                child: TextButton(
                  onPressed: _isSaving
                      ? null
                      : () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.secondaryText,
                  ),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The current stock, shown as a field so it reads as part of the form but
/// clearly cannot be typed into.
class _ReadOnlyRow extends StatelessWidget {
  const _ReadOnlyRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label),
        const SizedBox(height: AppSpacing.labelGap),
        Container(
          width: double.infinity,
          decoration: AppDecorations.inputLookalike,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Text(
            value,
            style: AppTypography.input.copyWith(color: AppColors.secondaryText),
          ),
        ),
      ],
    );
  }
}

/// "New total" — what will actually be written.
class _TotalPreview extends StatelessWidget {
  const _TotalPreview({required this.total, required this.isValid});

  final int total;
  final bool isValid;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isValid
            ? AppColors.successBackground
            : AppColors.inputBackground,
        borderRadius: AppRadius.mdAll,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: AppSizes.iconMd,
            color: isValid ? AppColors.successText : AppColors.iconMuted,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text('New total', style: AppTypography.bodyLarge),
          const Spacer(),
          Text(
            isValid ? '$total' : '—',
            style: AppTypography.headlineMedium.copyWith(
              color: isValid ? AppColors.successText : AppColors.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}

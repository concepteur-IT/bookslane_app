import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/core/widgets/widgets.dart';
import 'package:bookslane_app/features/books/domain/entities/book.dart';
import 'package:bookslane_app/features/books/domain/entities/book_draft.dart';
import 'package:bookslane_app/features/books/domain/entities/book_form_options.dart';

/// The Add Book form.
///
/// Owns its own input state plus the in-flight request: once every field
/// validates it calls [onSubmit] with the finished [BookDraft] and awaits it,
/// showing a spinner on the button meanwhile. What [onSubmit] actually does —
/// the API call, updating a list, showing a toast on failure — is the
/// caller's business; the form only knows whether that future succeeded.
///
/// This is a `Column`, like [LoginForm] — it is taller than a phone screen, so
/// the caller is expected to put it inside a scroll view.
class AddBookForm extends StatefulWidget {
  const AddBookForm({
    super.key,
    this.source,
    this.onSubmit,
    this.isSubmitting = false,
  });

  /// Which shelf the book is being added to. Titles the form; the caller
  /// already knows which list it is inserting into, so it is not part of
  /// [BookDraft].
  final BookSource? source;

  /// Awaited once the form validates. Throwing (e.g. an `ApiFailure`) keeps
  /// the sheet open with every field intact — see `BookListPage._addBook` for
  /// where the toast on failure actually lives.
  final Future<void> Function(BookDraft draft)? onSubmit;

  /// While true the button shows a spinner and stops accepting taps — set
  /// from outside for a caller that wants to gate submission on something
  /// beyond the request [onSubmit] itself makes.
  final bool isSubmitting;

  /// Opens the form in a modal sheet over the current page.
  ///
  /// Resolves to the finished [BookDraft] once [onSubmit] succeeds, or null
  /// if the sheet was dismissed without submitting — so the caller can
  /// `await` it and act only on a real result:
  ///
  /// ```dart
  /// final draft = await AddBookForm.show(
  ///   context,
  ///   source: widget.source,
  ///   onSubmit: (draft) => booksRepository.createBook(draft),
  /// );
  /// if (draft == null) return;
  /// ```
  static Future<BookDraft?> show(
    BuildContext context, {
    required BookSource source,
    required Future<void> Function(BookDraft draft) onSubmit,
  }) {
    return showModalBottomSheet<BookDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      // The form is fourteen fields tall, so it needs most of the screen. The
      // sliver of list left behind it is what keeps it reading as a sheet over
      // this page rather than as a new screen — which matters here, because
      // the tab's bottom bar is deliberately never covered by a route.
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.92,
      ),
      builder: (sheetContext) => Padding(
        // Lifts the sheet above the keyboard.
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xs,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: AddBookForm(source: source, onSubmit: onSubmit),
        ),
      ),
    );
  }

  @override
  State<AddBookForm> createState() => _AddBookFormState();
}

class _AddBookFormState extends State<AddBookForm> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _skuController = TextEditingController();
  final _authorController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountController = TextEditingController();
  final _quantityController = TextEditingController();

  BookLanguage? _language;
  BookCategory? _category;
  BookBinding? _binding;
  DiscountType _discountType = DiscountType.flat;
  BookStatus _status = BookStatus.active;
  XFile? _image;

  /// True while [widget.onSubmit] is in flight — separate from
  /// [AddBookForm.isSubmitting], which the caller controls.
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _skuController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  String? _required(String? value, String field) {
    if ((value ?? '').trim().isEmpty) return 'Please enter $field';
    return null;
  }

  String? _validatePrice(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return 'Please enter a price';

    final price = double.tryParse(raw);
    if (price == null) return 'Enter a price like 249.00';
    if (price <= 0) return 'Price must be greater than zero';
    return null;
  }

  String? _validateQuantity(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return 'Please enter a quantity';

    final quantity = int.tryParse(raw);
    if (quantity == null) return 'Enter a whole number';
    if (quantity < 0) return 'Quantity cannot be negative';
    return null;
  }

  /// Discount is optional, but a discount that is present has to make sense
  /// against the price — a flat ₹500 off a ₹200 book would sell at a loss, and
  /// 120% off would sell below free.
  String? _validateDiscount(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return null;

    final discount = double.tryParse(raw);
    if (discount == null) return 'Enter an amount like 50';
    if (discount < 0) return 'Discount cannot be negative';

    if (_discountType == DiscountType.percentage && discount > 90) {
      return 'A percentage discount cannot exceed 90';
    }

    if (_discountType == DiscountType.flat) {
      final price = double.tryParse(_priceController.text.trim());
      if (price != null && discount > price) {
        return 'Discount cannot be more than the price';
      }
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // Submit
  // ---------------------------------------------------------------------------

  Future<void> _submit() async {
    // Dismiss the keyboard first so validation errors aren't hidden behind it.
    FocusScope.of(context).unfocus();

    if (widget.isSubmitting || _isSubmitting) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      AppToast.error(context, 'Please fix the highlighted fields.');
      return;
    }

    final draft = BookDraft(
      title: _titleController.text.trim(),
      subtitle: _subtitleController.text.trim(),
      sku: _skuController.text.trim(),
      author: _authorController.text.trim(),
      // Safe to force: validation above rejects an empty dropdown.
      language: _language!,
      category: _category!,
      description: _descriptionController.text.trim(),
      binding: _binding!,
      price: double.parse(_priceController.text.trim()),
      discount: double.tryParse(_discountController.text.trim()) ?? 0,
      discountType: _discountType,
      quantity: int.parse(_quantityController.text.trim()),
      status: _status,
      image: _image,
    );

    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit?.call(draft);
      if (!mounted) return;
      Navigator.of(context).pop(draft);
    } catch (_) {
      // Swallowed on purpose: the caller reports the failure (see
      // BookListPage._addBook), and the sheet stays open with every field
      // intact so the submission can be retried without retyping anything.
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.source == null
                ? 'Add a book'
                : 'Add to ${widget.source!.label}',
            style: AppTypography.displayMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Fields marked * are required.',
            style: AppTypography.bodyMedium,
          ),

          const SizedBox(height: AppSpacing.xl),

          // ---- Title ----------------------------------------------------
          const FieldLabel('Title', isRequired: true),
          const SizedBox(height: AppSpacing.labelGap),
          AppTextField(
            controller: _titleController,
            hintText: 'The Guide',
            prefixIcon: Icons.menu_book_outlined,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            validator: (value) => _required(value, 'a title'),
          ),

          const SizedBox(height: AppSpacing.fieldGap),

          // ---- Subtitle -------------------------------------------------
          const FieldLabel('Subtitle'),
          const SizedBox(height: AppSpacing.labelGap),
          AppTextField(
            controller: _subtitleController,
            hintText: 'Optional',
            prefixIcon: Icons.short_text_rounded,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
          ),

          const SizedBox(height: AppSpacing.fieldGap),

          // ---- Author ---------------------------------------------------
          const FieldLabel('Author', isRequired: true),
          const SizedBox(height: AppSpacing.labelGap),
          AppTextField(
            controller: _authorController,
            hintText: 'R. K. Narayan',
            prefixIcon: Icons.person_outline_rounded,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            validator: (value) => _required(value, 'an author'),
          ),

          const SizedBox(height: AppSpacing.fieldGap),

          // ---- SKU ------------------------------------------------------
          const FieldLabel('SKU', isRequired: true),
          const SizedBox(height: AppSpacing.labelGap),
          AppTextField(
            controller: _skuController,
            hintText: 'BL-0001',
            prefixIcon: Icons.qr_code_2_rounded,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.next,
            validator: (value) => _required(value, 'an SKU'),
          ),

          const SizedBox(height: AppSpacing.fieldGap),

          // ---- Language (dropdown) ---------------------------------------
          const FieldLabel('Language', isRequired: true),
          const SizedBox(height: AppSpacing.labelGap),
          AppDropdownField<BookLanguage>(
            value: _language,
            items: BookLanguage.values,
            labelBuilder: (language) => language.label,
            hintText: 'Select a language',
            prefixIcon: Icons.translate_rounded,
            onChanged: (language) => setState(() => _language = language),
            validator: (language) =>
                language == null ? 'Please select a language' : null,
          ),

          const SizedBox(height: AppSpacing.fieldGap),

          // ---- Category (dropdown) ---------------------------------------
          const FieldLabel('Category', isRequired: true),
          const SizedBox(height: AppSpacing.labelGap),
          AppDropdownField<BookCategory>(
            value: _category,
            items: BookCategory.values,
            labelBuilder: (category) => category.label,
            hintText: 'Select a category',
            prefixIcon: Icons.category_outlined,
            onChanged: (category) => setState(() => _category = category),
            validator: (category) =>
                category == null ? 'Please select a category' : null,
          ),

          const SizedBox(height: AppSpacing.fieldGap),

          // ---- Binding (dropdown) ----------------------------------------
          const FieldLabel('Binding', isRequired: true),
          const SizedBox(height: AppSpacing.labelGap),
          AppDropdownField<BookBinding>(
            value: _binding,
            items: BookBinding.values,
            labelBuilder: (binding) => binding.label,
            hintText: 'Select a binding',
            prefixIcon: Icons.auto_stories_outlined,
            onChanged: (binding) => setState(() => _binding = binding),
            validator: (binding) =>
                binding == null ? 'Please select a binding' : null,
          ),

          const SizedBox(height: AppSpacing.fieldGap),

          // ---- Description ------------------------------------------------
          const FieldLabel('Description'),
          const SizedBox(height: AppSpacing.labelGap),
          AppTextField(
            controller: _descriptionController,
            hintText: 'What is this book about?',
            prefixIcon: Icons.notes_rounded,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.newline,
          ),

          const SizedBox(height: AppSpacing.fieldGap),

          // ---- Price + quantity -------------------------------------------
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FieldLabel('Price', isRequired: true),
                    const SizedBox(height: AppSpacing.labelGap),
                    AppTextField(
                      controller: _priceController,
                      hintText: '249.00',
                      prefixIcon: Icons.currency_rupee_rounded,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'),
                        ),
                      ],
                      validator: _validatePrice,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FieldLabel('Quantity', isRequired: true),
                    const SizedBox(height: AppSpacing.labelGap),
                    AppTextField(
                      controller: _quantityController,
                      hintText: '10',
                      prefixIcon: Icons.inventory_2_outlined,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: _validateQuantity,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.fieldGap),

          // ---- Discount + discount type -----------------------------------
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FieldLabel('Discount'),
                    const SizedBox(height: AppSpacing.labelGap),
                    AppTextField(
                      controller: _discountController,
                      hintText: '0',
                      prefixIcon: Icons.local_offer_outlined,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.done,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'),
                        ),
                      ],
                      validator: _validateDiscount,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FieldLabel('Discount type'),
                    const SizedBox(height: AppSpacing.labelGap),
                    AppDropdownField<DiscountType>(
                      value: _discountType,
                      items: DiscountType.values,
                      labelBuilder: (type) => type.label,
                      hintText: 'Flat',
                      prefixIcon: Icons.percent_rounded,
                      onChanged: (type) {
                        if (type == null) return;
                        setState(() => _discountType = type);
                        // Switching flat ↔ percentage changes what counts as a
                        // valid discount, so re-check the amount beside it.
                        _formKey.currentState?.validate();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.fieldGap),

          // ---- Cover image ----------------------------------------------
          const FieldLabel('Cover image', isRequired: false),
          const SizedBox(height: AppSpacing.labelGap),
          ImagePickerField(
            value: _image,
            hintText: 'Choose a cover image',
            helperText: 'JPG or PNG. Downscaled to 1600px on upload.',
            onChanged: (file) => setState(() => _image = file),
            validator: (file) =>
                file == null ? 'Please add a cover image' : null,
          ),

          const SizedBox(height: AppSpacing.fieldGap),

          // ---- Status ------------------------------------------------------
          const FieldLabel('Status', isRequired: true),
          const SizedBox(height: AppSpacing.labelGap),
          AppDropdownField<BookStatus>(
            value: _status,
            items: BookStatus.values,
            labelBuilder: (status) => status.label,
            hintText: 'Active',
            prefixIcon: Icons.toggle_on_outlined,
            onChanged: (status) {
              if (status == null) return;
              setState(() => _status = status);
            },
          ),

          const SizedBox(height: AppSpacing.xl),

          CtaButton(
            label: 'ADD BOOK',
            icon: Icons.arrow_forward_rounded,
            isLoading: widget.isSubmitting || _isSubmitting,
            onPressed: _submit,
          ),

          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

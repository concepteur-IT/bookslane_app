import 'package:image_picker/image_picker.dart';

import 'package:bookslane_app/features/books/domain/entities/book_form_options.dart';

/// A validated Add Book form, on its way to the API.
///
/// The form hands this back once every field has passed validation, so the
/// caller never sees a half-filled draft and never has to re-parse a string
/// into a price.
class BookDraft {
  const BookDraft({
    required this.title,
    required this.sku,
    required this.author,
    required this.language,
    required this.category,
    required this.binding,
    required this.price,
    required this.quantity,
    required this.status,
    this.subtitle = '',
    this.description = '',
    this.discount = 0,
    this.discountType = DiscountType.flat,
    this.image,
  });

  final String title;
  final String subtitle;
  final String sku;
  final String author;
  final BookLanguage language;
  final BookCategory category;
  final String description;
  final BookBinding binding;

  /// Major units, as app-api sends and expects them — see [Product.price].
  final double price;

  final double discount;
  final DiscountType discountType;
  final int quantity;
  final BookStatus status;

  /// The picked cover. Null when the field was left empty.
  final XFile? image;

  /// Price after the discount, in major units. Never below zero.
  double get effectivePrice => switch (discountType) {
    DiscountType.flat => (price - discount).clamp(0, price),
    DiscountType.percentage => (price * (1 - discount / 100)).clamp(0, price),
  };

  /// The scalar fields, keyed the way the products table names them.
  ///
  /// [image] is deliberately absent: a file uploads as a multipart part
  /// alongside this map, not as a JSON value.
  Map<String, dynamic> toJson() => {
    'name': title,
    'subtitle': subtitle,
    'sku': sku,
    'author': author,
    'language': language.code,
    'category': category.id,
    'description': description,
    'binding': binding.value,
    'price': price,
    'discount': discount,
    'discount_type': discountType.value,
    'quantity': quantity,
    'is_active': status.value,
  };
}

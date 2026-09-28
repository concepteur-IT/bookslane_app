import 'package:bookslane_app/features/books/domain/entities/book_form_options.dart';

/// Full detail of one book — what `GET /v1/books/:id` returns. The list only
/// ever needs the trimmer [Book]; this is fetched separately, on demand, for
/// the Edit Book form and [BookDetailsDialog].
class BookDetail {
  const BookDetail({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.sku,
    required this.author,
    required this.description,
    required this.language,
    required this.category,
    required this.binding,
    required this.price,
    required this.discount,
    required this.discountType,
    required this.effectivePrice,
    required this.quantity,
    required this.status,
    this.imageUrl,
  });

  final String id;
  final String title;
  final String subtitle;
  final String sku;
  final String author;
  final String description;

  /// Null when app-api's stored value doesn't match any of the form's fixed
  /// options — legacy or free-form data. The form leaves that dropdown
  /// unset rather than guessing; see [BookLanguage.fromCode].
  final BookLanguage? language;
  final BookCategory? category;
  final BookBinding? binding;

  /// Major units, as the API sends them.
  final double price;

  final double discount;
  final DiscountType discountType;

  /// Price after the discount — app-api computes and stores this, rather
  /// than the client re-deriving it.
  final double effectivePrice;

  final int quantity;
  final BookStatus status;

  /// The current cover, or null when none was ever uploaded.
  final String? imageUrl;
}

import 'package:bookslane_app/features/books/domain/entities/book.dart';

/// Wire format of app-api's `BookDto` (`/v1/books`).
///
/// Coercion helpers mirror [ProductModel]'s, even though app-api's own books
/// endpoint sends proper JSON types throughout — keeping the same defensive
/// shape means one less thing to relearn when reading either model.
class BookModel {
  const BookModel({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.author,
    required this.price,
    required this.quantity,
    required this.isActive,
    required this.createdAt,
    this.imageUrl,
  });

  final int id;
  final String name;
  final String subtitle;
  final String author;

  /// Major units, as the API sends and expects them.
  final double price;

  final int quantity;
  final bool isActive;
  final DateTime createdAt;
  final String? imageUrl;

  factory BookModel.fromJson(Map<String, dynamic> json) {
    return BookModel(
      id: asInt(json['id']),
      name: asString(json['name']),
      subtitle: asString(json['subtitle']),
      author: asString(json['author']),
      price: asDouble(json['price']),
      quantity: asInt(json['quantity']),
      isActive: asInt(json['is_active']) == 1,
      createdAt: DateTime.tryParse(asString(json['created_at'])) ?? DateTime.now(),
      imageUrl: json['image_url'] is String && (json['image_url'] as String).isNotEmpty
          ? json['image_url'] as String
          : null,
    );
  }

  Book toEntity() => Book(
    id: id.toString(),
    title: name,
    // The card's second line: the subtitle when there is one, the author
    // otherwise — see the old BookListPage._bookFromDraft, which applied the
    // same fallback locally before this model existed.
    subtitle: subtitle.isNotEmpty ? subtitle : author,
    // Book keeps money in minor units; the API sends major units.
    price: (price * 100).round(),
    stock: quantity,
    isActive: isActive,
    addedOn: createdAt,
    imageUrl: imageUrl,
  );

  // ---------------------------------------------------------------------------
  // Coercion helpers — see ProductModel for the same pattern.
  // ---------------------------------------------------------------------------

  static int asInt(Object? value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double asDouble(Object? value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static String asString(Object? value) => value?.toString() ?? '';
}

/// Wire format of `BookListResponseDto` — `data` plus the `pagination` block.
/// See [ProductPageModel] for the same shape.
class BookPageModel {
  const BookPageModel({required this.items, required this.pagination});

  final List<BookModel> items;
  final Map<String, dynamic> pagination;

  factory BookPageModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! List) {
      throw const FormatException('Book list is missing "data".');
    }

    return BookPageModel(
      items: [
        for (final row in data)
          if (row is Map<String, dynamic>) BookModel.fromJson(row),
      ],
      pagination: json['pagination'] is Map<String, dynamic>
          ? json['pagination'] as Map<String, dynamic>
          : const {},
    );
  }

  BookPage toEntity() => BookPage(
    items: [for (final item in items) item.toEntity()],
    page: BookModel.asInt(pagination['page']),
    limit: BookModel.asInt(pagination['limit']),
    total: BookModel.asInt(pagination['total']),
    totalPages: BookModel.asInt(pagination['total_pages']),
    hasNext: pagination['has_next'] == true,
  );
}

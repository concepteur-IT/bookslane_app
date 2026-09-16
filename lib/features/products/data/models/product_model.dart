import 'package:bookslane_app/features/products/domain/entities/product.dart';

/// Wire format of app-api's `ProductDto`.
///
/// Tolerant on purpose: the legacy catalogue behind /v1/products returns some
/// numbers as strings, so every field goes through a coercion helper rather
/// than a blind cast. One odd row must not blank the whole page.
class ProductModel {
  const ProductModel({
    required this.id,
    required this.name,
    required this.author,
    required this.code,
    required this.price,
    required this.stock,
    required this.isActive,
    this.imageUrl,
    this.publisherName,
  });

  final int id;
  final String name;
  final String author;
  final String code;
  final double price;
  final int stock;
  final bool isActive;
  final String? imageUrl;
  final String? publisherName;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final publisher = json['publisher'];

    return ProductModel(
      id: asInt(json['id']),
      name: asString(json['name']),
      author: asString(json['author']),
      code: asString(json['code']),
      price: asDouble(json['price']),
      // `stock` is the field the quantity endpoint writes; stock_count and
      // total_stock are derived views of it.
      stock: asInt(json['stock']),
      // is_active is 0/1 on the wire, not a bool.
      isActive: asInt(json['is_active']) == 1,
      imageUrl: json['image_url'] is String && (json['image_url'] as String).isNotEmpty
          ? json['image_url'] as String
          : null,
      publisherName: publisher is Map<String, dynamic>
          ? asString(publisher['name'])
          : null,
    );
  }

  Product toEntity() => Product(
    id: id,
    name: name,
    author: author,
    code: code,
    price: price,
    stock: stock,
    isActive: isActive,
    imageUrl: imageUrl,
    publisherName: publisherName,
  );

  // ---------------------------------------------------------------------------
  // Coercion helpers — legacy rows send "12" as often as 12.
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

/// Wire format of `ProductListResponseDto` — `data` plus the `pagination`
/// block. The `publishers` list is ignored for now; the app shows every
/// imprint the caller owns in one list.
class ProductPageModel {
  const ProductPageModel({required this.items, required this.pagination});

  final List<ProductModel> items;
  final Map<String, dynamic> pagination;

  factory ProductPageModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! List) {
      throw const FormatException('Product list is missing "data".');
    }

    return ProductPageModel(
      items: [
        for (final row in data)
          if (row is Map<String, dynamic>) ProductModel.fromJson(row),
      ],
      pagination: json['pagination'] is Map<String, dynamic>
          ? json['pagination'] as Map<String, dynamic>
          : const {},
    );
  }

  ProductPage toEntity() {
    final total = ProductModel.asInt(pagination['total']);
    final limit = ProductModel.asInt(pagination['limit']);

    return ProductPage(
      items: [for (final item in items) item.toEntity()],
      page: ProductModel.asInt(pagination['page']),
      limit: limit,
      total: total,
      totalPages: ProductModel.asInt(pagination['total_pages']),
      hasNext: pagination['has_next'] == true,
    );
  }
}

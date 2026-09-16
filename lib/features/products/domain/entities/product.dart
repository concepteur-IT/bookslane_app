/// A product on the signed-in publisher's shelf.
///
/// A trimmed view of app-api's `ProductDto` — only the fields the app shows or
/// acts on. The wire format keeps the rest; see [ProductModel].
class Product {
  const Product({
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

  /// app-api's numeric id — the one in `PATCH /v1/products/:id/quantity`.
  final int id;

  final String name;
  final String author;
  final String code;

  /// Major units, as the API sends them.
  final double price;

  /// Units on hand. This is what the quantity form edits.
  final int stock;

  final bool isActive;
  final String? imageUrl;
  final String? publisherName;

  bool get isInStock => stock > 0;

  String get formattedPrice => '₹${price.toStringAsFixed(2)}';

  /// The subtitle under the name: author, falling back to the product code.
  String get subtitle => author.isNotEmpty ? author : code;

  Product copyWith({int? stock, bool? isActive}) => Product(
    id: id,
    name: name,
    author: author,
    code: code,
    price: price,
    stock: stock ?? this.stock,
    isActive: isActive ?? this.isActive,
    imageUrl: imageUrl,
    publisherName: publisherName,
  );
}

/// One page of [Product]s, mirroring app-api's `pagination` block.
class ProductPage {
  const ProductPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNext,
  });

  final List<Product> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNext;

  bool get isEmpty => items.isEmpty;
}

/// Which products the list asks for. Maps onto the `is_active` query param.
enum ProductFilter {
  all('All', null),
  active('Active', 1),
  inactive('Inactive', 0);

  const ProductFilter(this.label, this.isActiveValue);

  final String label;

  /// Null means "don't send the parameter at all".
  final int? isActiveValue;
}

/// Maps onto the `sort` + `order` query params, which app-api validates
/// against LEGACY_PRODUCT_SORTS.
enum ProductSort {
  newest('Newest', 'created_at', 'DESC'),
  name('Name', 'name', 'ASC'),
  quantity('Qty', 'stock', 'DESC'),
  price('Price', 'price', 'DESC');

  const ProductSort(this.label, this.field, this.order);

  final String label;
  final String field;
  final String order;
}

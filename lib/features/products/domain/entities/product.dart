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
    this.isbn = '',
    this.language = '',
    this.binding = '',
    this.pageCount = 0,
    this.publishYear,
    this.offeredPrice = 0,
    this.description = '',
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

  // Shown only in the details dialog. Legacy rows often leave these blank
  // or zero, so each is optional and the dialog prints a dash instead.
  final String isbn;
  final String language;
  final String binding;
  final int pageCount;
  final int? publishYear;

  /// The selling price in major units, when it differs from [price] (the
  /// MRP). Zero when thinkerslane has none set.
  final double offeredPrice;

  /// Plain text — [ProductModel] strips the HTML the legacy CMS stores.
  final String description;

  /// Whether [offeredPrice] is a real discount worth showing.
  bool get hasOfferedPrice => offeredPrice > 0 && offeredPrice < price;

  bool get isInStock => stock > 0;

  String get formattedPrice => '₹${price.toStringAsFixed(2)}';

  String get formattedOfferedPrice => '₹${offeredPrice.toStringAsFixed(2)}';

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
    isbn: isbn,
    language: language,
    binding: binding,
    pageCount: pageCount,
    publishYear: publishYear,
    offeredPrice: offeredPrice,
    description: description,
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

/// A category the caller's products are filed under — one of the options
/// from `GET /v1/products/categories`.
class ProductCategory {
  const ProductCategory({
    required this.id,
    required this.name,
    this.productCount = 0,
  });

  /// thinkerslane's tl_categories id — what `category_id` filters on.
  final int id;
  final String name;
  final int productCount;

  @override
  bool operator ==(Object other) => other is ProductCategory && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Which products the My Publishings list asks `/v1/products` for — the same
/// shape as the My Store filters. Every field maps onto one query param, so
/// filtering happens on the server.
class ProductFilters {
  const ProductFilters({
    this.isActive,
    this.inStockOnly = false,
    this.category,
  });

  /// What the list opens with, and what Reset goes back to: everything.
  static const ProductFilters initial = ProductFilters();

  /// `is_active`: true = Active only, false = Inactive only, null = either.
  final bool? isActive;

  /// `in_stock=1` when set.
  final bool inStockOnly;

  /// `category_id` — app-api takes a single one.
  final ProductCategory? category;

  /// How many filters differ from [initial] — the badge on the filter button.
  int get activeCount =>
      (isActive != null ? 1 : 0) +
      (inStockOnly ? 1 : 0) +
      (category != null ? 1 : 0);

  bool get isInitial => activeCount == 0;

  ProductFilters copyWith({
    bool? isActive,
    bool clearIsActive = false,
    bool? inStockOnly,
    ProductCategory? category,
    bool clearCategory = false,
  }) => ProductFilters(
    isActive: clearIsActive ? null : isActive ?? this.isActive,
    inStockOnly: inStockOnly ?? this.inStockOnly,
    category: clearCategory ? null : category ?? this.category,
  );
}

/// Maps onto the `sort` + `order` query params, which app-api validates
/// against LEGACY_PRODUCT_SORTS. The Shop's orders, less Featured.
enum ProductSort {
  newest('Newest', 'created_at', 'DESC'),
  oldest('Oldest', 'created_at', 'ASC'),
  priceLow('Price: low to high', 'price', 'ASC'),
  priceHigh('Price: high to low', 'price', 'DESC'),
  title('Title: A to Z', 'name', 'ASC'),
  titleDesc('Title: Z to A', 'name', 'DESC');

  const ProductSort(this.label, this.field, this.order);

  /// What Clear goes back to.
  static const ProductSort initial = ProductSort.newest;

  final String label;
  final String field;
  final String order;
}

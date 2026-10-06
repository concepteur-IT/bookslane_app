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

/// Which shelf a list is showing.
///
/// The two are the same screen with different data behind them, which is why
/// [BookListPage] takes this rather than existing twice.
enum BookSource {
  store('My Store', 'Books you sell'),
  publishings('My Publishings', 'Books you publish');

  const BookSource(this.label, this.description);

  final String label;
  final String description;
}

/// A book on one of those shelves.
class Book {
  const Book({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.stock,
    required this.isActive,
    required this.addedOn,
    this.imageUrl,
  });

  final String id;
  final String title;
  final String subtitle;

  /// Minor units (cents), so money never touches a double.
  final int price;

  final int stock;
  final bool isActive;

  /// Drives the "Newest" sort.
  final DateTime addedOn;

  /// Absolute cover URL, or null when there is none. A book has one once a
  /// cover was uploaded and app-api has a public storage URL configured.
  final String? imageUrl;

  bool get isInStock => stock > 0;

  String get formattedPrice => '₹${(price / 100).toStringAsFixed(2)}';

  Book copyWith({bool? isActive}) => Book(
    id: id,
    title: title,
    subtitle: subtitle,
    price: price,
    stock: stock,
    isActive: isActive ?? this.isActive,
    addedOn: addedOn,
    imageUrl: imageUrl,
  );
}

/// One page of [Book]s, mirroring app-api's `pagination` block — see
/// [ProductPage] for the same shape.
class BookPage {
  const BookPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNext,
  });

  final List<Book> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNext;

  bool get isEmpty => items.isEmpty;
}

/// The order the My Store list comes back in — the Shop's orders, less
/// Featured, which owner books have nothing to rank by.
enum BookSort {
  newest('Newest', 'created_at', 'DESC'),
  oldest('Oldest', 'created_at', 'ASC'),
  priceLow('Price: low to high', 'price', 'ASC'),
  priceHigh('Price: high to low', 'price', 'DESC'),
  title('Title: A to Z', 'title', 'ASC'),
  titleDesc('Title: Z to A', 'title', 'DESC');

  const BookSort(this.label, this.field, this.order);

  /// What Clear goes back to.
  static const BookSort initial = BookSort.newest;

  final String label;

  /// Maps onto the `sort`/`order` query params — see `OWNER_BOOK_SORTS` in
  /// app-api.
  final String field;
  final String order;
}

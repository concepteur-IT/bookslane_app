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

  /// Absolute cover URL, or null when there is none — sample books (My
  /// Publishings) never have one; a real book (My Store) does once a cover
  /// was uploaded and app-api has a public storage URL configured.
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

/// Which books a list shows.
enum BookFilter {
  all('All', null),
  active('Active', 1),
  inactive('Inactive', 0),
  inStock('In stock', null);

  const BookFilter(this.label, this.statusValue);

  final String label;

  /// Maps onto the server-backed (My Store) list's `status` query param.
  /// Null means "don't send the parameter" — true for both `all` and
  /// `inStock`, since app-api has no stock filter yet; [BooksProvider.books]
  /// applies `inStock` client-side on whatever page comes back instead.
  final int? statusValue;

  /// Used by the sample-data (My Publishings) list, which still filters in
  /// memory — see [SampleBooks].
  bool matches(Book book) => switch (this) {
    BookFilter.all => true,
    BookFilter.active => book.isActive,
    BookFilter.inactive => !book.isActive,
    BookFilter.inStock => book.isInStock,
  };
}

/// The order they appear in.
enum BookSort {
  newest('Newest', 'created_at', 'DESC'),
  name('Name', 'title', 'ASC'),
  quantity('Qty', 'quantity', 'DESC'),
  price('Price', 'price', 'DESC');

  const BookSort(this.label, this.field, this.order);

  final String label;

  /// Maps onto the server-backed (My Store) list's `sort`/`order` query
  /// params — see `OWNER_BOOK_SORTS` in app-api.
  final String field;
  final String order;

  /// Used by the sample-data (My Publishings) list, which still sorts in
  /// memory — see [SampleBooks].
  int compare(Book a, Book b) => switch (this) {
    // Newest and the two numeric sorts read best descending: the most recent,
    // the most stock, the highest price first.
    BookSort.newest => b.addedOn.compareTo(a.addedOn),
    BookSort.name => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    BookSort.quantity => b.stock.compareTo(a.stock),
    BookSort.price => b.price.compareTo(a.price),
  };
}

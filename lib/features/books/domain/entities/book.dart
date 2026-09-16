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

  bool get isInStock => stock > 0;

  String get formattedPrice => '\$${(price / 100).toStringAsFixed(2)}';

  Book copyWith({bool? isActive}) => Book(
    id: id,
    title: title,
    subtitle: subtitle,
    price: price,
    stock: stock,
    isActive: isActive ?? this.isActive,
    addedOn: addedOn,
  );
}

/// Which books a list shows.
enum BookFilter {
  all('All'),
  active('Active'),
  inactive('Inactive'),
  inStock('In stock');

  const BookFilter(this.label);

  final String label;

  bool matches(Book book) => switch (this) {
    BookFilter.all => true,
    BookFilter.active => book.isActive,
    BookFilter.inactive => !book.isActive,
    BookFilter.inStock => book.isInStock,
  };
}

/// The order they appear in.
enum BookSort {
  newest('Newest'),
  name('Name'),
  quantity('Qty'),
  price('Price');

  const BookSort(this.label);

  final String label;

  int compare(Book a, Book b) => switch (this) {
    // Newest and the two numeric sorts read best descending: the most recent,
    // the most stock, the highest price first.
    BookSort.newest => b.addedOn.compareTo(a.addedOn),
    BookSort.name => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    BookSort.quantity => b.stock.compareTo(a.stock),
    BookSort.price => b.price.compareTo(a.price),
  };
}

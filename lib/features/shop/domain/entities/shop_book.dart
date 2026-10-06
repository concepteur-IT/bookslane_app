/// Which of the caller's two shelves a [ShopBook] came from. The Shop shows
/// both at once.
enum ShopSource {
  /// My Publishings — a book of one of the account's imprints (thinkerslane).
  publishing('Publishing'),

  /// My Store — a book the account sells itself.
  store('Store');

  const ShopSource(this.label);

  final String label;

  static ShopSource fromWire(String? value) =>
      value == 'store' ? ShopSource.store : ShopSource.publishing;
}

/// A book in the Shop — one of the caller's own, from either shelf, as `GET
/// /v1/shop/books` returns it. A trimmed view: only what a catalogue card
/// shows or acts on.
class ShopBook {
  const ShopBook({
    required this.id,
    required this.source,
    required this.refId,
    required this.title,
    required this.author,
    required this.sku,
    required this.mrp,
    required this.price,
    required this.stock,
    this.isActive = true,
    this.imageUrl,
  });

  /// Unique across both shelves (`publishing-3244`, `store-12`) — a product and
  /// a store book can share a number.
  final String id;

  final ShopSource source;

  /// The id in its own shelf — what `/v1/products` or `/v1/books` know it by.
  final int refId;

  final String title;
  final String author;

  /// thinkerslane's product code, or the store book's SKU — the card's second
  /// line.
  final String sku;

  /// List price, struck through when [price] is lower. Major units.
  final double mrp;

  /// What a customer pays: the offer price when there is one, else [mrp].
  /// Major units.
  final double price;

  /// Units on hand.
  final int stock;

  /// Whether the owner has it switched on. The Shop lists inactive books too
  /// — it shows everything My Publishings and My Store do — and tags them.
  final bool isActive;

  /// Absolute cover URL, or null when there is none.
  final String? imageUrl;

  bool get isSoldOut => stock <= 0;
  bool get isDiscounted => price < mrp;

  String get formattedPrice => '₹${price.toStringAsFixed(2)}';
  String get formattedMrp => '₹${mrp.toStringAsFixed(2)}';
}

/// One page of [ShopBook]s, mirroring app-api's `pagination` block.
class ShopBookPage {
  const ShopBookPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNext,
  });

  final List<ShopBook> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNext;
}

/// The options in the sort overlay. [value] is what app-api's `sort` param
/// takes; ordering happens on the server.
enum ShopSort {
  featured('Featured', 'featured'),
  newest('Newest', 'newest'),
  oldest('Oldest', 'oldest'),
  priceLow('Price: low to high', 'price_low'),
  priceHigh('Price: high to low', 'price_high'),
  title('Title: A to Z', 'title'),
  titleDesc('Title: Z to A', 'title_desc');

  const ShopSort(this.label, this.value);

  /// What Clear goes back to.
  static const ShopSort initial = ShopSort.featured;

  final String label;
  final String value;
}

/// Grid of covers or a denser list of rows.
enum ShopView { grid, list }

/// A book in the Shop — the catalogue a retailer orders from.
///
/// MOCKUP: shaped for the design only. Once the Shop API exists, this should
/// mirror its DTO the way `Product` mirrors `/v1/products`.
class ShopBook {
  const ShopBook({
    required this.id,
    required this.title,
    required this.author,
    required this.sku,
    required this.category,
    required this.language,
    required this.mrp,
    required this.price,
    required this.stock,
    required this.addedOn,
    this.featuredRank = 0,
    this.imageUrl,
  });

  final String id;
  final String title;
  final String author;
  final String sku;
  final ShopCategory category;
  final ShopLanguage language;

  /// List price, struck through when [price] is lower. Major units.
  final double mrp;

  /// What the retailer pays. Major units.
  final double price;

  final int stock;
  final DateTime addedOn;

  /// Lower is more prominent; drives the "Featured" sort.
  final int featuredRank;

  final String? imageUrl;

  bool get isSoldOut => stock <= 0;
  bool get isDiscounted => price < mrp;

  String get formattedPrice => '₹${price.toStringAsFixed(2)}';
  String get formattedMrp => '₹${mrp.toStringAsFixed(2)}';
}

enum ShopCategory {
  fiction('Fiction'),
  nonFiction('Non-fiction'),
  lifestyle('Lifestyle'),
  food('Food'),
  kids('Kids'),
  poetry('Poetry');

  const ShopCategory(this.label);

  final String label;
}

enum ShopLanguage {
  english('English'),
  bengali('Bengali'),
  hindi('Hindi');

  const ShopLanguage(this.label);

  final String label;
}

/// The options in the sort overlay.
enum ShopSort {
  featured('Featured'),
  newest('Newest'),
  oldest('Oldest'),
  priceLow('Price: low to high'),
  priceHigh('Price: high to low'),
  title('Title: A to Z'),
  titleDesc('Title: Z to A');

  /// What Clear goes back to.
  static const ShopSort initial = ShopSort.featured;

  const ShopSort(this.label);

  final String label;

  int compare(ShopBook a, ShopBook b) => switch (this) {
    ShopSort.featured => a.featuredRank.compareTo(b.featuredRank),
    ShopSort.newest => b.addedOn.compareTo(a.addedOn),
    ShopSort.oldest => a.addedOn.compareTo(b.addedOn),
    ShopSort.priceLow => a.price.compareTo(b.price),
    ShopSort.priceHigh => b.price.compareTo(a.price),
    ShopSort.title => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    ShopSort.titleDesc => b.title.toLowerCase().compareTo(
      a.title.toLowerCase(),
    ),
  };
}

/// Grid of covers or a denser list of rows.
enum ShopView { grid, list }

/// Everything the filter overlay can set. Empty sets mean "any".
///
/// The starting point is [initial] — in stock only, nothing else — rather
/// than "no filters", since sold-out books can't be ordered.
class ShopFilters {
  const ShopFilters({
    this.categories = const {},
    this.languages = const {},
    this.priceRange,
    this.inStockOnly = true,
  });

  /// What the page opens with, and what Reset / Clear filters go back to.
  static const ShopFilters initial = ShopFilters();

  final Set<ShopCategory> categories;
  final Set<ShopLanguage> languages;

  /// Null means no price limit.
  final ({double min, double max})? priceRange;

  final bool inStockOnly;

  /// How many filter groups differ from [initial] — the badge on the filter
  /// button. The default "in stock only" doesn't count; switching it off does.
  int get activeCount =>
      (categories.isNotEmpty ? 1 : 0) +
      (languages.isNotEmpty ? 1 : 0) +
      (priceRange != null ? 1 : 0) +
      (inStockOnly != initial.inStockOnly ? 1 : 0);

  bool get isInitial => activeCount == 0;

  bool matches(ShopBook book) {
    if (categories.isNotEmpty && !categories.contains(book.category)) {
      return false;
    }
    if (languages.isNotEmpty && !languages.contains(book.language)) {
      return false;
    }
    final range = priceRange;
    if (range != null && (book.price < range.min || book.price > range.max)) {
      return false;
    }
    if (inStockOnly && book.isSoldOut) return false;
    return true;
  }

  ShopFilters copyWith({
    Set<ShopCategory>? categories,
    Set<ShopLanguage>? languages,
    ({double min, double max})? priceRange,
    bool clearPriceRange = false,
    bool? inStockOnly,
  }) => ShopFilters(
    categories: categories ?? this.categories,
    languages: languages ?? this.languages,
    priceRange: clearPriceRange ? null : priceRange ?? this.priceRange,
    inStockOnly: inStockOnly ?? this.inStockOnly,
  );
}

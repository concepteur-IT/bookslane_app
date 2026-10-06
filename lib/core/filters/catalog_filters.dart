/// The filter model shared by My Store, My Publishings and the Shop.
///
/// Every filter panel in the app is **data driven**: the options (categories,
/// languages, the price range) and their counts come from the screen's
/// `/filters` endpoint — see [FilterFacets] — rather than from lists compiled
/// into the app. What the user has *selected* lives in [CatalogFilters].
library;

/// One choosable option in a facet — a category, a language, ….
///
/// Equality is by [id]: the option the user picked and the one in a freshly
/// fetched list are the same option even when the count has moved.
class FacetOption {
  const FacetOption({required this.id, required this.label, this.count = 0});

  /// What goes on the wire — a category id, or a language's name.
  final String id;

  /// What the chip reads as.
  final String label;

  /// How many results the option would leave. Zero when it isn't known.
  final int count;

  @override
  bool operator ==(Object other) => other is FacetOption && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// A price range in whole currency units.
typedef PriceRange = ({double min, double max});

/// What the user has selected. Immutable; [copyWith] makes the next one.
///
/// Which fields a screen uses varies — only the owner screens have [isActive],
/// only the Shop has [priceRange] and [languages] — and each screen has its
/// own starting point (the Shop opens with [inStockOnly] on), so "how many
/// filters are on" is always measured against that screen's `initial`.
class CatalogFilters {
  const CatalogFilters({
    this.isActive,
    this.inStockOnly = false,
    this.categories = const {},
    this.languages = const {},
    this.priceRange,
  });

  /// Active (true) or Inactive (false) only; null = either.
  final bool? isActive;

  final bool inStockOnly;
  final Set<FacetOption> categories;
  final Set<FacetOption> languages;

  /// Null = no price limit.
  final PriceRange? priceRange;

  /// How many filter groups differ from [initial] — the badge on the filter
  /// button. A group counts once however many options it has selected.
  int activeCount(CatalogFilters initial) =>
      (isActive != initial.isActive ? 1 : 0) +
      (inStockOnly != initial.inStockOnly ? 1 : 0) +
      (categories.isNotEmpty ? 1 : 0) +
      (languages.isNotEmpty ? 1 : 0) +
      (priceRange != null ? 1 : 0);

  bool isInitial(CatalogFilters initial) => activeCount(initial) == 0;

  CatalogFilters copyWith({
    bool? isActive,
    bool clearIsActive = false,
    bool? inStockOnly,
    Set<FacetOption>? categories,
    Set<FacetOption>? languages,
    PriceRange? priceRange,
    bool clearPriceRange = false,
  }) => CatalogFilters(
    isActive: clearIsActive ? null : isActive ?? this.isActive,
    inStockOnly: inStockOnly ?? this.inStockOnly,
    categories: categories ?? this.categories,
    languages: languages ?? this.languages,
    priceRange: clearPriceRange ? null : priceRange ?? this.priceRange,
  );

  /// The query params every screen's list and `/filters` endpoint share.
  ///
  /// The API names differ slightly per screen, so the caller passes them:
  /// [categoryKey] is `category` or `category_id`, [statusKey] is `status` or
  /// `is_active`, and null drops a field that screen doesn't have. Anything
  /// not selected is left out entirely — the API rejects empty values.
  Map<String, dynamic> toQuery({
    required String categoryKey,
    String? statusKey,
    bool includeLanguages = true,
    bool includePrice = true,
  }) => {
    if (statusKey != null && isActive != null) statusKey: isActive! ? 1 : 0,
    if (inStockOnly) 'in_stock': 1,
    if (categories.isNotEmpty)
      categoryKey: (categories.map((c) => c.id).toList()..sort()).join(','),
    if (includeLanguages && languages.isNotEmpty)
      'language': (languages.map((l) => l.id).toList()..sort()).join(','),
    if (includePrice && priceRange != null) ...{
      'min_price': priceRange!.min.floor(),
      'max_price': priceRange!.max.ceil(),
    },
  };
}

/// What a filter panel can offer for the current selection — the parsed
/// response of a `/filters` endpoint.
///
/// Each facet is counted with every *other* filter applied but not its own,
/// so choosing one category leaves the rest listed; only [total] has all of
/// them applied.
class FilterFacets {
  const FilterFacets({
    required this.total,
    this.categories = const [],
    this.languages = const [],
    this.price,
    this.inStock = 0,
    this.active,
    this.inactive,
  });

  /// Results with every filter applied — the panel's "show N" button.
  final int total;

  final List<FacetOption> categories;
  final List<FacetOption> languages;

  /// The selling-price bounds across the current results; null when there is
  /// no price facet (or no results).
  final PriceRange? price;

  /// How many results are in stock.
  final int inStock;

  /// Counts for Active / Inactive; null on screens with no status filter.
  final int? active;
  final int? inactive;

  bool get hasStatus => active != null && inactive != null;

  factory FilterFacets.fromJson(Map<String, dynamic> json) {
    int asInt(Object? v) => switch (v) {
      int() => v,
      num() => v.round(),
      String() => int.tryParse(v) ?? 0,
      _ => 0,
    };

    String asString(Object? v) => v?.toString().trim() ?? '';

    List<FacetOption> options(Object? rows, String idKey, String labelKey) => [
      if (rows is List)
        for (final row in rows)
          if (row is Map<String, dynamic> && asString(row[idKey]).isNotEmpty)
            FacetOption(
              id: asString(row[idKey]),
              label: asString(row[labelKey]).isNotEmpty
                  ? asString(row[labelKey])
                  : asString(row[idKey]),
              count: asInt(row['count']),
            ),
    ];

    final priceJson = json['price'];
    final stock = json['stock'];
    final status = json['status'];

    return FilterFacets(
      total: asInt(json['total']),
      categories: options(json['categories'], 'id', 'name'),
      languages: options(json['languages'], 'value', 'value'),
      price: priceJson is Map<String, dynamic>
          ? (
              min: asInt(priceJson['min']).toDouble(),
              max: asInt(priceJson['max']).toDouble(),
            )
          : null,
      inStock: stock is Map<String, dynamic> ? asInt(stock['in_stock']) : 0,
      active: status is Map<String, dynamic> ? asInt(status['active']) : null,
      inactive: status is Map<String, dynamic>
          ? asInt(status['inactive'])
          : null,
    );
  }
}

/// Which sections a screen's filter panel shows, and where it starts.
class FilterSpec {
  const FilterSpec({
    this.initial = const CatalogFilters(),
    this.status = false,
    this.price = false,
    this.languages = false,
    this.multiCategory = false,
    this.noun = 'book',
  });

  /// What the screen opens with, and what Reset goes back to.
  final CatalogFilters initial;

  /// Show Active / Inactive.
  final bool status;

  /// Show the price range slider.
  final bool price;

  /// Show the language chips.
  final bool languages;

  /// May several categories be picked at once? The owner screens are
  /// single-choice; the Shop allows several.
  final bool multiCategory;

  /// Singular, for the apply button: "SHOW 1 BOOK" / "SHOW 12 BOOKS".
  final String noun;
}

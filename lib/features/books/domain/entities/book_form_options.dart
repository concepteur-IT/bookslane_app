/// The fixed choice lists behind the Add Book form's dropdowns.
///
/// Each enum carries both the label shown in the dropdown and the value the
/// API expects, so the form never maps between the two by hand.
///
/// Categories and languages are hard-coded for now. When app-api grows
/// `GET /v1/categories` and `GET /v1/languages`, swap [BookCategory.values]
/// and [BookLanguage.values] for the fetched lists — the form already takes
/// its items from a list, so only the source changes.
library;

/// `language` on the products table. The value is a BCP-47 code.
enum BookLanguage {
  english('English', 'en'),
  bengali('Bengali', 'bn');

  const BookLanguage(this.label, this.code);

  final String label;

  /// What goes on the wire — 'en', 'hi', …
  final String code;

  /// Null when [code] doesn't match any of these — e.g. legacy or free-form
  /// data the fixed dropdown doesn't cover. The Edit Book form leaves the
  /// field unset in that case rather than guessing.
  static BookLanguage? fromCode(String? code) {
    for (final language in values) {
      if (language.code == code) return language;
    }
    return null;
  }
}

/// `category` on the products table. The value is the numeric category id.
enum BookCategory {
  fiction('Fiction', 1),
  nonFiction('Non-fiction', 2),
  academic('Academic & Textbooks', 3),
  childrens("Children's", 4),
  biography('Biography & Memoir', 5),
  business('Business & Economics', 6),
  selfHelp('Self-help', 7),
  history('History', 8),
  science('Science & Technology', 9),
  religion('Religion & Spirituality', 10),
  poetry('Poetry', 11),
  comics('Comics & Graphic Novels', 12),
  reference('Reference', 13);

  const BookCategory(this.label, this.id);

  final String label;
  final int id;

  /// Null when [id] doesn't parse or match any of these — see
  /// [BookLanguage.fromCode] for the same fallback.
  static BookCategory? fromId(String? id) {
    final parsed = int.tryParse(id ?? '');
    if (parsed == null) return null;
    for (final category in values) {
      if (category.id == parsed) return category;
    }
    return null;
  }
}

/// `binding` on the products table — how the book is bound.
enum BookBinding {
  paperback('Paperback', 'paperback'),
  hardcover('Hardcover', 'hardcover'),
  spiral('Spiral bound', 'spiral'),
  boardBook('Board book', 'board_book'),
  ebook('E-book', 'ebook'),
  audiobook('Audiobook', 'audiobook');

  const BookBinding(this.label, this.value);

  final String label;
  final String value;

  /// Null when [value] doesn't match any of these — see
  /// [BookLanguage.fromCode] for the same fallback.
  static BookBinding? fromValue(String? value) {
    for (final binding in values) {
      if (binding.value == value) return binding;
    }
    return null;
  }
}

/// `discount_type` on the products table.
enum DiscountType {
  flat('Flat (₹)', 'flat'),
  percentage('Percentage (%)', 'percentage');

  const DiscountType(this.label, this.value);

  final String label;
  final String value;

  /// Unlike [BookLanguage.fromCode] this always resolves: app-api's own
  /// `discount_type` column only ever holds one of these two values, so
  /// there's no legacy/free-form case to fall back on — defaults to [flat].
  static DiscountType fromValue(String? value) {
    for (final type in values) {
      if (type.value == value) return type;
    }
    return DiscountType.flat;
  }
}

/// `status` on the products table. Mirrors the 0/1 `is_active` the product
/// list already reads — see [ProductFilter].
enum BookStatus {
  active('Active', 1),
  inactive('Inactive', 0);

  const BookStatus(this.label, this.value);

  final String label;
  final int value;

  /// Always resolves — see [DiscountType.fromValue] for why.
  static BookStatus fromValue(int value) => value == BookStatus.active.value
      ? BookStatus.active
      : BookStatus.inactive;
}

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
}

/// `discount_type` on the products table.
enum DiscountType {
  flat('Flat (₹)', 'flat'),
  percentage('Percentage (%)', 'percentage');

  const DiscountType(this.label, this.value);

  final String label;
  final String value;
}

/// `status` on the products table. Mirrors the 0/1 `is_active` the product
/// list already reads — see [ProductFilter].
enum BookStatus {
  active('Active', 1),
  inactive('Inactive', 0);

  const BookStatus(this.label, this.value);

  final String label;
  final int value;
}

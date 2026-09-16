import 'package:bookslane_app/features/books/domain/entities/book.dart';

/// Stand-in catalogue until the books endpoints exist.
///
/// TODO: replace with a BooksRepository once /v1/books lands. Everything the
/// list screen does — search, filter, sort, paging — happens in memory here
/// and moves to query parameters then.
abstract final class SampleBooks {
  static final DateTime _now = DateTime(2026, 9, 8);

  static Book _book(
    String id,
    String title,
    String subtitle,
    int price,
    int stock,
    bool isActive,
    int daysAgo,
  ) => Book(
    id: id,
    title: title,
    subtitle: subtitle,
    price: price,
    stock: stock,
    isActive: isActive,
    addedOn: _now.subtract(Duration(days: daysAgo)),
  );

  static final List<Book> store = [
    _book('s1', 'Travel Journal', 'Hardcover dotted notebook', 1125, 500, false, 1),
    _book('s2', 'Gardening Basics', 'Grow your own vegetables', 1675, 23, true, 2),
    _book('s3', 'Startup Handbook', 'From idea to first customer', 2100, 54, true, 3),
    _book('s4', 'Exam Prep: Math', 'Grade 10 mathematics workbook', 850, 340, true, 4),
    _book('s5', 'Poetry Collection', 'Selected poems 1900-2000', 999, 66, false, 5),
    _book('s6', 'Atlas of the World', 'Updated 2026 edition with maps', 4999, 15, true, 6),
    _book('s7', 'Pocket Dictionary', 'Compact English reference', 750, 0, true, 7),
    _book('s8', 'Watercolour Pad', '200gsm, 30 sheets', 1450, 88, true, 8),
    _book('s9', 'Chess for Beginners', 'Openings and endgames', 1299, 12, false, 9),
    _book('s10', 'Baking at Home', 'Breads, cakes and pastry', 2450, 41, true, 10),
    _book('s11', 'Nordic Birds', 'Field guide with photographs', 3199, 7, true, 11),
    _book('s12', 'Sticker Book', 'For ages 3 and up', 599, 210, true, 12),
  ];

  static final List<Book> publishings = [
    _book('p1', 'The Malmö Letters', 'A novel in three parts', 1899, 120, true, 1),
    _book('p2', 'Coastal Recipes', 'Seafood from the south', 2599, 64, true, 3),
    _book('p3', 'Winter Light', 'Short stories', 1499, 38, false, 5),
    _book('p4', 'Building Bookslane', 'Notes from a founder', 2299, 91, true, 6),
    _book('p5', 'Small Hours', 'Poems for the sleepless', 1150, 27, true, 8),
    _book('p6', 'Maps of Skåne', 'Illustrated regional guide', 3450, 9, true, 9),
    _book('p7', 'First Words', 'A picture book', 899, 0, false, 12),
  ];

  static List<Book> forSource(BookSource source) => switch (source) {
    BookSource.store => store,
    BookSource.publishings => publishings,
  };
}

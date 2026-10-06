import 'package:bookslane_app/core/filters/catalog_filters.dart';
import 'package:bookslane_app/features/books/domain/entities/book.dart';
import 'package:bookslane_app/features/books/domain/entities/book_detail.dart';
import 'package:bookslane_app/features/books/domain/entities/book_draft.dart';
import 'package:bookslane_app/features/books/domain/entities/book_form_options.dart';

/// The signed-in account's books, stated without reference to HTTP or JSON.
///
/// Every method throws [ApiFailure] and nothing else.
abstract interface class BooksRepository {
  /// One page of the signed-in account's books (`My Store`).
  Future<BookPage> fetchBooks({
    required int page,
    int limit,
    String? search,
    CatalogFilters filters,
    BookSort sort,
  });

  /// What the My Store filter panel can offer if the user keeps [filters] and
  /// the current [search]: counts per option and the total they would leave.
  Future<FilterFacets> fetchFilters(CatalogFilters filters, {String? search});

  /// Every category a book can be filed under — the Add/Edit Book form's
  /// dropdown. The same list My Publishings' categories come from.
  Future<List<BookCategory>> fetchCategories();

  /// One book's full detail — used to prefill the Edit Book form, which
  /// needs fields (sku, description, language, category, ...) the list row
  /// [Book] doesn't carry.
  Future<BookDetail> getBook(String id);

  /// Creates a book from a validated [AddBookForm] draft and returns it as
  /// the API stored it — including the server-assigned id and, once a cover
  /// was attached, its `image_url`.
  Future<Book> createBook(BookDraft draft);

  /// Updates a book from a validated [AddBookForm] draft (edit mode) and
  /// returns it as the API stored it. A draft whose `image` is null leaves
  /// the existing cover untouched — see [BooksRemoteDataSource.update].
  Future<Book> updateBook(String id, BookDraft draft);

  /// Sets a book's active flag and returns the updated book.
  Future<Book> setActive({required String id, required bool isActive});
}

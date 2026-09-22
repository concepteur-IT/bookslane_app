import 'package:bookslane_app/features/books/domain/entities/book.dart';
import 'package:bookslane_app/features/books/domain/entities/book_draft.dart';

/// The signed-in account's books, stated without reference to HTTP or JSON.
///
/// Every method throws [ApiFailure] and nothing else.
abstract interface class BooksRepository {
  /// One page of the signed-in account's books (`My Store`).
  Future<BookPage> fetchBooks({
    required int page,
    int limit,
    String? search,
    BookFilter filter,
    BookSort sort,
  });

  /// Creates a book from a validated [AddBookForm] draft and returns it as
  /// the API stored it — including the server-assigned id and, once a cover
  /// was attached, its `image_url`.
  Future<Book> createBook(BookDraft draft);

  /// Sets a book's active flag and returns the updated book.
  Future<Book> setActive({required String id, required bool isActive});
}

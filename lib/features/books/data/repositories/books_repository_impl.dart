import 'package:dio/dio.dart';

import 'package:bookslane_app/core/network/api_failure.dart';
import 'package:bookslane_app/features/books/data/datasources/books_remote_datasource.dart';
import 'package:bookslane_app/features/books/domain/entities/book.dart';
import 'package:bookslane_app/features/books/domain/entities/book_draft.dart';
import 'package:bookslane_app/features/books/domain/repositories/books_repository.dart';

/// Implements [BooksRepository] against app-api.
///
/// This is where `DioException` stops: callers get an [ApiFailure] with a
/// message meant for a person and app-api's `errorCode` to switch on — see
/// [ProductsRepositoryImpl] for the same shape.
class BooksRepositoryImpl implements BooksRepository {
  const BooksRepositoryImpl({required this.remoteDataSource});

  final BooksRemoteDataSource remoteDataSource;

  @override
  Future<Book> createBook(BookDraft draft) async {
    try {
      final result = await remoteDataSource.create(draft);
      return result.toEntity();
    } on DioException catch (error) {
      // app-api's message is already written for a person here (e.g.
      // "You already have a book with that SKU." for SKU_ALREADY_EXISTS), so
      // there's no per-code override to make, unlike ProductsRepositoryImpl.
      throw mapDioException(error);
    } on FormatException {
      throw const ApiFailure(
        'The server sent something unexpected. Please try again.',
      );
    }
  }
}

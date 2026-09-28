import 'package:dio/dio.dart';

import 'package:bookslane_app/core/network/api_failure.dart';
import 'package:bookslane_app/features/books/data/datasources/books_remote_datasource.dart';
import 'package:bookslane_app/features/books/domain/entities/book.dart';
import 'package:bookslane_app/features/books/domain/entities/book_detail.dart';
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
  Future<BookPage> fetchBooks({
    required int page,
    int limit = 10,
    String? search,
    BookFilters filters = BookFilters.initial,
    BookSort sort = BookSort.initial,
  }) async {
    try {
      final result = await remoteDataSource.list(
        page: page,
        limit: limit,
        search: search,
        filters: filters,
        sort: sort,
      );
      return result.toEntity();
    } on DioException catch (error) {
      throw mapDioException(error);
    } on FormatException {
      throw const ApiFailure(
        'The server sent something unexpected. Please try again.',
      );
    }
  }

  @override
  Future<BookDetail> getBook(String id) async {
    try {
      final result = await remoteDataSource.get(id);
      return result.toDetail();
    } on DioException catch (error) {
      throw mapDioException(error);
    } on FormatException {
      throw const ApiFailure(
        'The server sent something unexpected. Please try again.',
      );
    }
  }

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

  @override
  Future<Book> updateBook(String id, BookDraft draft) async {
    try {
      final result = await remoteDataSource.update(id, draft);
      return result.toEntity();
    } on DioException catch (error) {
      throw mapDioException(error);
    } on FormatException {
      throw const ApiFailure(
        'The server sent something unexpected. Please try again.',
      );
    }
  }

  @override
  Future<Book> setActive({required String id, required bool isActive}) async {
    try {
      final result = await remoteDataSource.updateActive(
        id: id,
        isActive: isActive,
      );
      return result.toEntity();
    } on DioException catch (error) {
      throw mapDioException(error);
    } on FormatException {
      throw const ApiFailure(
        'The server sent something unexpected. Please try again.',
      );
    }
  }
}

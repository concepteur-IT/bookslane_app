import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import 'package:bookslane_app/core/config/api_endpoints.dart';
import 'package:bookslane_app/core/network/api_client.dart';
import 'package:bookslane_app/features/books/data/models/book_model.dart';
import 'package:bookslane_app/features/books/domain/entities/book.dart';
import 'package:bookslane_app/features/books/domain/entities/book_draft.dart';

/// Talks to `/v1/books`. Knows about HTTP, multipart and JSON, and nothing
/// else.
///
/// Guarded, so every call needs the bearer token that `AuthInterceptor`
/// attaches.
class BooksRemoteDataSource {
  const BooksRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Future<BookPageModel> list({
    required int page,
    required int limit,
    String? search,
    BookFilters filters = BookFilters.initial,
    BookSort sort = BookSort.initial,
  }) async {
    final response = await apiClient.dio.get<dynamic>(
      ApiEndpoints.books,
      queryParameters: <String, dynamic>{
        'page': page,
        'limit': limit,
        'sort': sort.field,
        'order': sort.order,
        // Omitted rather than sent empty: the pipe runs with
        // forbidNonWhitelisted, and an empty search would match nothing.
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (filters.isActive != null) 'status': filters.isActive! ? 1 : 0,
        if (filters.inStockOnly) 'in_stock': 1,
        if (filters.category != null) 'category': '${filters.category!.id}',
      },
    );

    return BookPageModel.fromJson(_asJsonObject(response.data));
  }

  /// One book's full detail — what the Edit Book form prefills itself from.
  Future<BookModel> get(String id) async {
    final response = await apiClient.dio.get<dynamic>(ApiEndpoints.book(id));
    return BookModel.fromJson(_asJsonObject(response.data));
  }

  /// Sets a book's active flag. Sent as multipart, like create/update, even
  /// though this one field would be just as valid as JSON — app-api's
  /// `PATCH /v1/books/:id` only accepts multipart/form-data.
  Future<BookModel> updateActive({
    required String id,
    required bool isActive,
  }) async {
    final formData = FormData.fromMap({'is_active': isActive ? '1' : '0'});

    final response = await apiClient.dio.patch<dynamic>(
      ApiEndpoints.book(id),
      data: formData,
    );

    return BookModel.fromJson(_asJsonObject(response.data));
  }

  /// Creates a book.
  ///
  /// Sent as multipart/form-data — see [BookDraft.toJson], which deliberately
  /// leaves `image` out of its map because it travels as a file part
  /// alongside it, not as a JSON value.
  Future<BookModel> create(BookDraft draft) async {
    final response = await apiClient.dio.post<dynamic>(
      ApiEndpoints.books,
      data: await _formDataFor(draft),
    );

    return BookModel.fromJson(_asJsonObject(response.data));
  }

  /// Updates a book. Same multipart shape as [create] — an unpicked [image]
  /// means "leave the current cover alone", not "clear it".
  Future<BookModel> update(String id, BookDraft draft) async {
    final response = await apiClient.dio.patch<dynamic>(
      ApiEndpoints.book(id),
      data: await _formDataFor(draft),
    );

    return BookModel.fromJson(_asJsonObject(response.data));
  }

  Future<FormData> _formDataFor(BookDraft draft) async {
    final image = draft.image;

    return FormData.fromMap({
      for (final entry in draft.toJson().entries)
        entry.key: entry.value.toString(),
      if (image != null) 'image': await _multipartFor(image),
    });
  }

  Future<MultipartFile> _multipartFor(XFile file) async {
    return MultipartFile.fromBytes(
      await file.readAsBytes(),
      filename: file.name,
      contentType: _mediaTypeFor(file),
    );
  }

  /// image_picker's `mimeType` isn't always populated (platform-dependent),
  /// so this falls back to the file extension — app-api only accepts jpeg,
  /// png and webp, so anything else is rejected there with a clear message.
  DioMediaType _mediaTypeFor(XFile file) {
    final mime = file.mimeType;
    if (mime != null && mime.isNotEmpty) return DioMediaType.parse(mime);

    final extension = file.name.split('.').last.toLowerCase();
    return switch (extension) {
      'png' => DioMediaType('image', 'png'),
      'webp' => DioMediaType('image', 'webp'),
      _ => DioMediaType('image', 'jpeg'),
    };
  }

  Map<String, dynamic> _asJsonObject(Object? body) {
    if (body is! Map<String, dynamic>) {
      throw const FormatException('Expected a JSON object from the API.');
    }
    return body;
  }
}

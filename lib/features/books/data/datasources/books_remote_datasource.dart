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
    BookFilter filter = BookFilter.all,
    BookSort sort = BookSort.newest,
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
        if (filter.statusValue != null) 'status': filter.statusValue,
      },
    );

    return BookPageModel.fromJson(_asJsonObject(response.data));
  }

  /// Sets a book's active flag. Sent as multipart, like create/update, even
  /// though this one field would be just as valid as JSON — app-api's
  /// `PATCH /v1/books/:id` only accepts multipart/form-data.
  Future<BookModel> updateActive({required String id, required bool isActive}) async {
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
    final image = draft.image;

    final formData = FormData.fromMap({
      for (final entry in draft.toJson().entries) entry.key: entry.value.toString(),
      if (image != null) 'image': await _multipartFor(image),
    });

    final response = await apiClient.dio.post<dynamic>(
      ApiEndpoints.books,
      data: formData,
    );

    return BookModel.fromJson(_asJsonObject(response.data));
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

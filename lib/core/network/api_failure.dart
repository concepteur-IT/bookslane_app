import 'package:dio/dio.dart';

/// An API problem, already phrased for a human.
///
/// The data layer catches [DioException] and throws one of these, so no widget
/// has to know what a status code is — it shows [message].
class ApiFailure implements Exception {
  const ApiFailure(this.message, {this.errorCode, this.statusCode});

  /// Safe to put in front of the user.
  final String message;

  /// app-api's machine-readable tag — `PRODUCT_NOT_FOUND`,
  /// `CATALOGUE_UNAVAILABLE`, `PUBLISHER_NOT_OWNED`. Switch on this, never on
  /// [message]: the text is written for people and will be translated.
  final String? errorCode;

  final int? statusCode;

  bool get isNotFound => statusCode == 404;
  bool get isUnavailable => statusCode == 503;

  @override
  String toString() => 'ApiFailure($statusCode/$errorCode): $message';
}

/// Turns a [DioException] into an [ApiFailure].
///
/// app-api answers every error through one exception filter, so the body is
/// always `{statusCode, message, errorCode?, errors?}` with `message` already
/// flattened to a string.
ApiFailure mapDioException(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return const ApiFailure(
        'The server took too long to respond. Please try again.',
      );
    case DioExceptionType.connectionError:
    case DioExceptionType.unknown:
      return const ApiFailure(
        'Cannot reach the server. Check your connection and try again.',
      );
    case DioExceptionType.cancel:
      return const ApiFailure('The request was cancelled.');
    case DioExceptionType.badCertificate:
      return const ApiFailure('The server could not be verified.');
    case DioExceptionType.badResponse:
      final status = error.response?.statusCode;
      final body = error.response?.data;
      final message = body is Map ? body['message'] : null;
      final errorCode = body is Map ? body['errorCode'] : null;

      return ApiFailure(
        message is String && message.isNotEmpty
            ? message
            : _fallbackFor(status),
        errorCode: errorCode is String ? errorCode : null,
        statusCode: status,
      );
  }
}

String _fallbackFor(int? status) {
  if (status != null && status >= 500) {
    return 'Something went wrong on our side. Please try again.';
  }
  return 'That request could not be completed.';
}

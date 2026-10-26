import 'package:dio/dio.dart';

import 'package:bookslane_app/core/config/api_endpoints.dart';
import 'package:bookslane_app/core/network/api_client.dart';
import 'package:bookslane_app/core/network/api_failure.dart';
import 'package:bookslane_app/core/network/json_coerce.dart';
import 'package:bookslane_app/features/profile/domain/entities/profile.dart';
import 'package:bookslane_app/features/profile/domain/repositories/profile_repository.dart';

/// `GET /v1/profile` — small enough that the wire format, the call and the
/// error mapping live in one file.
class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<Profile> fetchProfile() async {
    try {
      final response = await apiClient.dio.get<dynamic>(ApiEndpoints.profile);
      final json = response.data;
      if (json is! Map<String, dynamic>) throw const FormatException();

      DateTime date(Object? v) =>
          DateTime.tryParse(jsonString(v))?.toLocal() ?? DateTime.now();

      return Profile(
        id: jsonString(json['id']),
        legacyUserId: jsonString(json['user_id']),
        email: jsonString(json['email']).trim(),
        firstName: jsonString(json['first_name']).trim(),
        lastName: jsonString(json['last_name']).trim(),
        mobile: jsonString(json['mobile']).trim(),
        address: jsonString(json['address']).trim(),
        roleIds: jsonString(json['role_ids']).trim(),
        isActive: jsonInt(json['status']) == 1,
        createdAt: date(json['created_at']),
        updatedAt: date(json['updated_at']),
      );
    } on DioException catch (error) {
      throw mapDioException(error);
    } on FormatException {
      throw const ApiFailure(
        'The server sent something unexpected. Please try again.',
      );
    }
  }
}

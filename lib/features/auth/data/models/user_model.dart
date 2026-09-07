import 'package:bookslane_app/features/auth/domain/entities/user.dart';

/// Wire format of app-api's `AppUserDto`: `{ id, email }`.
///
/// A separate type from [User] on purpose — when the API adds or renames a
/// field, only this file changes.
class UserModel {
  const UserModel({required this.id, required this.email, this.name});

  final String id;
  final String email;
  final String? name;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      // The API sends a UUID string today; an int is accepted too.
      id: User.parseId(json['id']),
      email: json['email'] as String,
      // Not part of AppUserDto — tolerated so a future field just works.
      name: json['name'] as String?,
    );
  }

  User toEntity() => User(id: id, email: email, name: name);
}

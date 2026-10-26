import 'package:bookslane_app/features/profile/domain/entities/profile.dart';

/// The signed-in owner's own account. Throws [ApiFailure] and nothing else.
abstract interface class ProfileRepository {
  Future<Profile> fetchProfile();
}

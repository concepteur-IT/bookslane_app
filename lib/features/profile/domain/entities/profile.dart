/// Everything bookslane's `users` table holds about the signed-in owner,
/// except the password. Fields the account never filled in are empty.
class Profile {
  const Profile({
    required this.id,
    required this.legacyUserId,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.mobile,
    required this.address,
    required this.roleIds,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;

  /// The account's id in thinkerslane; `0` when it was created in bookslane.
  final String legacyUserId;
  final String email;
  final String firstName;
  final String lastName;
  final String mobile;
  final String address;

  /// As stored, e.g. `1`.
  final String roleIds;
  final bool isActive;

  /// Local time.
  final DateTime createdAt;
  final DateTime updatedAt;

  String get fullName => '$firstName $lastName'.trim();

  /// One or two letters for the avatar.
  String get initials {
    final letters = [
      if (firstName.isNotEmpty) firstName[0],
      if (lastName.isNotEmpty) lastName[0],
    ].join();
    return letters.isEmpty
        ? (email.isEmpty ? '?' : email[0]).toUpperCase()
        : letters.toUpperCase();
  }
}

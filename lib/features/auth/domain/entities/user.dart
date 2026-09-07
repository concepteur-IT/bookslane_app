/// A signed-in person, as the rest of the app thinks of them.
///
/// Domain layer: no JSON, no Dio, no imports from `data/`. Anything that knows
/// about wire formats belongs in `data/models/`.
class User {
  const User({required this.id, required this.email, this.name});

  /// Always held as a [String].
  ///
  /// app-api sends a UUID string, but other services (and older endpoints)
  /// send a numeric id. Rather than picking one and breaking on the other,
  /// ids are normalised through [parseId] on the way in — `7` and `"7"` end up
  /// identical, so comparison, routing and storage never depend on which
  /// arrived.
  final String id;

  final String email;

  /// app-api's `AppUserDto` carries only `id` and `email`, so this is often
  /// absent. Use [displayName] when you need something to show.
  final String? name;

  /// Safe to put on screen: the name when there is one, otherwise the email.
  String get displayName => (name != null && name!.isNotEmpty) ? name! : email;

  /// Accepts an id that arrives as an `int` or a `String`.
  ///
  /// ```dart
  /// User.parseId(7)        // '7'
  /// User.parseId('c7f1')   // 'c7f1'
  /// User.parseId(null)     // throws FormatException
  /// ```
  ///
  /// Throws [FormatException] on anything else — a null or a nested object
  /// means the response shape changed, and failing loudly at the edge beats a
  /// mysterious null halfway through a screen.
  static String parseId(Object? raw) {
    if (raw is String && raw.isNotEmpty) return raw;
    if (raw is int) return raw.toString();
    if (raw is BigInt) return raw.toString();
    throw FormatException('Unsupported user id: ${raw.runtimeType} ($raw)');
  }

  User copyWith({String? id, String? email, String? name}) => User(
    id: id ?? this.id,
    email: email ?? this.email,
    name: name ?? this.name,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          other.id == id &&
          other.email == email &&
          other.name == name;

  @override
  int get hashCode => Object.hash(id, email, name);

  @override
  String toString() => 'User(id: $id, email: $email, name: $name)';
}

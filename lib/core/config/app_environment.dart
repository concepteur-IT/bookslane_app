/// The build's target environment.
///
/// Selected at compile time so a build can never point at the wrong backend by
/// accident:
///
/// ```sh
/// flutter run                                   # dev (default)
/// flutter run --dart-define=ENV=staging
/// flutter build apk --dart-define=ENV=production
/// ```
enum AppEnvironment {
  dev,
  staging,
  production;

  /// Value of `--dart-define=ENV=...`, defaulting to [AppEnvironment.dev].
  ///
  /// `const` so the compiler can tree-shake the branches it doesn't need.
  static const String _raw = String.fromEnvironment('ENV', defaultValue: 'dev');

  static final AppEnvironment current = AppEnvironment.values.firstWhere(
    (env) => env.name == _raw,
    // A typo'd flag must not silently ship a dev build to the store.
    orElse: () => throw StateError(
      'Unknown ENV "$_raw". Expected one of: '
      '${AppEnvironment.values.map((e) => e.name).join(', ')}.',
    ),
  );

  bool get isDev => this == AppEnvironment.dev;
  bool get isStaging => this == AppEnvironment.staging;
  bool get isProduction => this == AppEnvironment.production;
}

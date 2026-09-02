/// Bundled asset paths.
///
/// Every path here must also be declared under `flutter: assets:` in
/// pubspec.yaml, or the lookup throws at runtime.
abstract final class AppAssets {
  static const String _images = 'assets/images';

  static const String logo = '$_images/logo.png';
  static const String logo48 = '$_images/logo-48.png';
  static const String logo32 = '$_images/logo-32.png';
}

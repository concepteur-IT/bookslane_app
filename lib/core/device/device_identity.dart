import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

import 'package:bookslane_app/core/config/config.dart';

/// Where the install's id lives. An interface so tests need no keychain.
abstract interface class DeviceIdStore {
  Future<String?> read();

  Future<void> write(String id);
}

/// The install id in the platform's secure store, next to the auth tokens.
class SecureDeviceIdStore implements DeviceIdStore {
  SecureDeviceIdStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: AppConstants.deviceIdKey);

  @override
  Future<void> write(String id) =>
      _storage.write(key: AppConstants.deviceIdKey, value: id);
}

/// What the device and the build say about themselves. An interface so tests
/// need no platform channels.
abstract interface class DeviceProbe {
  /// `android`, `ios`, `windows`, `macos`, `web` or `other` — the values the
  /// API accepts for `platform`.
  String get platform;

  /// A human label such as "Pixel 7" for the "signed in on …" message, or null.
  Future<String?> deviceName();

  /// `1.2.3+45` (version + build number), or null if it can't be read.
  Future<String?> appVersion();
}

/// The API's `platform` value for a Flutter target platform. Linux and Fuchsia
/// are not distribution targets here, so they report `other`.
String platformNameFor(TargetPlatform platform, {required bool isWeb}) {
  if (isWeb) return 'web';
  return switch (platform) {
    TargetPlatform.android => 'android',
    TargetPlatform.iOS => 'ios',
    TargetPlatform.macOS => 'macos',
    TargetPlatform.windows => 'windows',
    TargetPlatform.linux || TargetPlatform.fuchsia => 'other',
  };
}

/// The real probe, backed by device_info_plus and package_info_plus.
class PlatformDeviceProbe implements DeviceProbe {
  @override
  String get platform =>
      platformNameFor(defaultTargetPlatform, isWeb: kIsWeb);

  @override
  Future<String?> deviceName() async {
    try {
      final info = DeviceInfoPlugin();
      if (kIsWeb) return (await info.webBrowserInfo).browserName.name;

      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          final a = await info.androidInfo;
          return '${a.manufacturer} ${a.model}';
        // The model ("iPhone", "MacBookPro18,3"), never the owner's chosen
        // device name, which is usually their own name.
        case TargetPlatform.iOS:
          return (await info.iosInfo).model;
        case TargetPlatform.macOS:
          return (await info.macOsInfo).model;
        case TargetPlatform.windows:
          return (await info.windowsInfo).computerName;
        case TargetPlatform.linux:
        case TargetPlatform.fuchsia:
          return null;
      }
    } catch (_) {
      return null; // a label is nice to have, never worth failing over
    }
  }

  @override
  Future<String?> appVersion() async {
    try {
      final p = await PackageInfo.fromPlatform();
      return p.buildNumber.isEmpty ? p.version : '${p.version}+${p.buildNumber}';
    } catch (_) {
      return null;
    }
  }
}

/// Who this install is, as the API wants to hear it: a stable id for the
/// single-device rule, a label for messages, the platform, and the build version.
///
/// Load it once at start-up ([load]) and share it.
class DeviceIdentity {
  const DeviceIdentity({
    required this.deviceId,
    required this.platform,
    this.deviceName,
    this.appVersion,
  });

  /// Random v4 uuid, created on first run and kept in secure storage. The API
  /// treats a new id as a new device (and signs the old one out), so it must
  /// not change from launch to launch. Uninstalling may or may not clear it,
  /// depending on the OS — either way the API copes.
  final String deviceId;

  /// See [DeviceProbe.platform].
  final String platform;

  /// At most 120 characters, as the API allows; null if unknown.
  final String? deviceName;

  /// `1.2.3+45`; null if unknown (the header is then simply not sent).
  final String? appVersion;

  /// The ids the API accepts: 8–64 letters, digits and `. _ : -`.
  static final RegExp _validId = RegExp(r'^[A-Za-z0-9._:-]{8,64}$');

  static Future<DeviceIdentity> load({
    DeviceIdStore? store,
    DeviceProbe? probe,
    String Function()? newId,
  }) async {
    final idStore = store ?? SecureDeviceIdStore();
    final device = probe ?? PlatformDeviceProbe();

    String? id;
    try {
      id = await idStore.read();
    } catch (_) {
      id = null; // an unreadable store must not stop the app from starting
    }

    if (id == null || !_validId.hasMatch(id)) {
      id = (newId ?? const Uuid().v4)();
      try {
        await idStore.write(id);
      } catch (_) {
        // Still usable for this run; a later launch will make another.
      }
    }

    final name = (await device.deviceName())?.trim();
    return DeviceIdentity(
      deviceId: id,
      platform: device.platform,
      deviceName: (name == null || name.isEmpty)
          ? null
          : (name.length > 120 ? name.substring(0, 120) : name),
      appVersion: await device.appVersion(),
    );
  }

  /// Sent on EVERY request, so the server can ask an outdated build to update.
  Map<String, String> get headers => {
    AppConstants.appPlatformHeader: platform,
    AppConstants.appVersionHeader: ?appVersion,
  };

  /// The extra fields of the login body (and the refresh body's `device_id`).
  Map<String, String> get loginFields => {
    'device_id': deviceId,
    'platform': platform,
    'device_name': ?deviceName,
    'app_version': ?appVersion,
  };
}

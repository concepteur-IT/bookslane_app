import 'package:bookslane_app/core/device/device_identity.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeIdStore implements DeviceIdStore {
  FakeIdStore({this.stored, this.failRead = false, this.failWrite = false});

  String? stored;
  final bool failRead;
  final bool failWrite;
  int writes = 0;

  @override
  Future<String?> read() async {
    if (failRead) throw StateError('keychain unavailable');
    return stored;
  }

  @override
  Future<void> write(String id) async {
    if (failWrite) throw StateError('keychain unavailable');
    writes++;
    stored = id;
  }
}

class FakeProbe implements DeviceProbe {
  FakeProbe({
    this.platform = 'android',
    this.name = 'Pixel 7',
    this.version = '1.2.3+45',
  });

  @override
  final String platform;
  final String? name;
  final String? version;

  @override
  Future<String?> deviceName() async => name;

  @override
  Future<String?> appVersion() async => version;
}

void main() {
  group('device id', () {
    test('is created on first run, saved, and reused afterwards', () async {
      final store = FakeIdStore();
      var minted = 0;
      String mint() => 'minted-id-${++minted}';

      final first = await DeviceIdentity.load(
        store: store,
        probe: FakeProbe(),
        newId: mint,
      );
      final second = await DeviceIdentity.load(
        store: store,
        probe: FakeProbe(),
        newId: mint,
      );

      expect(first.deviceId, 'minted-id-1');
      expect(second.deviceId, 'minted-id-1');
      expect(minted, 1);
      expect(store.writes, 1);
    });

    test('is a real v4 uuid by default', () async {
      final id = (await DeviceIdentity.load(
        store: FakeIdStore(),
        probe: FakeProbe(),
      )).deviceId;
      expect(
        id,
        matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')),
      );
    });

    test('an id the API would reject is replaced, not sent', () async {
      for (final bad in ['short', 'has spaces in it!', 'x' * 65, '']) {
        final store = FakeIdStore(stored: bad);
        final identity = await DeviceIdentity.load(
          store: store,
          probe: FakeProbe(),
          newId: () => 'fresh-valid-id',
        );
        expect(identity.deviceId, 'fresh-valid-id', reason: 'for "$bad"');
        expect(store.stored, 'fresh-valid-id');
      }
    });

    test('an unreadable or unwritable store never stops start-up', () async {
      final unreadable = await DeviceIdentity.load(
        store: FakeIdStore(failRead: true),
        probe: FakeProbe(),
        newId: () => 'still-works-1',
      );
      expect(unreadable.deviceId, 'still-works-1');

      final unwritable = await DeviceIdentity.load(
        store: FakeIdStore(failWrite: true),
        probe: FakeProbe(),
        newId: () => 'still-works-2',
      );
      expect(unwritable.deviceId, 'still-works-2');
    });
  });

  group('what is sent', () {
    test('headers carry the platform and the build version', () async {
      final identity = await DeviceIdentity.load(
        store: FakeIdStore(stored: 'existing-id-1'),
        probe: FakeProbe(platform: 'macos', version: '1.2.3+45'),
      );
      expect(identity.headers, {
        'X-App-Platform': 'macos',
        'X-App-Version': '1.2.3+45',
      });
    });

    test('an unreadable version is left out, never faked', () async {
      final identity = await DeviceIdentity.load(
        store: FakeIdStore(stored: 'existing-id-1'),
        probe: FakeProbe(version: null),
      );
      expect(identity.headers.containsKey('X-App-Version'), isFalse);
      expect(identity.loginFields.containsKey('app_version'), isFalse);
    });

    test('login fields use the API names', () async {
      final identity = await DeviceIdentity.load(
        store: FakeIdStore(stored: 'existing-id-1'),
        probe: FakeProbe(platform: 'windows', name: 'DESKTOP-ABC'),
      );
      expect(identity.loginFields, {
        'device_id': 'existing-id-1',
        'platform': 'windows',
        'device_name': 'DESKTOP-ABC',
        'app_version': '1.2.3+45',
      });
    });

    test('the device name is trimmed and capped at 120 characters', () async {
      final long = await DeviceIdentity.load(
        store: FakeIdStore(stored: 'existing-id-1'),
        probe: FakeProbe(name: '  ${'N' * 200}  '),
      );
      expect(long.deviceName, 'N' * 120);

      final blank = await DeviceIdentity.load(
        store: FakeIdStore(stored: 'existing-id-1'),
        probe: FakeProbe(name: '   '),
      );
      expect(blank.deviceName, isNull);
      expect(blank.loginFields.containsKey('device_name'), isFalse);
    });
  });

  group('platformNameFor', () {
    test('maps every target to a value the API accepts', () {
      const accepted = {'android', 'ios', 'windows', 'macos', 'web', 'other'};
      for (final target in TargetPlatform.values) {
        expect(accepted, contains(platformNameFor(target, isWeb: false)));
      }
      expect(platformNameFor(TargetPlatform.android, isWeb: false), 'android');
      expect(platformNameFor(TargetPlatform.iOS, isWeb: false), 'ios');
      expect(platformNameFor(TargetPlatform.macOS, isWeb: false), 'macos');
      expect(platformNameFor(TargetPlatform.windows, isWeb: false), 'windows');
      expect(platformNameFor(TargetPlatform.linux, isWeb: false), 'other');
    });

    test('web wins over the target platform', () {
      expect(platformNameFor(TargetPlatform.macOS, isWeb: true), 'web');
    });
  });
}

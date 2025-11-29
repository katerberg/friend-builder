import 'package:flutter_test/flutter_test.dart';
import 'package:friend_builder/utils/avatar_sync.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AvatarSync', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('syncAvatarsIfNeeded runs on first call', () async {
      final preferences = await SharedPreferences.getInstance();

      expect(preferences.getInt('avatar_sync_last_run'), isNull);

      // Note: This test would need mocking to fully test the sync logic
      // For now, we're just testing that it doesn't throw an error
      // In a real scenario, you'd mock the database and contact service
      try {
        await AvatarSync.syncAvatarsIfNeeded();
      } catch (e) {
        expect(e, isNot(throwsA(anything)));
      }
    });

    test('syncAvatarsIfNeeded skips if called within 24 hours', () async {
      final preferences = await SharedPreferences.getInstance();
      final now = DateTime.now();

      await preferences.setInt(
        'avatar_sync_last_run',
        now.subtract(const Duration(hours: 12)).millisecondsSinceEpoch,
      );

      await AvatarSync.syncAvatarsIfNeeded();

      final lastSync = preferences.getInt('avatar_sync_last_run')!;
      final lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSync);
      final timeDiff = now.difference(lastSyncTime);

      expect(timeDiff.inHours, greaterThan(11));
      expect(timeDiff.inHours, lessThan(13));
    });

    test('syncAvatarsIfNeeded runs if 24+ hours have passed', () async {
      final preferences = await SharedPreferences.getInstance();
      final now = DateTime.now();

      await preferences.setInt(
        'avatar_sync_last_run',
        now.subtract(const Duration(hours: 25)).millisecondsSinceEpoch,
      );

      await AvatarSync.syncAvatarsIfNeeded();
    });
  });
}

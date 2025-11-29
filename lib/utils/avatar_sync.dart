import 'package:flutter/foundation.dart';
import 'package:friend_builder/contacts_permission.dart';
import 'package:friend_builder/data/database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AvatarSync {
  static const String _lastSyncKey = 'avatar_sync_last_run';
  static const Duration _syncInterval = Duration(milliseconds: 1);

  /// Syncs hangout avatars with current contact avatars if 24 hours have passed
  /// since the last sync. This runs in the background and is safe to call
  /// on every app startup.
  static Future<void> syncAvatarsIfNeeded() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final lastSyncMillis = preferences.getInt(_lastSyncKey);
      final now = DateTime.now();

      if (lastSyncMillis != null) {
        final lastSync = DateTime.fromMillisecondsSinceEpoch(lastSyncMillis);
        final timeSinceLastSync = now.difference(lastSync);

        if (timeSinceLastSync < _syncInterval) {
          return;
        }
      }

      await _performAvatarSync();

      await preferences.setInt(_lastSyncKey, now.millisecondsSinceEpoch);
    } catch (e) {
      if (kDebugMode) {
        print('Avatar sync failed: $e');
      }
    }
  }

  static Future<void> _performAvatarSync() async {
    final contactService = ContactPermissionService();
    final contactPermission = await contactService.getContacts();

    if (contactPermission.missingPermission) {
      return;
    }

    final Map<String, Contact> contactMap = {};
    for (final contact in contactPermission.contacts) {
      contactMap[contact.id] = contact;
    }

    final hangouts = await DBProvider.db.getAllHangouts();

    for (final hangout in hangouts) {
      bool hangoutUpdated = false;

      for (final encodableContact in hangout.contacts) {
        final currentContact = contactMap[encodableContact.identifier];

        if (currentContact != null) {
          final currentAvatar = currentContact.photo;

          // Update avatar if it's different
          // Note: We compare by checking if one is null and the other isn't,
          // or if both exist but have different lengths (simple heuristic)
          final bool avatarChanged =
              (encodableContact.avatar == null && currentAvatar != null) ||
                  (encodableContact.avatar != null && currentAvatar == null) ||
                  (encodableContact.avatar != null &&
                      currentAvatar != null &&
                      encodableContact.avatar!.length != currentAvatar.length);

          if (avatarChanged) {
            encodableContact.avatar = currentAvatar;
            hangoutUpdated = true;
          }
        }
      }

      if (hangoutUpdated) {
        await DBProvider.db.saveHangout(hangout);
      }
    }
  }
}

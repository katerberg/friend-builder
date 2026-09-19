import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:friend_builder/contacts_permission.dart';
import 'package:friend_builder/data/friend.dart';
import 'package:friend_builder/services/friend_catalog.dart';
import 'package:friend_builder/services/top_due_friend.dart';
import 'package:friend_builder/storage.dart';

/// Publishes the top due friend snapshot and friend catalog to the App Group
/// for WidgetKit + Siri.
class DueFriendSnapshotService {
  static const String appGroupId = 'group.com.example.friendBuilder';
  static const String iosWidgetName = 'DueFriendWidget';

  static const String keyFound = 'due_friend_found';
  static const String keyReason = 'due_friend_reason';
  static const String keyContactIdentifier = 'due_friend_contact_identifier';
  static const String keyDisplayName = 'due_friend_display_name';
  static const String keyUrgency = 'due_friend_urgency';
  static const String keyFriendCatalogJson = 'friend_catalog_json';
  static const String keyPendingHangoutsJson = 'pending_hangouts_json';

  static final Storage _storage = Storage();
  static bool _appGroupConfigured = false;

  static Future<void> configureAppGroup() async {
    if (_appGroupConfigured) {
      return;
    }
    try {
      await HomeWidget.setAppGroupId(appGroupId);
      _appGroupConfigured = true;
    } catch (error) {
      if (kDebugMode) {
        print('DueFriendSnapshotService configureAppGroup failed: $error');
      }
    }
  }

  /// Recomputes ranking, publishes App Group snapshot + friend catalog.
  /// Returns the payload (also used by live `getTopPerson`).
  static Future<Map<String, dynamic>> refreshAndReturnPayload() async {
    await configureAppGroup();
    final contactPermission =
        await ContactPermissionService().getContacts();
    final friends = await Storage.getFriends() ?? [];
    final hangouts = await _storage.getHangouts() ?? [];
    final result = resolveTopDueFriend(
      missingContactsPermission: contactPermission.missingPermission,
      contacts: contactPermission.contacts,
      friends: friends,
      hangouts: hangouts,
    );
    final payload = result.toSnapshotPayload();
    await publishSnapshot(payload);
    await publishFriendCatalog(
      friends: friends,
      contacts: contactPermission.contacts,
    );
    return payload;
  }

  /// Returns true when ranking was recomputed and published successfully.
  static Future<bool> refresh() async {
    try {
      await refreshAndReturnPayload();
      return true;
    } catch (error) {
      if (kDebugMode) {
        print('DueFriendSnapshotService refresh failed: $error');
      }
      return false;
    }
  }

  static Future<void> publishSnapshot(Map<String, dynamic> payload) async {
    await configureAppGroup();
    final found = payload['found'] == true;
    try {
      await HomeWidget.saveWidgetData<bool>(keyFound, found);
      await HomeWidget.saveWidgetData<String>(
        keyReason,
        payload['reason'] as String? ?? '',
      );
      await HomeWidget.saveWidgetData<String>(
        keyContactIdentifier,
        payload['contactIdentifier'] as String? ?? '',
      );
      await HomeWidget.saveWidgetData<String>(
        keyDisplayName,
        payload['displayName'] as String? ?? '',
      );
      await HomeWidget.saveWidgetData<String>(
        keyUrgency,
        payload['urgency'] as String? ?? '',
      );
      await HomeWidget.updateWidget(
        iOSName: iosWidgetName,
        name: iosWidgetName,
      );
    } catch (error) {
      if (kDebugMode) {
        print('DueFriendSnapshotService publishSnapshot failed: $error');
      }
      rethrow;
    }
  }

  static Future<void> publishFriendCatalog({
    required List<Friend> friends,
    required Iterable<Contact> contacts,
  }) async {
    await configureAppGroup();
    try {
      final entries = buildFriendCatalogEntries(
        friends: friends,
        contacts: contacts,
      );
      await HomeWidget.saveWidgetData<String>(
        keyFriendCatalogJson,
        encodeFriendCatalogEntries(entries),
      );
    } catch (error) {
      if (kDebugMode) {
        print('DueFriendSnapshotService publishFriendCatalog failed: $error');
      }
      rethrow;
    }
  }
}

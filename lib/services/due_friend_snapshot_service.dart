import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:friend_builder/contacts_permission.dart';
import 'package:friend_builder/services/top_due_friend.dart';
import 'package:friend_builder/storage.dart';

/// Publishes the top due friend snapshot to the App Group for WidgetKit + Siri.
class DueFriendSnapshotService {
  static const String appGroupId = 'group.com.example.friendBuilder';
  static const String iosWidgetName = 'DueFriendWidget';

  static const String keyFound = 'due_friend_found';
  static const String keyReason = 'due_friend_reason';
  static const String keyContactIdentifier = 'due_friend_contact_identifier';
  static const String keyDisplayName = 'due_friend_display_name';
  static const String keyUrgency = 'due_friend_urgency';

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

  static Future<void> refresh() async {
    await configureAppGroup();
    try {
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
      await publishSnapshot(result.toSnapshotPayload());
    } catch (error) {
      if (kDebugMode) {
        print('DueFriendSnapshotService refresh failed: $error');
      }
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
    }
  }
}

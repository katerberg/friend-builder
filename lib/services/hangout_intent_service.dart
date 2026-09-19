import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:friend_builder/contacts_permission.dart';
import 'package:friend_builder/data/encodable_contact.dart';
import 'package:friend_builder/data/hangout.dart';
import 'package:friend_builder/services/due_friend_snapshot_service.dart';
import 'package:friend_builder/services/pending_hangout.dart';
import 'package:friend_builder/storage.dart';
import 'package:home_widget/home_widget.dart';

/// Handles Siri/CarPlay MethodChannel hangout logging and App Group queue drain.
class HangoutIntentService {
  static const MethodChannel methodChannel = MethodChannel(
    'com.example.friend_builder/hangouts',
  );

  static final Storage _storage = Storage();
  static bool _methodChannelRegistered = false;

  static void registerMethodChannel() {
    if (_methodChannelRegistered) {
      return;
    }
    methodChannel.setMethodCallHandler(_handleMethodCall);
    _methodChannelRegistered = true;
  }

  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'logHangout':
        return _handleLogHangout(call.arguments);
      case 'getTopPerson':
        return getTopPerson();
      default:
        throw PlatformException(
          code: 'unsupported_method',
          message: 'Unsupported method ${call.method}',
        );
    }
  }

  static Future<Map<String, dynamic>> _handleLogHangout(
    dynamic arguments,
  ) async {
    if (arguments is! Map) {
      throw PlatformException(
        code: 'invalid_arguments',
        message: 'logHangout expects a map argument',
      );
    }
    final contactIdentifier =
        arguments['contactIdentifier'] as String? ?? '';
    final pendingId = arguments['pendingId'] as String? ?? '';
    final displayName = arguments['displayName'] as String? ?? '';
    if (contactIdentifier.isEmpty) {
      throw PlatformException(
        code: 'missing_contact',
        message: 'contactIdentifier is required',
      );
    }
    await logHangout(
      contactIdentifier: contactIdentifier,
      displayName: displayName,
      pendingId: pendingId,
    );
    return {'ok': true};
  }

  /// Live ranking for warm Flutter (Siri / CarPlay). Also refreshes App Group.
  static Future<Map<String, dynamic>> getTopPerson() async {
    return DueFriendSnapshotService.refreshAndReturnPayload();
  }

  static Future<void> logHangout({
    required String contactIdentifier,
    String displayName = '',
    String pendingId = '',
  }) async {
    final contact = await _resolveContact(
      contactIdentifier: contactIdentifier,
      displayName: displayName,
    );
    await _storage.createHangout(
      Hangout(
        contacts: [contact],
        notes: '',
        when: DateTime.now(),
        isAllDay: false,
      ),
    );
    if (pendingId.isNotEmpty) {
      await removePendingHangout(pendingId);
    }
    // Close the ranking/Siri snapshot loop after a durable hangout commit.
    // createHangout already refreshes; this second pass guarantees the App
    // Group reflects the hangout even if the first publish raced or failed.
    final refreshed = await DueFriendSnapshotService.refresh();
    if (!refreshed && kDebugMode) {
      print('HangoutIntentService snapshot refresh failed after logHangout');
    }
  }

  static Future<EncodableContact> _resolveContact({
    required String contactIdentifier,
    required String displayName,
  }) async {
    final contactPermission =
        await ContactPermissionService().getContacts();
    if (!contactPermission.missingPermission) {
      for (final contact in contactPermission.contacts) {
        if (contact.id == contactIdentifier) {
          return EncodableContact.fromContact(contact);
        }
      }
    }
    final resolvedDisplayName =
        displayName.trim().isEmpty ? 'Friend' : displayName.trim();
    return EncodableContact(
      displayName: resolvedDisplayName,
      middleName: '',
      givenName: '',
      identifier: contactIdentifier,
      familyName: '',
    );
  }

  static Future<void> drainPendingHangouts() async {
    await DueFriendSnapshotService.configureAppGroup();
    try {
      final pendingJson = await HomeWidget.getWidgetData<String>(
        DueFriendSnapshotService.keyPendingHangoutsJson,
      );
      final pendingItems = parsePendingHangouts(pendingJson);
      if (pendingItems.isEmpty) {
        return;
      }

      final remainingItems = <PendingHangoutItem>[];
      var committedAny = false;
      for (final item in pendingItems) {
        try {
          await logHangout(
            contactIdentifier: item.contactIdentifier,
            displayName: item.displayName,
          );
          committedAny = true;
        } catch (error) {
          remainingItems.add(item);
          if (kDebugMode) {
            print('HangoutIntentService drain item failed: $error');
          }
        }
      }

      await HomeWidget.saveWidgetData<String>(
        DueFriendSnapshotService.keyPendingHangoutsJson,
        encodePendingHangouts(remainingItems),
      );

      if (committedAny) {
        await DueFriendSnapshotService.refresh();
      }
    } catch (error) {
      if (kDebugMode) {
        print('HangoutIntentService drainPendingHangouts failed: $error');
      }
    }
  }

  static Future<void> removePendingHangout(String pendingId) async {
    await DueFriendSnapshotService.configureAppGroup();
    try {
      final pendingJson = await HomeWidget.getWidgetData<String>(
        DueFriendSnapshotService.keyPendingHangoutsJson,
      );
      final remaining = removePendingHangoutById(
        items: parsePendingHangouts(pendingJson),
        pendingId: pendingId,
      );
      await HomeWidget.saveWidgetData<String>(
        DueFriendSnapshotService.keyPendingHangoutsJson,
        encodePendingHangouts(remaining),
      );
    } catch (error) {
      if (kDebugMode) {
        print('HangoutIntentService removePendingHangout failed: $error');
      }
    }
  }
}

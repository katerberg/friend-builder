import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:friend_builder/contacts_permission.dart';
import 'package:friend_builder/data/database.dart';
import 'package:friend_builder/data/encodable_contact.dart';
import 'package:friend_builder/data/hangout.dart';
import 'package:friend_builder/services/due_friend_snapshot_service.dart';
import 'package:friend_builder/services/native_projection_service.dart';
import 'package:friend_builder/services/pending_hangout.dart';
import 'package:friend_builder/storage.dart';
import 'package:home_widget/home_widget.dart';

/// Handles Siri/CarPlay MethodChannel hangout logging and App Group queue drain.
class HangoutIntentService {
  static const MethodChannel methodChannel = MethodChannel(
    'com.example.friend_builder/hangouts',
  );

  /// Matches iOS `PendingHangoutStore.keyPendingJson`.
  static const String keyPendingHangoutsJson = 'pending_hangouts_json';

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
        // CarPlay / warm callers only. Siri uses queue-only + drain.
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
    return NativeProjectionService.refreshAndReturnPayload();
  }

  static Future<void> logHangout({
    required String contactIdentifier,
    String displayName = '',
    String pendingId = '',
    bool refreshProjection = true,
  }) async {
    if (pendingId.isNotEmpty) {
      await _commitPendingHangout(
        pendingId: pendingId,
        contactIdentifier: contactIdentifier,
        displayName: displayName,
      );
    } else {
      await _createHangoutForContact(
        contactIdentifier: contactIdentifier,
        displayName: displayName,
      );
    }
    if (refreshProjection) {
      final refreshed = await NativeProjectionService.refreshNow();
      if (!refreshed) {
        if (kDebugMode) {
          print(
            'HangoutIntentService snapshot refresh failed after logHangout',
          );
        }
      }
    }
  }

  /// Claim → create → remove-one from queue (reload+filter, never batch rewrite).
  /// Returns true when a new hangout was written.
  static Future<bool> _commitPendingHangout({
    required String pendingId,
    required String contactIdentifier,
    required String displayName,
  }) async {
    final claimed =
        await DBProvider.db.claimProcessedPendingHangout(pendingId);
    if (!claimed) {
      await removePendingHangout(pendingId);
      return false;
    }
    try {
      await _createHangoutForContact(
        contactIdentifier: contactIdentifier,
        displayName: displayName,
      );
    } catch (error) {
      await DBProvider.db.releaseProcessedPendingHangout(pendingId);
      rethrow;
    }
    await removePendingHangout(pendingId);
    return true;
  }

  static Future<void> _createHangoutForContact({
    required String contactIdentifier,
    required String displayName,
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
  }

  static Future<EncodableContact> _resolveContact({
    required String contactIdentifier,
    required String displayName,
  }) async {
    final contactPermission =
        await ContactPermissionService().getContacts();
    if (!contactPermission.missingPermission) {
      for (final contact in contactPermission.contacts) {
        if (contact.safeId == contactIdentifier) {
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
        keyPendingHangoutsJson,
      );
      final pendingItems = parsePendingHangouts(pendingJson);
      if (pendingItems.isEmpty) {
        return;
      }

      var committedAny = false;
      for (final item in pendingItems) {
        try {
          final didCommit = await _commitPendingHangout(
            pendingId: item.pendingId,
            contactIdentifier: item.contactIdentifier,
            displayName: item.displayName,
          );
          if (didCommit) {
            committedAny = true;
          }
        } catch (error) {
          if (kDebugMode) {
            print('HangoutIntentService drain item failed: $error');
          }
        }
      }

      if (committedAny) {
        await NativeProjectionService.refreshNow();
      }
    } catch (error) {
      if (kDebugMode) {
        print('HangoutIntentService drainPendingHangouts failed: $error');
      }
    }
  }

  /// Reloads the current queue and removes only [pendingId] (merge-safe).
  static Future<void> removePendingHangout(String pendingId) async {
    await DueFriendSnapshotService.configureAppGroup();
    try {
      final pendingJson = await HomeWidget.getWidgetData<String>(
        keyPendingHangoutsJson,
      );
      final remaining = removePendingHangoutById(
        items: parsePendingHangouts(pendingJson),
        pendingId: pendingId,
      );
      await HomeWidget.saveWidgetData<String>(
        keyPendingHangoutsJson,
        encodePendingHangouts(remaining),
      );
    } catch (error) {
      if (kDebugMode) {
        print('HangoutIntentService removePendingHangout failed: $error');
      }
    }
  }
}

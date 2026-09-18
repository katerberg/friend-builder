import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:friend_builder/contacts_permission.dart';
import 'package:friend_builder/data/encodable_contact.dart';
import 'package:friend_builder/data/hangout.dart';
import 'package:friend_builder/services/carplay_top_person.dart';
import 'package:friend_builder/storage.dart';
import 'package:friend_builder/utils/notification_helper.dart';

/// Dart side of the CarPlay MethodChannel (`friend_builder/carplay`).
///
/// Native owns templates and `tel:` open; Dart owns ranking, photos, and
/// hangout writes.
class CarPlayService {
  static const MethodChannel channel = MethodChannel('friend_builder/carplay');

  static final Storage _storage = Storage();
  static FlutterLocalNotificationsPlugin? _notificationsPlugin;
  static bool _isRegistered = false;

  static void register({
    required FlutterLocalNotificationsPlugin notificationsPlugin,
  }) {
    _notificationsPlugin = notificationsPlugin;
    if (_isRegistered) {
      return;
    }
    _isRegistered = true;
    channel.setMethodCallHandler(_handleMethodCall);
  }

  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'getTopPerson':
        return getTopPersonPayload();
      case 'logHangout':
        final arguments = call.arguments;
        if (arguments is! Map) {
          return {'ok': false, 'error': 'invalid_arguments'};
        }
        final contactIdentifier = arguments['contactIdentifier'];
        if (contactIdentifier is! String || contactIdentifier.isEmpty) {
          return {'ok': false, 'error': 'missing_contact_identifier'};
        }
        return logHangoutForContact(contactIdentifier);
      default:
        throw PlatformException(
          code: 'unimplemented',
          message: 'Method ${call.method} is not implemented',
        );
    }
  }

  static Future<Map<String, dynamic>> getTopPersonPayload() async {
    try {
      final contactPermission =
          await ContactPermissionService().getContacts();
      final friends = await Storage.getFriends() ?? [];
      final hangouts = await _storage.getHangouts() ?? [];
      final result = await resolveCarPlayTopPerson(
        missingContactsPermission: contactPermission.missingPermission,
        contacts: contactPermission.contacts,
        friends: friends,
        hangouts: hangouts,
        loadPhoto: ContactPermissionService.getContactPhoto,
      );
      return result.toChannelPayload();
    } catch (error) {
      if (kDebugMode) {
        print('CarPlay getTopPerson failed: $error');
      }
      return {'found': false, 'reason': 'error'};
    }
  }

  static Future<Map<String, dynamic>> logHangoutForContact(
    String contactIdentifier,
  ) async {
    try {
      final contactPermission =
          await ContactPermissionService().getContacts();
      if (contactPermission.missingPermission) {
        return {'ok': false, 'error': 'contacts_permission'};
      }

      Contact? matchedContact;
      for (final contact in contactPermission.contacts) {
        if (contact.id == contactIdentifier) {
          matchedContact = contact;
          break;
        }
      }
      if (matchedContact == null) {
        return {'ok': false, 'error': 'contact_not_found'};
      }

      final hangout = Hangout(
        contacts: [EncodableContact.fromContact(matchedContact)],
        when: DateTime.now(),
        notes: '',
        isAllDay: false,
      );
      await _storage.createHangout(hangout);

      final notificationsPlugin = _notificationsPlugin;
      if (notificationsPlugin != null) {
        await clearSnoozeRemindersForContacts(
          [contactIdentifier],
          notificationsPlugin,
        );
      }

      return {'ok': true};
    } catch (error) {
      if (kDebugMode) {
        print('CarPlay logHangout failed: $error');
      }
      return {'ok': false, 'error': 'exception'};
    }
  }

  /// Ask native CarPlay UI to re-fetch the top person and update templates.
  static Future<void> notifyRefresh() async {
    if (!_isRegistered) {
      return;
    }
    try {
      await channel.invokeMethod<void>('refresh');
    } on MissingPluginException {
      // Native CarPlay bridge not present (e.g. Android / tests).
    } catch (error) {
      if (kDebugMode) {
        print('CarPlay notifyRefresh failed: $error');
      }
    }
  }
}

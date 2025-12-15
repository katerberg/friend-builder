import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:friend_builder/data/database.dart';
import 'package:friend_builder/data/encodable_contact.dart';
import 'package:friend_builder/data/hangout.dart';
import 'package:friend_builder/utils/notification_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _calendarSyncEnabledKey = 'calendar_sync_enabled';

class CalendarSync {
  static final DeviceCalendarPlugin _deviceCalendarPlugin =
      DeviceCalendarPlugin();

  static Future<bool> checkCalendarPermission() async {
    var permissionsGranted = await _deviceCalendarPlugin.hasPermissions();
    final hasPermission =
        permissionsGranted.isSuccess && permissionsGranted.data == true;
    if (kDebugMode) {
      print(
          'Calendar permission check: isSuccess=${permissionsGranted.isSuccess}, data=${permissionsGranted.data}, hasPermission=$hasPermission');
    }
    return hasPermission;
  }

  static Future<bool> requestCalendarPermission() async {
    var permissionsGranted = await _deviceCalendarPlugin.hasPermissions();
    if (permissionsGranted.isSuccess && permissionsGranted.data == true) {
      return true;
    }

    var requestResult = await _deviceCalendarPlugin.requestPermissions();
    return requestResult.isSuccess && requestResult.data == true;
  }

  static Future<bool> isCalendarSyncEnabled() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_calendarSyncEnabledKey) ?? false;
  }

  static Future<List<String>> _getExcludedContacts() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getStringList('excluded_calendar_contacts') ?? [];
  }

  static Future<void> syncCalendarEvents(
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
  ) async {
    try {
      final isEnabled = await isCalendarSyncEnabled();
      if (!isEnabled) {
        if (kDebugMode) {
          print('Calendar sync is disabled');
        }
        return;
      }

      final hasPermission = await requestCalendarPermission();
      if (!hasPermission) {
        if (kDebugMode) {
          print('Calendar permission not granted');
        }
        return;
      }

      final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      if (!calendarsResult.isSuccess || calendarsResult.data == null) {
        if (kDebugMode) {
          print('Failed to retrieve calendars');
        }
        return;
      }

      final friends = await DBProvider.db.getAllFriends();
      if (friends.isEmpty) {
        if (kDebugMode) {
          print('No friends to match against');
        }
        return;
      }

      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      final excludedContactIds = await _getExcludedContacts();
      final friendIdentifiers = friends.map((f) => f.contactIdentifier).toSet();

      final contactsByEmail = <String, Contact>{};
      for (var contact in contacts) {
        if (excludedContactIds.contains(contact.id)) {
          continue;
        }
        for (var email in contact.emails) {
          final normalizedEmail = email.address.toLowerCase().trim();
          if (normalizedEmail.isNotEmpty) {
            contactsByEmail[normalizedEmail] = contact;
          }
        }
      }

      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));

      bool createdAnyHangouts = false;

      for (var calendar in calendarsResult.data!) {
        final eventsResult = await _deviceCalendarPlugin.retrieveEvents(
          calendar.id,
          RetrieveEventsParams(
            startDate: sevenDaysAgo,
            endDate: now,
          ),
        );

        if (!eventsResult.isSuccess || eventsResult.data == null) {
          continue;
        }

        for (var event in eventsResult.data!) {
          if (event.eventId == null) continue;

          final alreadySynced =
              await DBProvider.db.isEventSynced(event.eventId!);
          if (alreadySynced) continue;

          if (event.attendees == null || event.attendees!.isEmpty) continue;

          final matchedFriendContacts = <Contact>[];

          for (var attendee in event.attendees!) {
            if (attendee == null || attendee.emailAddress == null) continue;

            final normalizedEmail = attendee.emailAddress!.toLowerCase().trim();
            final matchedContact = contactsByEmail[normalizedEmail];

            if (matchedContact != null &&
                friendIdentifiers.contains(matchedContact.id)) {
              matchedFriendContacts.add(matchedContact);
            }
          }

          if (matchedFriendContacts.isEmpty) {
            await DBProvider.db.markEventAsSynced(event.eventId!);
            continue;
          }

          final hangout = Hangout(
            contacts: matchedFriendContacts
                .map((c) => EncodableContact.fromContact(c))
                .toList(),
            notes: 'Calendar: ${event.title ?? "Event"}',
            when: event.start ?? now,
          );

          await DBProvider.db.saveHangout(hangout);
          await DBProvider.db.markEventAsSynced(event.eventId!);
          createdAnyHangouts = true;

          if (kDebugMode) {
            print(
                'Created hangout from calendar event: ${event.title} with ${matchedFriendContacts.length} friends');
          }
        }
      }

      if (createdAnyHangouts) {
        await scheduleNextNotification(flutterLocalNotificationsPlugin);
        if (kDebugMode) {
          print('Rescheduled notifications after calendar sync');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing calendar events: $e');
      }
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:friend_builder/contacts_permission.dart';
import 'package:friend_builder/data/hangout.dart';
import 'package:friend_builder/data/database.dart';
import 'package:friend_builder/data/snooze_reminder.dart';
import 'package:friend_builder/utils/scheduling.dart';
import 'package:rxdart/rxdart.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:friend_builder/data/reminder_notification.dart';
import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';

final BehaviorSubject<ReminderNotification> didReceiveLocalNotificationSubject =
    BehaviorSubject<ReminderNotification>();

final BehaviorSubject<String> selectNotificationSubject =
    BehaviorSubject<String>();

const int _nextNotificationId = 999999;
const int _inactivityNotificationId = 999998;
const int _snoozeNotificationBaseId = 900000;
const int _maxSnoozeNotifications = 50;
const String _lastLoginKey = 'last_login_time';
const String snoozeActionId = 'snooze_action';
const String _friendReminderCategoryId = 'friendReminderCategory';

Future<void> initNotifications(
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
  var initializationSettingsAndroid =
      const AndroidInitializationSettings('app_icon');

  final darwinNotificationCategories = <DarwinNotificationCategory>[
    DarwinNotificationCategory(
      _friendReminderCategoryId,
      actions: <DarwinNotificationAction>[
        DarwinNotificationAction.plain(
          snoozeActionId,
          'Snooze',
          options: <DarwinNotificationActionOption>{
            DarwinNotificationActionOption.foreground,
          },
        ),
      ],
      options: <DarwinNotificationCategoryOption>{
        DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
      },
    ),
  ];

  var initializationSettingsIOS = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
    notificationCategories: darwinNotificationCategories,
  );
  var initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid, iOS: initializationSettingsIOS);

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      await _handleNotificationResponse(
          response, flutterLocalNotificationsPlugin);
    },
  );

  await updateLastLoginTime();
  await scheduleNextNotification(flutterLocalNotificationsPlugin);
  await scheduleInactivityNotification(flutterLocalNotificationsPlugin);
}

Future<void> _handleNotificationResponse(NotificationResponse response,
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
  final actionId = response.actionId;
  final payload = response.payload;

  if (actionId == snoozeActionId && payload != null) {
    await _handleSnoozeAction(payload, flutterLocalNotificationsPlugin);
  }

  await scheduleNextNotification(flutterLocalNotificationsPlugin);
  await scheduleInactivityNotification(flutterLocalNotificationsPlugin);
}

Future<void> _handleSnoozeAction(String contactIdentifier,
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
  try {
    await DBProvider.db.deleteSnoozeRemindersForContact(contactIdentifier);

    final snoozeUntil = DateTime.now().add(const Duration(hours: 24));
    final snoozeReminder = SnoozeReminder(
      contactIdentifier: contactIdentifier,
      snoozeUntil: snoozeUntil,
    );
    await DBProvider.db.saveSnoozeReminder(snoozeReminder);
  } catch (e) {
    if (kDebugMode) {
      print('Error handling snooze action: $e');
    }
  }
}

void requestIOSPermissions(
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) {
  flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
}

Future<void> _cancelNotification(
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin, int id) {
  return flutterLocalNotificationsPlugin.cancel(id);
}

Future<void> _cancelAllSnoozeNotifications(
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
  for (var i = 0; i < _maxSnoozeNotifications; i++) {
    await flutterLocalNotificationsPlugin.cancel(_snoozeNotificationBaseId + i);
  }
}

Future<void> _scheduleNotification(
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
    int id,
    String title,
    String body,
    DateTime scheduledNotificationDateTime) async {
  requestIOSPermissions(flutterLocalNotificationsPlugin);
  var androidPlatformChannelSpecifics = AndroidNotificationDetails(
    "$id",
    'Reminder notifications',
    channelDescription: 'Remember about it',
    icon: 'app_icon',
  );
  var iOSPlatformChannelSpecifics = const DarwinNotificationDetails();
  var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics);
  await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledNotificationDateTime, tz.UTC),
      platformChannelSpecifics,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime);
}

Future<void> _scheduleNotificationWithActions(
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
    int id,
    String title,
    String body,
    DateTime scheduledNotificationDateTime,
    String contactIdentifier) async {
  requestIOSPermissions(flutterLocalNotificationsPlugin);

  const List<AndroidNotificationAction> androidActions = [
    AndroidNotificationAction(
      snoozeActionId,
      'Snooze',
      showsUserInterface: false,
    ),
  ];

  var androidPlatformChannelSpecifics = AndroidNotificationDetails(
    "$id",
    'Reminder notifications',
    channelDescription: 'Remember about it',
    icon: 'app_icon',
    actions: androidActions,
  );

  var iOSPlatformChannelSpecifics = const DarwinNotificationDetails(
    categoryIdentifier: _friendReminderCategoryId,
  );

  var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledNotificationDateTime, tz.UTC),
      platformChannelSpecifics,
      payload: contactIdentifier,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime);
}

Future<void> updateLastLoginTime() async {
  try {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
        _lastLoginKey, DateTime.now().toIso8601String());
  } catch (e) {
    if (kDebugMode) {
      print('Error updating last login time: $e');
    }
  }
}

Future<void> scheduleInactivityNotification(
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
  try {
    final preferences = await SharedPreferences.getInstance();
    final lastLoginString = preferences.getString(_lastLoginKey);

    if (lastLoginString == null) {
      return;
    }

    final lastLoginTime = DateTime.parse(lastLoginString);
    final notificationTime = lastLoginTime.add(const Duration(days: 7));

    if (notificationTime.isAfter(DateTime.now())) {
      await _cancelNotification(
          flutterLocalNotificationsPlugin, _inactivityNotificationId);

      await _scheduleNotification(
        flutterLocalNotificationsPlugin,
        _inactivityNotificationId,
        'We miss you!',
        "It's been a while since you checked in. Time to catch up with friends?",
        notificationTime,
      );
    } else {
      await _cancelNotification(
          flutterLocalNotificationsPlugin, _inactivityNotificationId);
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error scheduling inactivity notification: $e');
    }
  }
}

Future<void> scheduleNextNotification(
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
  try {
    final friends = await DBProvider.db.getAllFriends();
    final hangouts = await DBProvider.db.getAllHangouts();
    final activeSnoozeReminders =
        await DBProvider.db.getActiveSnoozeReminders();

    final snoozedContactIdentifiers =
        activeSnoozeReminders.map((s) => s.contactIdentifier).toSet();

    final contactableFriends = friends
        .where((f) =>
            f.isContactable &&
            !snoozedContactIdentifiers.contains(f.contactIdentifier))
        .toList();

    if (contactableFriends.isEmpty) {
      await _cancelNotification(
          flutterLocalNotificationsPlugin, _nextNotificationId);
      return;
    }

    final contactPermissionService = ContactPermissionService();
    final contactPermission = await contactPermissionService.getContacts();
    final phoneContacts = contactPermission.contacts.toList();

    if (phoneContacts.isEmpty) {
      await _cancelNotification(
          flutterLocalNotificationsPlugin, _nextNotificationId);
      return;
    }

    DateTime? earliestTime;
    String? earliestFriendName;
    String? earliestContactIdentifier;

    for (var friend in contactableFriends) {
      final contact = phoneContacts.firstWhereOrNull(
        (c) => c.id == friend.contactIdentifier,
      );
      if (contact == null) {
        continue;
      }

      List<Hangout> friendHangouts = hangouts
          .where((h) =>
              h.contacts.any((c) => c.identifier == friend.contactIdentifier))
          .toList();

      DateTime latestHangoutTime = friendHangouts.isEmpty
          ? DateTime.now()
          : friendHangouts
              .reduce((a, b) => a.when.compareTo(b.when) > 0 ? a : b)
              .when;

      DateTime nextNotificationTime =
          Scheduling.howLong(latestHangoutTime, friend.frequency);

      if (nextNotificationTime.isAfter(DateTime.now())) {
        if (earliestTime == null ||
            nextNotificationTime.isBefore(earliestTime)) {
          earliestTime = nextNotificationTime;
          earliestFriendName = contact.displayName;
          earliestContactIdentifier = friend.contactIdentifier;
        }
      }
    }

    if (earliestTime != null &&
        earliestFriendName != null &&
        earliestContactIdentifier != null) {
      await _cancelNotification(
          flutterLocalNotificationsPlugin, _nextNotificationId);

      await _scheduleNotificationWithActions(
        flutterLocalNotificationsPlugin,
        _nextNotificationId,
        'Want to chat with $earliestFriendName?',
        "It's been a minute!",
        earliestTime,
        earliestContactIdentifier,
      );
    }

    await scheduleSnoozeNotifications(flutterLocalNotificationsPlugin);
  } catch (e) {
    if (kDebugMode) {
      print('Error scheduling next notification: $e');
    }
  }
}

Future<void> scheduleSnoozeNotifications(
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
  try {
    await _cancelAllSnoozeNotifications(flutterLocalNotificationsPlugin);

    await DBProvider.db.deleteExpiredSnoozeReminders();

    final snoozeReminders = await DBProvider.db.getActiveSnoozeReminders();

    if (snoozeReminders.isEmpty) {
      return;
    }

    final contactPermissionService = ContactPermissionService();
    final contactPermission = await contactPermissionService.getContacts();
    final phoneContacts = contactPermission.contacts.toList();

    for (var i = 0; i < snoozeReminders.length; i++) {
      final reminder = snoozeReminders[i];

      if (!reminder.snoozeUntil.isAfter(DateTime.now())) {
        continue;
      }

      final contact = phoneContacts.firstWhereOrNull(
        (c) => c.id == reminder.contactIdentifier,
      );

      if (contact == null) {
        await DBProvider.db
            .deleteSnoozeRemindersForContact(reminder.contactIdentifier);
        continue;
      }

      final notificationId = _snoozeNotificationBaseId + i;

      await _scheduleNotificationWithActions(
        flutterLocalNotificationsPlugin,
        notificationId,
        'Reminder: Chat with ${contact.displayName}?',
        "You snoozed this reminder!",
        reminder.snoozeUntil,
        reminder.contactIdentifier,
      );
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error scheduling snooze notifications: $e');
    }
  }
}

Future<void> clearSnoozeRemindersForContacts(List<String> contactIdentifiers,
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
  try {
    for (var contactIdentifier in contactIdentifiers) {
      await DBProvider.db.deleteSnoozeRemindersForContact(contactIdentifier);
    }
    await scheduleNextNotification(flutterLocalNotificationsPlugin);
  } catch (e) {
    if (kDebugMode) {
      print('Error clearing snooze reminders: $e');
    }
  }
}

Future<void> scheduleTestNotification(
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
    String title,
    String body,
    DateTime scheduledTime,
    String contactIdentifier) async {
  const int testNotificationId = 888888;

  await _scheduleNotificationWithActions(
    flutterLocalNotificationsPlugin,
    testNotificationId,
    title,
    body,
    scheduledTime,
    contactIdentifier,
  );
}

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:friend_builder/contacts_permission.dart';
import 'package:friend_builder/data/hangout.dart';
import 'package:friend_builder/data/database.dart';
import 'package:friend_builder/utils/scheduling.dart';
import 'package:rxdart/rxdart.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:friend_builder/data/reminder_notification.dart';
import 'package:collection/collection.dart';

final BehaviorSubject<ReminderNotification> didReceiveLocalNotificationSubject =
    BehaviorSubject<ReminderNotification>();

final BehaviorSubject<String> selectNotificationSubject =
    BehaviorSubject<String>();

const int _nextNotificationId =
    999999; // Use a fixed ID for the rolling notification

Future<void> initNotifications(
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
  var initializationSettingsAndroid =
      const AndroidInitializationSettings('app_icon');
  var initializationSettingsIOS = const DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );
  var initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid, iOS: initializationSettingsIOS);

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      await scheduleNextNotification(flutterLocalNotificationsPlugin);
    },
  );

  await scheduleNextNotification(flutterLocalNotificationsPlugin);
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

Future<void> scheduleNextNotification(
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
  try {
    final friends = await DBProvider.db.getAllFriends();
    final hangouts = await DBProvider.db.getAllHangouts();

    final contactableFriends = friends.where((f) => f.isContactable).toList();

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

      // Only consider notification times in the future
      if (nextNotificationTime.isAfter(DateTime.now())) {
        if (earliestTime == null ||
            nextNotificationTime.isBefore(earliestTime)) {
          earliestTime = nextNotificationTime;
          earliestFriendName = contact.displayName;
        }
      }
    }

    if (earliestTime != null && earliestFriendName != null) {
      await _cancelNotification(
          flutterLocalNotificationsPlugin, _nextNotificationId);

      await _scheduleNotification(
        flutterLocalNotificationsPlugin,
        _nextNotificationId,
        'Want to chat with $earliestFriendName?',
        "It's been a minute!",
        earliestTime,
      );
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error scheduling next notification: $e');
    }
  }
}

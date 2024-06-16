import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:friend_builder/contacts_permission.dart';
import 'package:friend_builder/data/friend.dart';
import 'package:friend_builder/data/hangout.dart';
import 'package:friend_builder/utils/scheduling.dart';
import 'package:rxdart/rxdart.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:friend_builder/data/reminder_notification.dart';

final BehaviorSubject<ReminderNotification> didReceiveLocalNotificationSubject =
    BehaviorSubject<ReminderNotification>();

final BehaviorSubject<String> selectNotificationSubject =
    BehaviorSubject<String>();

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
  );
}

Future<void> cancelNotification(
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin, int id) {
  return flutterLocalNotificationsPlugin.cancel(id);
}

Future<void> scheduleNotification(
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

void upsertNotifications(
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
    List<Hangout> hangouts,
    Friend result,
    Contact contact) {
  List<Hangout> contactHangouts = hangouts
      .where((element) =>
          element.contacts.any((hc) => hc.identifier == contact.id))
      .toList();
  DateTime latestTime = contactHangouts.isEmpty
      ? DateTime.now()
      : contactHangouts
          .reduce((value, element) =>
              element.when.compareTo(value.when) > 0 ? element : value)
          .when;
  scheduleNotification(
    flutterLocalNotificationsPlugin,
    contact.id.hashCode,
    'Want to chat with ${contact.displayName}?',
    "It's been a minute!",
    Scheduling.howLong(latestTime, result.frequency),
  );
}

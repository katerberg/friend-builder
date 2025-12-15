import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:friend_builder/router.dart';
import 'package:friend_builder/utils/notification_helper.dart';
import 'package:friend_builder/utils/debug_data.dart';
import 'package:friend_builder/utils/avatar_sync.dart';
import 'package:friend_builder/utils/calendar_sync.dart';
import 'package:friend_builder/shared/settings_modal.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

bool backgroundFetchFailed = false;

@pragma('vm:entry-point')
void backgroundFetchHeadlessTask(HeadlessTask task) async {
  final taskId = task.taskId;
  final isTimeout = task.timeout;

  if (isTimeout) {
    BackgroundFetch.finish(taskId);
    return;
  }

  final notificationsPlugin = FlutterLocalNotificationsPlugin();
  await CalendarSync.syncCalendarEvents(notificationsPlugin);

  BackgroundFetch.finish(taskId);
}

Future<bool> initBackgroundFetch() async {
  try {
    final status = await BackgroundFetch.configure(
      BackgroundFetchConfig(
        minimumFetchInterval: 60,
        stopOnTerminate: false,
        enableHeadless: true,
        startOnBoot: false,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresStorageNotLow: false,
        requiresDeviceIdle: false,
        requiredNetworkType: NetworkType.NONE,
      ),
      (String taskId) async {
        if (kDebugMode) {
          print('Background fetch event received: $taskId');
        }
        await CalendarSync.syncCalendarEvents(flutterLocalNotificationsPlugin);
        BackgroundFetch.finish(taskId);
      },
      (String taskId) async {
        if (kDebugMode) {
          print('Background fetch timeout: $taskId');
        }
        BackgroundFetch.finish(taskId);
      },
    );

    if (status == BackgroundFetch.STATUS_DENIED ||
        status == BackgroundFetch.STATUS_RESTRICTED) {
      if (kDebugMode) {
        print('Background fetch is disabled: $status');
      }
      return false;
    }

    BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
    return true;
  } catch (e) {
    if (kDebugMode) {
      print('Error initializing background fetch: $e');
    }
    return false;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initNotifications(flutterLocalNotificationsPlugin);

  await DebugData.removeDebugHangouts();
  await DebugData.removeDebugContacts();
  // await DebugData.populateFakeContactsIfNeeded();
  // await DebugData.populateFakeHangoutsIfNeeded();

  AvatarSync.syncAvatarsIfNeeded();

  final calendarSyncEnabled = await SettingsModal.isCalendarSyncEnabled();
  if (calendarSyncEnabled) {
    final backgroundFetchSuccess = await initBackgroundFetch();
    backgroundFetchFailed = !backgroundFetchSuccess;
  }

  CalendarSync.syncCalendarEvents(flutterLocalNotificationsPlugin);

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});
  static const String _title = 'Friend Crafter';

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF2898D5);
    return MaterialApp(
        title: _title,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: color,
            primary: color,
          ),
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: FriendRouter(
          flutterLocalNotificationsPlugin: flutterLocalNotificationsPlugin,
        ));
  }
}

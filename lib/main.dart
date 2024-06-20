import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:friend_builder/router.dart';
import 'package:friend_builder/utils/notification_helper.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initNotifications(flutterLocalNotificationsPlugin);

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

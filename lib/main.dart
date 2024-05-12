import 'package:flutter/material.dart';
import 'package:friend_builder/router.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});
  static const String _title = 'Friend Crafter';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: _title,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const FriendRouter());
  }
}

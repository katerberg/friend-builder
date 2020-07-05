import 'package:flutter/material.dart';
import 'package:friend_builder/navigationBar.dart';

void main() => runApp(FriendBuilderApp());

class FriendBuilderApp extends StatelessWidget {
  static const String _title = 'Friend Builder';

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: NavigationBar(),
    );
  }
}

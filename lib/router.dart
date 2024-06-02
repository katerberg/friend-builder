import 'dart:async';
import 'package:friend_builder/pages/start_screen.dart';
import 'package:friend_builder/pages/splash_screen.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:friend_builder/pages/friends/friends_page.dart';
import 'package:friend_builder/pages/log/log_page.dart';
import 'package:friend_builder/pages/history/history_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FriendRouter extends StatefulWidget {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  const FriendRouter({
    super.key,
    required this.flutterLocalNotificationsPlugin,
  });

  @override
  State<FriendRouter> createState() => _FriendRouterState();
}

class _FriendRouterState extends State<FriendRouter> {
  var selectedIndex = 1;

  bool? firstTime;
  late Future _googleFontsPending;

  void navigationPageHome() {}

  Future<void> _handleFirstLoad() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();

    Timer(const Duration(seconds: 1), () {
      if (preferences.getBool('first_time') ?? true) {
        preferences.setBool('first_time', false);
        setState(() {
          firstTime = true;
        });
      } else {
        setState(() {
          firstTime = false;
        });
      }
    });
  }

  @override
  void initState() {
    _googleFontsPending =
        GoogleFonts.pendingFonts([GoogleFonts.londrinaSketch]);
    _handleFirstLoad();
    super.initState();
  }

  void _changeTab(int tabIndex) async {
    setState(() {
      selectedIndex = tabIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = HistoryPage(
            flutterLocalNotificationsPlugin:
                widget.flutterLocalNotificationsPlugin);
      case 1:
        page = LogPage(
            onSubmit: () => _changeTab(0),
            flutterLocalNotificationsPlugin:
                widget.flutterLocalNotificationsPlugin);
      case 2:
        page = FriendsPage(
            flutterLocalNotificationsPlugin:
                widget.flutterLocalNotificationsPlugin);
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    var mainArea = ColoredBox(
        color: colorScheme.surfaceVariant,
        child: AnimatedSwitcher(duration: Durations.medium1, child: page));

    Widget content;
    if (firstTime == null) {
      content = SplashScreen(
        googleFontsPending: _googleFontsPending,
      );
    } else if (firstTime == true) {
      content = Column(
        children: [
          Expanded(
            child: StartScreen(
                googleFontsPending: _googleFontsPending,
                onSubmit: () {
                  setState(() {
                    firstTime = false;
                  });
                  _changeTab(1);
                },
                flutterLocalNotificationsPlugin:
                    widget.flutterLocalNotificationsPlugin),
          ),
        ],
      );
    } else {
      content = Column(children: [
        Expanded(child: mainArea),
        BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.note_add,
              ),
              label: 'Log',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Friends',
            ),
          ],
          currentIndex: selectedIndex,
          backgroundColor: selectedIndex != 1
              ? Theme.of(context).canvasColor
              : Theme.of(context).primaryColor,
          selectedItemColor: selectedIndex != 1
              ? Theme.of(context).primaryColor
              : Colors.white,
          unselectedItemColor: selectedIndex != 1
              ? Theme.of(context).textTheme.bodySmall!.color
              : Colors.white70,
          onTap: (value) {
            setState(() {
              selectedIndex = value;
            });
          },
        ),
      ]);
    }

    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: content,
      );
    });
  }
}

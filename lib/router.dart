import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:friend_builder/pages/friends/friends_page.dart';

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

  // List<Widget> tabs = <Widget>[
  // ResultsPage(
  //   flutterLocalNotificationsPlugin: widget.flutterLocalNotificationsPlugin,
  // ),
  // LogPage(
  //   onSubmit: () => _changeTab(0),
  //   flutterLocalNotificationsPlugin: widget.flutterLocalNotificationsPlugin,
  // ),
  // ContactsPage(
  //     flutterLocalNotificationsPlugin:
  //         widget.flutterLocalNotificationsPlugin),
  // ];
  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = const Text('foo');
      case 1:
        page = const Text('bar');
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

    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: Column(
          children: [
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
          ],
        ),
      );
    });
  }
}

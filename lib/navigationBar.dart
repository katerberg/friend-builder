import 'package:flutter/material.dart';
import 'package:friend_builder/pages/friends/friendsPage.dart';
import 'package:friend_builder/pages/log/logPage.dart';
import 'package:friend_builder/pages/history/historyPage.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NavigationBar extends StatefulWidget {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  NavigationBar({@required this.flutterLocalNotificationsPlugin});
  @override
  _NavigationBarState createState() => _NavigationBarState();
}

class _NavigationBarState extends State<NavigationBar> {
  int _tabIndex = 1;

  void _changeTab(int tabIndex) async {
    setState(() {
      _tabIndex = tabIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> tabs = <Widget>[
      ResultsPage(
        flutterLocalNotificationsPlugin: widget.flutterLocalNotificationsPlugin,
      ),
      LogPage(
        onSubmit: () => _changeTab(0),
        flutterLocalNotificationsPlugin: widget.flutterLocalNotificationsPlugin,
      ),
      ContactsPage(
          flutterLocalNotificationsPlugin:
              widget.flutterLocalNotificationsPlugin),
    ];

    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
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
        currentIndex: _tabIndex,
        backgroundColor: _tabIndex != 1
            ? Theme.of(context).canvasColor
            : Theme.of(context).primaryColor,
        selectedItemColor:
            _tabIndex != 1 ? Theme.of(context).primaryColor : Colors.white,
        unselectedItemColor: _tabIndex != 1
            ? Theme.of(context).textTheme.caption.color
            : Colors.white70,
        onTap: _changeTab,
      ),
      body: Center(
        child: tabs.elementAt(_tabIndex),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:friend_builder/pages/contactsPage.dart';
import 'package:friend_builder/pages/logPage.dart';
import 'package:friend_builder/pages/resultsPage.dart';
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
      ResultsPage(),
      LogPage(onSubmit: () => _changeTab(0)),
      ContactsPage(
          flutterLocalNotificationsPlugin:
              widget.flutterLocalNotificationsPlugin),
    ];

    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            title: Text('User'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.note_add),
            title: Text('Log'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            title: Text('Friends'),
          ),
        ],
        currentIndex: _tabIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        onTap: _changeTab,
      ),
      body: Center(
        child: tabs.elementAt(_tabIndex),
      ),
    );
  }
}

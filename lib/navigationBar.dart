import 'package:flutter/material.dart';

class NavigationBar extends StatefulWidget {
  @override
  _NavigationBarState createState() => _NavigationBarState();
}

class _NavigationBarState extends State<NavigationBar> {
  int _tabIndex = 1;

  static const TextStyle optionStyle =
      TextStyle(fontSize: 30, fontWeight: FontWeight.bold);

  static const List<Widget> _tabs = <Widget>[
    Text(
      'Index 0: User',
      style: optionStyle,
    ),
    Text(
      'Index 1: Log',
      style: optionStyle,
    ),
    Text(
      'Index 2: Friends',
      style: optionStyle,
    ),
  ];

  void _changeTab(int tabIndex) async {
    setState(() {
      _tabIndex = tabIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
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
        child: _tabs.elementAt(_tabIndex),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:friend_builder/pages/contactsPage.dart';
import 'package:friend_builder/storage.dart';
import 'package:friend_builder/pages/logPage.dart';
import 'package:friend_builder/data/hangout.dart';
import 'package:friend_builder/pages/resultsPage.dart';

class NavigationBar extends StatefulWidget {
  final Storage storage = Storage();
  @override
  _NavigationBarState createState() => _NavigationBarState();
}

class _NavigationBarState extends State<NavigationBar> {
  int _tabIndex = 1;
  List<Hangout> _hangouts;

  @override
  void initState() {
    super.initState();
    _refreshHangouts();
  }

  void _refreshHangouts() {
    print('refreshing hangouts');
    widget.storage.getHangouts().then((hangouts) {
      setState(() {
        _hangouts = hangouts;
      });
    });
  }

  void _changeTab(int tabIndex) async {
    setState(() {
      _tabIndex = tabIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> tabs = <Widget>[
      ResultsPage(hangouts: _hangouts, updateHangouts: _refreshHangouts),
      LogPage(onSubmit: () {
        _refreshHangouts();
        _changeTab(0);
      }),
      ContactsPage(),
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

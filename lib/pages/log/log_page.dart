import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:friend_builder/contacts.dart';
import 'package:friend_builder/pages/log/components/friend_selector.dart';
import 'package:friend_builder/pages/log/components/hangout_form.dart';
import 'package:friend_builder/pages/log/components/selected_friend_chips.dart';

class LogPage extends StatefulWidget {
  final void Function() onSubmit;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  const LogPage(
      {super.key,
      required this.onSubmit,
      required this.flutterLocalNotificationsPlugin});

  @override
  LogPageState createState() => LogPageState();
}

class LogPageState extends State<LogPage> {
  List<Contact> _selectedFriends = [];
  TextEditingController typeaheadController = TextEditingController(text: '');

  @override
  void initState() {
    super.initState();
    _selectedFriends = [];
  }

  void _setFriend(Contact friend) {
    typeaheadController.text = '';
    setState(() {
      _selectedFriends = [..._selectedFriends, friend];
    });
  }

  void _resetFriend(Contact friendToRemove) {
    setState(() {
      _selectedFriends = _selectedFriends
          .where((element) => element.id != friendToRemove.id)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> itemsToShow = [
      FriendSelector(selectedFriends: _selectedFriends, addFriend: _setFriend),
      SelectedFriendChips(
        selectedFriends: _selectedFriends,
        onRemoveFriend: _resetFriend,
        isWhite: true,
      )
    ];
    if (_selectedFriends.isNotEmpty) {
      itemsToShow.add(Row(children: [
        Expanded(
          child: HangoutForm(
            onSubmit: widget.onSubmit,
            selectedFriends: _selectedFriends,
            flutterLocalNotificationsPlugin:
                widget.flutterLocalNotificationsPlugin,
          ),
        ),
      ]));
    }

    return GestureDetector(
      child: Scaffold(
        backgroundColor: Theme.of(context).primaryColor,
        body: SafeArea(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: ListView(
              shrinkWrap: false,
              scrollDirection: Axis.vertical,
              children: itemsToShow,
            ),
          ),
        ),
      ),
      onTap: () {
        if (mounted) {
          FocusScope.of(context).requestFocus(FocusNode());
        }
      },
    );
  }
}

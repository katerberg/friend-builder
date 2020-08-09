import 'package:flutter/material.dart';
import 'package:friend_builder/contacts.dart';
import 'package:friend_builder/logPageComponents/hangoutForm.dart';
import 'package:friend_builder/logPageComponents/selectedFriendChips.dart';
import 'package:friend_builder/logPageComponents/friendSelector.dart';

class LogPage extends StatefulWidget {
  final void Function() onSubmit;
  LogPage({@required this.onSubmit});

  @override
  _LogPageState createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
  List<Contact> _selectedFriends;
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
          .where((element) => element.identifier != friendToRemove.identifier)
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
      )
    ];

    if (_selectedFriends.isNotEmpty) {
      itemsToShow.add(Row(children: [
        Expanded(
          child: Card(
            child: HangoutForm(
              onSubmit: widget.onSubmit,
              selectedFriends: _selectedFriends,
            ),
          ),
        ),
      ]));
    }

    return GestureDetector(
      child: Scaffold(
        body: SafeArea(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: ListView(
              shrinkWrap: true,
              scrollDirection: Axis.vertical,
              children: itemsToShow,
            ),
          ),
        ),
      ),
      onTap: () {
        FocusScope.of(context).requestFocus(new FocusNode());
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:friend_builder/pages/log/components/selectedFriendChips.dart';
import 'package:friend_builder/pages/history/components/friendSelector.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:friend_builder/contacts.dart';
import 'package:friend_builder/data/hangout.dart';
import 'package:friend_builder/pages/history/components/hangoutForm.dart';

class EditDialog extends StatefulWidget {
  final List<Contact> selectedFriends;
  final Hangout hangout;
  final void Function() onSubmit;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  EditDialog({
    @required this.selectedFriends,
    @required this.hangout,
    @required this.onSubmit,
    @required this.flutterLocalNotificationsPlugin,
  });

  @override
  _EditDialogState createState() => _EditDialogState(this.selectedFriends);
}

class _EditDialogState extends State<EditDialog> {
  List<Contact> _selectedFriends;
  TextEditingController typeaheadController = TextEditingController(text: '');

  _EditDialogState(List<Contact> selectedFriends) {
    this._selectedFriends = selectedFriends;
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
    return GestureDetector(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Edit'),
        ),
        body: SafeArea(
          child: ListView(
            shrinkWrap: true,
            scrollDirection: Axis.vertical,
            children: [
              Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: ListView(
                      shrinkWrap: true,
                      scrollDirection: Axis.vertical,
                      children: [
                        FriendSelector(
                            selectedFriends: _selectedFriends,
                            addFriend: _setFriend),
                        SelectedFriendChips(
                          selectedFriends: _selectedFriends,
                          onRemoveFriend: _resetFriend,
                        )
                      ])),
              HangoutForm(
                  hangout: widget.hangout,
                  selectedFriends: _selectedFriends,
                  flutterLocalNotificationsPlugin:
                      widget.flutterLocalNotificationsPlugin,
                  onSubmit: () {
                    widget.onSubmit();
                    Navigator.pop(context);
                  }),
            ],
          ),
        ),
      ),
      onTap: () {
        FocusScope.of(context).requestFocus(new FocusNode());
      },
    );
  }
}

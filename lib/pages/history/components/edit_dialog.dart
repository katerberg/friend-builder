import 'package:flutter/material.dart';
import 'package:friend_builder/shared/selected_friend_chips.dart';
import 'package:friend_builder/pages/history/components/friend_selector.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:friend_builder/contacts_permission.dart';
import 'package:friend_builder/data/hangout.dart';
import 'package:friend_builder/pages/history/components/hangout_form.dart';
import 'package:friend_builder/utils/contacts_helper.dart';

class EditDialog extends StatefulWidget {
  final List<Contact> selectedFriends;
  final Hangout hangout;
  final void Function() onSubmit;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  const EditDialog({
    super.key,
    required this.selectedFriends,
    required this.hangout,
    required this.onSubmit,
    required this.flutterLocalNotificationsPlugin,
  });

  @override
  EditDialogState createState() => EditDialogState();
}

class EditDialogState extends State<EditDialog> {
  List<Contact> _selectedFriends = [];
  TextEditingController typeaheadController = TextEditingController(text: '');

  @override
  void initState() {
    super.initState();
    _selectedFriends = widget.selectedFriends;
  }

  void _setFriend(Contact friend) {
    typeaheadController.text = '';
    setState(() {
      _selectedFriends = [..._selectedFriends, friend];
    });
  }

  void _resetFriend(Contact friendToRemove) {
    setState(() {
      _selectedFriends =
          ContactsHelper.filterContacts(_selectedFriends, friendToRemove);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit'),
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
                            typeaheadController: typeaheadController,
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
        FocusScope.of(context).requestFocus(FocusNode());
      },
    );
  }
}

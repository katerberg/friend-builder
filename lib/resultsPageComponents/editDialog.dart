import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:friend_builder/contacts.dart';
import 'package:friend_builder/data/hangout.dart';
import 'package:friend_builder/logPageComponents/hangoutForm.dart';

class EditDialog extends StatelessWidget {
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
              HangoutForm(
                  hangout: hangout,
                  selectedFriends: this.selectedFriends,
                  flutterLocalNotificationsPlugin:
                      flutterLocalNotificationsPlugin,
                  onSubmit: () {
                    onSubmit();
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

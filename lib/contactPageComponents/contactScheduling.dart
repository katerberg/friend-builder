import 'package:flutter/material.dart';
import 'package:friend_builder/contacts.dart';
import 'package:friend_builder/data/friend.dart';

class ContactSchedulingDialog extends StatelessWidget {
  final Contact contact;
  final void Function() onSave;

  ContactSchedulingDialog({@required this.contact, @required this.onSave});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.close),
            onPressed: () =>
                Navigator.pop(context, Friend(contactIdentifier: '4234')),
          ),
          title: Text(this.contact?.displayName ?? 'Schedule'),
        ),
        body: SafeArea(
          child: ListView(
              shrinkWrap: true,
              scrollDirection: Axis.vertical,
              children: [
                Text('thingy'),
              ]),
        ),
      ),
      onTap: () {
        FocusScope.of(context).requestFocus(new FocusNode());
      },
    );
  }
}

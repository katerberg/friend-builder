import 'package:flutter/material.dart';
import 'package:friend_builder/contacts.dart';

class ContactSchedulingDialog extends StatelessWidget {
  final Contact contact;
  final void Function() onSave;

  ContactSchedulingDialog({@required this.contact, @required this.onSave});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Scaffold(
        appBar: AppBar(
          title: Text(this.contact?.displayName ?? 'Schedule'),
        ),
        body: SafeArea(
          child: ListView(
              shrinkWrap: true,
              scrollDirection: Axis.vertical,
              children: [
                FlatButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onSave();
                  },
                  child: Text('thingy'),
                ),
              ]),
        ),
      ),
      onTap: () {
        FocusScope.of(context).requestFocus(new FocusNode());
      },
    );
  }
}

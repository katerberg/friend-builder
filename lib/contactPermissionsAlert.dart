import 'package:flutter/material.dart';

class ContactPermissionsAlert extends AlertDialog {
  ContactPermissionsAlert(BuildContext context)
      : super(
          title: Text('Permissions'),
          content: Text('Contacts cannot show until you enable contacts access '
              'permission in system settings'),
          actions: <Widget>[
            FlatButton(
              child: Text('Acknowledge'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
}

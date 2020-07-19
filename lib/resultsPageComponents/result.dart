import 'package:flutter/material.dart';
import 'package:friend_builder/data/hangout.dart';

class Result extends StatelessWidget {
  final Hangout hangout;

  Result({
    Hangout hangout,
  }) : this.hangout = hangout;

  @override
  Widget build(BuildContext context) {
    print('inside result');
    print(hangout.contacts);
    return InputChip(
      avatar: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColorDark,
        child: hangout.contacts.length > 0
            ? Text(hangout.contacts[0].initials())
            : Text(hangout.howMany[0]),
      ),
      label: Text(hangout.medium),
    );
  }
}

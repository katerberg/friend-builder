import 'package:flutter/material.dart';
import 'package:friend_builder/storage.dart';

class Result extends StatelessWidget {
  final HangoutData hangout;

  Result({
    HangoutData hangout,
  }) : this.hangout = hangout;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      avatar: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColorDark,
        child: Text(this.hangout.howMany[0]),
      ),
      label: Text(this.hangout.medium),
    );
  }
}

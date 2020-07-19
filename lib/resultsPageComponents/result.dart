import 'package:flutter/material.dart';
import 'package:friend_builder/data/hangout.dart';

class Result extends StatelessWidget {
  final Hangout hangout;

  Result({
    Hangout hangout,
  }) : this.hangout = hangout;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColorDark,
                    child: hangout.contacts.length > 0
                        ? Text(hangout.contacts[0].initials())
                        : Text(hangout.medium[0]),
                  ),
                  Container(
                    padding: EdgeInsets.only(left: 8),
                    child: Text(
                      hangout.formattedDate(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ]
        // avatar: CircleAvatar(
        //   backgroundColor: Theme.of(context).primaryColorDark,
        //   child: hangout.contacts.length > 0
        //       ? Text(hangout.contacts[0].initials())
        //       : Text(hangout.howMany[0]),
        // ),
        // label: Text(hangout.medium),
        );
  }
}

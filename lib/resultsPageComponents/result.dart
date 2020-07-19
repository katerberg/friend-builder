import 'package:flutter/material.dart';
import 'package:friend_builder/data/hangout.dart';
import 'package:friend_builder/resultsPageComponents/resultBubbles.dart';

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
                  Container(
                    alignment: Alignment.centerRight,
                    child: Text(
                      hangout.formattedDate(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ResultBubbles(contacts: hangout.contacts),
                ],
              ),
            ),
          ],
        ),
      ),
    ]);
  }
}

import 'package:flutter/material.dart';
import 'package:friend_builder/data/encodableContact.dart';
import 'package:friend_builder/resultsPageComponents/resultBubble.dart';

class ResultBubbles extends StatelessWidget {
  final List<EncodableContact> contacts;

  ResultBubbles({this.contacts});

  @override
  Widget build(BuildContext context) {
    var bubbles = [
      ...contacts.take(3).map((c) => ResultBubble(text: c.initials())).toList(),
    ];

    if (contacts.length > 3) {
      if (contacts.length == 4) {
        bubbles.add(ResultBubble(text: contacts[3].initials()));
      } else {
        bubbles.add(ResultBubble(text: '+' + (contacts.length - 3).toString()));
      }
    }

    return Row(
      children: bubbles,
    );
  }
}

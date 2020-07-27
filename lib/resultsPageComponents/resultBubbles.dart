import 'package:flutter/material.dart';
import 'package:friend_builder/data/encodableContact.dart';
import 'package:friend_builder/resultsPageComponents/resultBubble.dart';

class ResultBubbles extends StatelessWidget {
  final List<EncodableContact> contacts;

  ResultBubbles({this.contacts});

  Widget _getPadded(Widget widget) {
    return Container(
      padding: EdgeInsets.only(left: 8),
      child: widget,
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> bubbles = [
      ...contacts.take(3).map((c) => _getPadded(c.getAvatar(context))).toList(),
    ];

    if (contacts.length > 3) {
      if (contacts.length == 4) {
        bubbles.add(_getPadded(contacts[3].getAvatar(context)));
      } else {
        bubbles.add(ResultBubble(text: '+' + (contacts.length - 3).toString()));
      }
    }

    return Row(
      children: bubbles,
    );
  }
}

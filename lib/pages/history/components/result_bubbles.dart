import 'package:flutter/material.dart';
import 'package:friend_builder/data/encodable_contact.dart';
import 'package:friend_builder/pages/history/components/result_bubble.dart';

class ResultBubbles extends StatelessWidget {
  final List<EncodableContact> contacts;

  const ResultBubbles({super.key, required this.contacts});

  Widget _getPadded(Widget widget) {
    return Container(
      padding: const EdgeInsets.only(left: 8),
      child: widget,
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> bubbles = [
      ...contacts.take(3).map((c) => _getPadded(c.getAvatar(context))),
    ];

    if (contacts.length > 3) {
      if (contacts.length == 4) {
        bubbles.add(_getPadded(contacts[3].getAvatar(context)));
      } else {
        bubbles.add(ResultBubble(text: '+${contacts.length - 3}'));
      }
    }

    return Row(
      children: bubbles,
    );
  }
}

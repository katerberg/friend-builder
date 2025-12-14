import 'package:flutter/material.dart';
import 'package:friend_builder/data/encodable_contact.dart';
import 'package:friend_builder/pages/history/components/result_bubble.dart';
import 'package:friend_builder/shared/lazy_contact_avatar.dart';

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
      ...contacts.take(3).map((c) => _getPadded(LazyContactAvatar(contact: c))),
    ];

    if (contacts.length > 3) {
      if (contacts.length == 4) {
        bubbles.add(_getPadded(LazyContactAvatar(contact: contacts[3])));
      } else {
        bubbles.add(ResultBubble(text: '+${contacts.length - 3}'));
      }
    }

    return Row(
      children: bubbles,
    );
  }
}

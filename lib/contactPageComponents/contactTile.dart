import 'package:flutter/material.dart';
import 'package:friend_builder/contacts.dart';
import 'package:friend_builder/data/encodableContact.dart';
import 'package:friend_builder/data/hangout.dart';

class ContactTile extends StatelessWidget {
  final Contact contact;
  final void Function(Contact contact) onPressed;
  final String frequency;
  final Hangout latestHangout;

  ContactTile({
    @required this.contact,
    @required this.onPressed,
    this.latestHangout,
    this.frequency,
  });

  Text _getSubTitle() {
    if (latestHangout == null) {
      return null;
    }
    print(latestHangout.when);
    var daysAgo = DateTime.now().difference(latestHangout.when).inDays;
    return Text(daysAgo > 0 ? daysAgo.toString() + " days ago" : 'Today');
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 2, horizontal: 18),
      leading: EncodableContact.fromContact(contact).getAvatar(context),
      onTap: () => onPressed(this.contact),
      title: Text(
        contact?.displayName ?? '',
        style: TextStyle(
            fontWeight:
                frequency == null ? FontWeight.normal : FontWeight.bold),
      ),
      subtitle: _getSubTitle(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:friend_builder/contacts.dart';
import 'package:friend_builder/data/encodableContact.dart';
import 'package:friend_builder/utils/scheduling.dart';
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

  Text _getSubTitle(context) {
    if (frequency == null && latestHangout == null) {
      return null;
    }
    if (latestHangout == null) {
      return Text('Never seen!');
    }

    int daysLeft = Scheduling.daysLeft(frequency, latestHangout.when);

    String daysLeftMessage = daysLeft > 0
        ? (daysLeft).toString() + ' days to go'
        : (daysLeft.abs().toString() + ' days late');
    return frequency == null
        ? null
        : Text(daysLeftMessage,
            style: TextStyle(
                color:
                    daysLeft > 0 ? Theme.of(context).hintColor : Colors.red));
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
      subtitle: _getSubTitle(context),
    );
  }
}

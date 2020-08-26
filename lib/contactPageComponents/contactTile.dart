import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:friend_builder/contacts.dart';
import 'package:friend_builder/data/encodableContact.dart';
import 'package:friend_builder/schedulingUtils.dart';
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
    if (frequency == null && latestHangout == null) {
      return null;
    }
    if (latestHangout == null) {
      return Text('Never seen!');
    }
    String daysLeft =
        (SchedulingUtils.daysLeft(frequency, latestHangout.when)).toString() +
            ' days to go';
    return frequency == null ? null : Text(daysLeft);
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

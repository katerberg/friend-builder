import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:friend_builder/contacts.dart';
import 'package:friend_builder/data/encodableContact.dart';
import 'package:friend_builder/data/hangout.dart';

class ContactTile extends StatelessWidget {
  final Contact contact;
  final void Function(Contact contact) onPressed;
  final bool isBold;
  final List<Hangout> hangouts;

  ContactTile({
    @required this.contact,
    @required this.onPressed,
    this.hangouts,
    bool isBold,
  }) : isBold = isBold ?? false;

  Text _getSubTitle() {
    if (hangouts == null) {
      return null;
    }
    var latestHangout = hangouts.reduce((value, hangout) {
      var contacts = hangout.contacts
          .where((c) => c.identifier == this.contact.identifier);
      if (contacts.length == 1 && value.when.compareTo(hangout.when) < 0) {
        return hangout;
      }
      return value;
    });
    return Text(latestHangout == null
        ? 'Unknown'
        : DateFormat.yMMMMd().format(latestHangout.when));
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 2, horizontal: 18),
      leading: EncodableContact.fromContact(contact).getAvatar(context),
      onTap: () => onPressed(this.contact),
      title: Text(
        contact?.displayName ?? '',
        style:
            TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
      ),
      subtitle: _getSubTitle(),
    );
  }
}

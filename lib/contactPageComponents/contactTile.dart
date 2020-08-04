import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:friend_builder/contacts.dart';
import 'package:friend_builder/data/encodableContact.dart';
import 'package:friend_builder/data/hangout.dart';

class ContactTile extends StatelessWidget {
  final Contact contact;
  final void Function(Contact contact) onPressed;
  final bool isBold;
  final Hangout latestHangout;

  ContactTile({
    @required this.contact,
    @required this.onPressed,
    this.latestHangout,
    bool isBold,
  }) : isBold = isBold ?? false;

  Text _getSubTitle() {
    if (latestHangout == null) {
      return null;
    }
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

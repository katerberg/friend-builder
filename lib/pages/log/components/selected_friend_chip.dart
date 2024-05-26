import 'package:flutter/material.dart';
import 'package:friend_builder/contacts.dart';
import 'package:friend_builder/data/encodable_contact.dart';

class SelectedFriendChip extends StatelessWidget {
  final Contact selectedFriend;
  final Function onPressed;
  final bool isWhite;

  const SelectedFriendChip({
    super.key,
    required this.selectedFriend,
    required void Function(Contact friend) this.onPressed,
    this.isWhite = false,
  });

  @override
  Widget build(BuildContext context) {
    handleDelete() => onPressed(selectedFriend);
    return InputChip(
      avatar:
          EncodableContact.fromContact(selectedFriend).getAvatar(context, 12),
      backgroundColor:
          isWhite ? Colors.white : Theme.of(context).chipTheme.backgroundColor,
      onDeleted: handleDelete,
      onPressed: handleDelete,
      deleteIconColor: Colors.black54,
      label: Text(selectedFriend.displayName),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:friend_builder/contacts.dart';
import 'package:friend_builder/data/encodableContact.dart';

class SelectedFriendChip extends StatelessWidget {
  final Contact selectedFriend;
  final Function onPressed;
  final bool isWhite;

  SelectedFriendChip({
    Contact selectedFriend,
    void Function(Contact friend) onPressed,
    this.isWhite = false,
  })  : this.selectedFriend = selectedFriend,
        this.onPressed = onPressed;

  @override
  Widget build(BuildContext context) {
    var handleDelete = () => this.onPressed(this.selectedFriend);
    return InputChip(
      avatar:
          EncodableContact.fromContact(selectedFriend).getAvatar(context, 12),
      backgroundColor:
          isWhite ? Colors.white : Theme.of(context).chipTheme.backgroundColor,
      onDeleted: handleDelete,
      onPressed: handleDelete,
      deleteIconColor: Colors.black54,
      label: Text(this.selectedFriend.displayName),
    );
  }
}

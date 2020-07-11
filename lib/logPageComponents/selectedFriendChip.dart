import 'package:flutter/material.dart';
import 'package:friend_builder/contacts.dart';

class SelectedFriendChip extends StatelessWidget {
  final Contact selectedFriend;
  final Function onPressed;

  SelectedFriendChip({
    Contact selectedFriend,
    Function onPressed,
  })  : this.selectedFriend = selectedFriend,
        this.onPressed = onPressed;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      avatar: CircleAvatar(
        backgroundColor: Colors.grey.shade800,
        child: Text(this.selectedFriend.initials()),
      ),
      label: Text(this.selectedFriend.displayName),
      onPressed: () => this.onPressed(this.selectedFriend),
    );
  }
}

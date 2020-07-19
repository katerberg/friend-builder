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
    var handleDelete = () => this.onPressed(this.selectedFriend);
    return InputChip(
      avatar: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColorDark,
        child: Text(
          this.selectedFriend.initials(),
          style: TextStyle(fontSize: 12),
        ),
      ),
      onDeleted: handleDelete,
      onPressed: handleDelete,
      deleteIconColor: Colors.black54,
      label: Text(this.selectedFriend.displayName),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:friend_builder/contacts_permission.dart';
import 'package:friend_builder/shared/lazy_contact_avatar.dart';

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
      avatar: LazyContactAvatar(contact: selectedFriend, radius: 12),
      backgroundColor:
          isWhite ? Colors.white : Theme.of(context).chipTheme.backgroundColor,
      onDeleted: handleDelete,
      onPressed: handleDelete,
      deleteIconColor: Colors.black54,
      label: Text(selectedFriend.displayName),
    );
  }
}

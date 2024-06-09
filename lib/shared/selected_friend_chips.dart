import 'package:flutter/material.dart';
import 'package:friend_builder/contacts_permission.dart';
import 'package:friend_builder/shared/selected_friend_chip.dart';

class SelectedFriendChips extends StatelessWidget {
  final List<Contact> selectedFriends;
  final void Function(Contact contact) onRemoveFriend;
  final bool isWhite;

  const SelectedFriendChips(
      {super.key,
      required this.selectedFriends,
      required this.onRemoveFriend,
      this.isWhite = false});

  @override
  Widget build(BuildContext context) {
    List<Widget> itemsToShow = [];
    if (selectedFriends.isNotEmpty) {
      itemsToShow.add(Wrap(
        spacing: 8,
        runSpacing: 4,
        children: selectedFriends
            .map((Contact contact) => SelectedFriendChip(
                  onPressed: onRemoveFriend,
                  selectedFriend: contact,
                  isWhite: isWhite,
                ))
            .toList(),
      ));
    }
    return Wrap(children: itemsToShow);
  }
}

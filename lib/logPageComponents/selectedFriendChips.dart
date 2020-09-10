import 'package:flutter/material.dart';
import 'package:friend_builder/contacts.dart';
import 'package:friend_builder/logPageComponents/selectedFriendChip.dart';

class SelectedFriendChips extends StatelessWidget {
  final List<Contact> selectedFriends;
  final void Function(Contact contact) onRemoveFriend;
  final bool isWhite;

  SelectedFriendChips(
      {@required this.selectedFriends,
      @required this.onRemoveFriend,
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

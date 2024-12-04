import 'package:flutter/material.dart';
import 'package:friend_builder/contacts_permission.dart';
import 'package:friend_builder/shared/no_items_found.dart';
import 'package:friend_builder/data/encodable_contact.dart';
import 'package:friend_builder/utils/contacts_helper.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class FriendSelector extends StatelessWidget {
  final List<Contact> selectedFriends;
  final void Function(Contact friend) addFriend;
  final TextEditingController typeaheadController;
  final String? emptyLabel;
  final String? populatedLabel;

  const FriendSelector(
      {super.key,
      required this.selectedFriends,
      required this.addFriend,
      required this.typeaheadController,
      this.emptyLabel,
      this.populatedLabel});

  String _getInputLabelText() {
    if (selectedFriends.isEmpty) {
      return emptyLabel ?? 'Who are you seeing?';
    }
    return populatedLabel ?? 'Anyone else?';
  }

  @override
  Widget build(BuildContext context) {
    return TypeAheadField(
      controller: typeaheadController,
      builder: (context, controller, focusNode) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          cursorColor: TextSelectionTheme.of(context).cursorColor,
          style: const TextStyle(fontSize: 24),
          autofocus: false,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: _getInputLabelText(),
          ),
        );
      },
      suggestionsCallback: (pattern) async =>
          ContactsHelper.getSuggestions(selectedFriends, pattern),
      itemBuilder: (context, Contact suggestion) {
        return ListTile(
          leading: EncodableContact.fromContact(suggestion).getAvatar(context),
          title: Text(suggestion.displayName),
        );
      },
      emptyBuilder: (context) => const NoItemsFound(),
      debounceDuration: const Duration(milliseconds: 200),
      onSelected: addFriend,
    );
  }
}

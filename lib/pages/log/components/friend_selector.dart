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
    const inputBorder = UnderlineInputBorder(
        borderSide: BorderSide(width: 1, color: Colors.white));
    return TypeAheadField(
      controller: typeaheadController,
      builder: (context, controller, focusNode) {
        return TextField(
          textCapitalization: TextCapitalization.sentences,
          controller: controller,
          focusNode: focusNode,
          cursorColor: Colors.white,
          style: const TextStyle(color: Colors.white, fontSize: 24),
          autofocus: false,
          decoration: InputDecoration(
            floatingLabelBehavior: FloatingLabelBehavior.never,
            focusedBorder: inputBorder,
            enabledBorder: inputBorder,
            labelStyle: const TextStyle(color: Colors.white, fontSize: 24),
            labelText: _getInputLabelText(),
          ),
        );
      },
      suggestionsCallback: (pattern) async =>
          await ContactsHelper.getSuggestions(selectedFriends, pattern),
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

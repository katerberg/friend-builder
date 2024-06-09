import 'package:flutter/material.dart';
import 'package:friend_builder/contacts_permission.dart';
import 'package:friend_builder/shared/no_items_found.dart';
import 'package:friend_builder/data/encodable_contact.dart';
import 'package:friend_builder/utils/search_utils.dart';
import 'package:friend_builder/utils/string_utils.dart';
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

  Future<List<Contact>> _getSuggestions(String pattern) async {
    ContactPermission contactPermission =
        await ContactPermissionService().getContacts();
    if (contactPermission.missingPermission) {
      return Future.value([]);
    }
    var listOfFriends = await Future.value(contactPermission.contacts
        .where((element) =>
            !selectedFriends.any((selected) => selected.id == element.id) &&
            (pattern.length < 2 ||
                StringUtils.getComparison(element.displayName, pattern) > 0.1))
        .toList());
    var sortedFriends = listOfFriends
      ..sort((a, b) {
        return SearchUtils.sortTwoFriendsInSuggestions(pattern, a, b);
      });
    const maxResults = 7;
    return sortedFriends.sublist(0,
        sortedFriends.length > maxResults ? maxResults : sortedFriends.length);
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
      suggestionsCallback: (pattern) async => await _getSuggestions(pattern),
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

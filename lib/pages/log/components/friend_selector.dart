import 'package:flutter/material.dart';
import 'package:friend_builder/contacts.dart';
import 'package:friend_builder/pages/log/components/no_items_found.dart';
import 'package:friend_builder/data/encodable_contact.dart';
import 'package:friend_builder/utils/string_utils.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class FriendSelector extends StatelessWidget {
  final List<Contact> selectedFriends;
  final void Function(Contact friend) addFriend;
  final TextEditingController _typeaheadController = TextEditingController();
  final String? emptyLabel;
  final String? populatedLabel;

  FriendSelector(
      {super.key,
      required this.selectedFriends,
      required this.addFriend,
      this.emptyLabel,
      this.populatedLabel});

  String _getInputLabelText() {
    if (selectedFriends.isEmpty) {
      return emptyLabel ?? 'Who are you seeing?';
    }
    return populatedLabel ?? 'Anyone else?';
  }

  int sortByBetterMatch(pattern, a, b) {
    bool isBBetterMatch = StringUtils.getComparison(a?.displayName, pattern) <
        StringUtils.getComparison(b?.displayName, pattern);
    return isBBetterMatch ? 1 : -1;
  }

  int sortTwoFriendsInSuggestions(pattern, a, b) {
    RegExp startsWithExactly = RegExp(
      "^$pattern",
      caseSensitive: false,
    );
    var aMatches = startsWithExactly.hasMatch(a?.displayName ?? '');
    if (aMatches || startsWithExactly.hasMatch(b?.displayName ?? '')) {
      return aMatches ? -1 : 1;
    }
    return sortByBetterMatch(pattern, a, b);
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
        return sortTwoFriendsInSuggestions(pattern, a, b);
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
      builder: (context, controller, focusNode) {
        return TextField(
          controller: _typeaheadController,
          focusNode: focusNode,
          cursorColor: Colors.white,
          style: const TextStyle(color: Colors.white, fontSize: 24),
          autofocus: true,
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
      debounceDuration: Duration.zero,
      onSelected: addFriend,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:friend_builder/contacts.dart';
import 'package:friend_builder/pages/log/components/no_items_found.dart';
import 'package:friend_builder/data/encodable_contact.dart';
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
    if (!contactPermission.missingPermission) {
      var listOfFriends = await Future.value(contactPermission.contacts
          .where((element) =>
              !selectedFriends.any((selected) => selected.id == element.id) &&
              (pattern.length < 2 ||
                  StringUtils.getComparison(element.displayName, pattern) >
                      0.1))
          .toList());
      return listOfFriends
        ..sort((a, b) {
          RegExp regExp = RegExp(
            '^$pattern',
            caseSensitive: false,
          );
          var aMatches = regExp.hasMatch(a.displayName);
          if (aMatches || regExp.hasMatch(b.displayName)) {
            return aMatches ? -1 : 1;
          }
          bool isBigger = StringUtils.getComparison(a.displayName, pattern) <
              StringUtils.getComparison(b.displayName, pattern);
          return isBigger ? 1 : -1;
        });
    }
    return Future.value([]);
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
          decoration: InputDecoration(
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

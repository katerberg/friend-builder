import 'package:flutter/material.dart';
import 'package:friend_builder/contacts.dart';
import 'package:friend_builder/logPageComponents/noItemsFound.dart';
import 'package:friend_builder/stringUtils.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class FriendSelector extends StatelessWidget {
  final List<Contact> selectedFriends;
  final void Function(Contact friend) addFriend;
  final TextEditingController typeaheadController =
      TextEditingController(text: '');
  final String emptyLabel;
  final String populatedLabel;

  FriendSelector(
      {Key key,
      @required this.selectedFriends,
      @required this.addFriend,
      this.emptyLabel,
      this.populatedLabel})
      : super(key: key);

  String _getInputLabelText() {
    if (selectedFriends.isEmpty) {
      return emptyLabel ?? 'Who are you hanging out with?';
    }
    return populatedLabel ?? 'Anyone else?';
  }

  Future<List<Contact>> _getSuggestions(String pattern) async {
    ContactPermission contactPermission =
        await ContactPermissionService().getContacts();
    if (!contactPermission.missingPermission) {
      var val = await Future.value(contactPermission.contacts
          .where((element) =>
              !selectedFriends.any(
                  (selected) => selected.identifier == element.identifier) &&
              (pattern.length < 2 ||
                  StringUtils.getComparison(element?.displayName, pattern) >
                      0.1))
          .toList());
      return val
        ..sort((a, b) => StringUtils.getComparison(a?.displayName, pattern) <
                StringUtils.getComparison(b?.displayName, pattern)
            ? 1
            : -1);
    }
    return Future.value([]);
  }

  @override
  Widget build(BuildContext context) {
    return TypeAheadField(
      textFieldConfiguration: TextFieldConfiguration(
        autofocus: false,
        autocorrect: false,
        controller: typeaheadController,
        cursorColor: Theme.of(context).cursorColor,
        decoration: InputDecoration(
          labelText: _getInputLabelText(),
        ),
      ),
      suggestionsCallback: (pattern) async => await _getSuggestions(pattern),
      itemBuilder: (context, suggestion) {
        return ListTile(
          leading: Icon(Icons.person_add),
          title: Text(suggestion.displayName ?? ''),
        );
      },
      noItemsFoundBuilder: (context) => NoItemsFound(),
      onSuggestionSelected: addFriend,
    );
  }
}

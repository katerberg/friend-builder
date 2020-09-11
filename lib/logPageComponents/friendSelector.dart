import 'package:flutter/material.dart';
import 'package:friend_builder/contacts.dart';
import 'package:friend_builder/logPageComponents/noItemsFound.dart';
import 'package:friend_builder/data/encodableContact.dart';
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
      return emptyLabel ?? 'Who are you seeing?';
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
        ..sort((a, b) {
          RegExp regExp = new RegExp(
            '^' + pattern,
            caseSensitive: false,
          );
          var aMatches = regExp.hasMatch(a?.displayName ?? '');
          if (aMatches || regExp.hasMatch(b?.displayName ?? '')) {
            return aMatches ? -1 : 1;
          }
          bool isBigger = StringUtils.getComparison(a?.displayName, pattern) <
              StringUtils.getComparison(b?.displayName, pattern);
          return isBigger ? 1 : -1;
        });
    }
    return Future.value([]);
  }

  @override
  Widget build(BuildContext context) {
    const inputBorder = UnderlineInputBorder(
        borderSide: BorderSide(width: 1, color: Colors.white));
    return TypeAheadField(
      textFieldConfiguration: TextFieldConfiguration(
        autofocus: false,
        autocorrect: false,
        controller: typeaheadController,
        cursorColor: Colors.white,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          floatingLabelBehavior: FloatingLabelBehavior.never,
          focusedBorder: inputBorder,
          enabledBorder: inputBorder,
          labelStyle: TextStyle(color: Colors.white, fontSize: 24),
          labelText: _getInputLabelText(),
        ),
      ),
      suggestionsCallback: (pattern) async => await _getSuggestions(pattern),
      itemBuilder: (context, Contact suggestion) {
        return ListTile(
          leading: EncodableContact.fromContact(suggestion).getAvatar(context),
          title: Text(suggestion.displayName ?? ''),
        );
      },
      noItemsFoundBuilder: (context) => NoItemsFound(),
      onSuggestionSelected: addFriend,
    );
  }
}

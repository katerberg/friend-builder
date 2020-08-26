import 'package:flutter/material.dart';
import 'package:friend_builder/stringUtils.dart';
import 'package:friend_builder/contacts.dart';

class ContactSearch extends StatefulWidget {
  final Iterable<Contact> contacts;
  final void Function(Iterable<Contact> filteredList) filterList;

  ContactSearch({@required this.contacts, @required this.filterList});

  @override
  _ContactSearchState createState() => _ContactSearchState();
}

class _ContactSearchState extends State<ContactSearch> {
  final TextEditingController typeaheadController =
      TextEditingController(text: '');

  void _handleContactSelection(String pattern) {
    var exactMatches = widget.contacts.where((element) =>
        (element?.displayName ?? '')
            .toLowerCase()
            .contains(pattern.toLowerCase()));
    if (exactMatches.length > 0) {
      return widget.filterList(exactMatches.toList()
        ..sort(
            (a, b) => (a?.displayName ?? '').compareTo(b?.displayName ?? '')));
    }
    var matchingLevel = widget.contacts.where((element) =>
        StringUtils.getComparison(element?.displayName, pattern) > 0.3);
    widget
        .filterList(matchingLevel.length > 0 ? matchingLevel : widget.contacts);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      textCapitalization: TextCapitalization.sentences,
      autocorrect: false,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.search),
      ),
      controller: typeaheadController,
      onChanged: _handleContactSelection,
    );
  }
}

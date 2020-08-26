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
    var filtered = widget.contacts.where((element) =>
        StringUtils.getComparison(element?.displayName, pattern) > 0.3);
    widget.filterList(filtered.length > 0 ? filtered : widget.contacts);
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

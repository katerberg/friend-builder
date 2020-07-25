import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:friend_builder/contacts.dart';
import 'package:friend_builder/logPageComponents/hangoutForm.dart';
import 'package:friend_builder/logPageComponents/noItemsFound.dart';
import 'package:friend_builder/logPageComponents/suggestionForm.dart';
import 'package:friend_builder/stringUtils.dart';

class LogPage extends StatefulWidget {
  final Function() onSubmit;
  LogPage({Key key, @required this.onSubmit}) : super(key: key);

  @override
  _LogPageState createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
  List<Contact> _selectedFriends;
  TextEditingController typeaheadController = TextEditingController(text: '');

  @override
  void initState() {
    super.initState();
    _selectedFriends = [];
  }

  Future<List<Contact>> _getSuggestions(String pattern) async {
    ContactPermission contactPermission =
        await ContactPermissionService().getContacts();
    if (!contactPermission.missingPermission) {
      var val = await Future.value(contactPermission.contacts
          .where((element) =>
              !_selectedFriends.any(
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

  void _setFriend(Contact friend) {
    typeaheadController.text = '';
    setState(() {
      _selectedFriends = [..._selectedFriends, friend];
    });
  }

  void _resetFriend(Contact friendToRemove) {
    setState(() {
      _selectedFriends = _selectedFriends
          .where((element) => element.identifier != friendToRemove.identifier)
          .toList();
    });
  }

  String _getInputLabelText() {
    if (_selectedFriends.isEmpty) {
      return 'Who are you hanging out with?';
    }
    return 'Anyone else?';
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> itemsToShow = [
      TypeAheadField(
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
        onSuggestionSelected: _setFriend,
      )
    ];
    itemsToShow.add(SuggestionForm(
      selectedFriends: _selectedFriends,
      onRemoveFriend: _resetFriend,
    ));

    if (_selectedFriends.isNotEmpty) {
      itemsToShow.add(Row(children: [
        Expanded(
          child: Card(
            child: HangoutForm(
              onSubmit: widget.onSubmit,
              selectedFriends: _selectedFriends,
            ),
          ),
        ),
      ]));
    }

    return GestureDetector(
      child: Scaffold(
        body: SafeArea(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: ListView(
              shrinkWrap: true,
              scrollDirection: Axis.vertical,
              children: itemsToShow,
            ),
          ),
        ),
      ),
      onTap: () {
        FocusScope.of(context).requestFocus(new FocusNode());
      },
    );
  }
}

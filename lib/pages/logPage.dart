import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:friend_builder/contacts.dart';
import 'package:friend_builder/logPageComponents/hangoutForm.dart';
import 'package:friend_builder/logPageComponents/noItemsFound.dart';
import 'package:friend_builder/logPageComponents/selectedFriendChip.dart';

class LogPage extends StatefulWidget {
  final Function() notifyParent;
  LogPage({Key key, @required this.notifyParent}) : super(key: key);

  @override
  _LogPageState createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
  List<Contact> _selectedFriends;

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
              (element.displayName ?? '')
                  .toLowerCase()
                  .contains(pattern?.toLowerCase()) &&
              !_selectedFriends.contains(element))
          .toList());
      return val
        ..sort((a, b) => a?.displayName?.compareTo(b?.displayName ?? '') ?? 0);
    }
    return Future.value([]);
  }

  void _setFriend(Contact friend) {
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
    List<Widget> itemsToShow = [];

    itemsToShow.add(TypeAheadField(
      textFieldConfiguration: TextFieldConfiguration(
        autofocus: _selectedFriends.isEmpty,
        autocorrect: false,
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
    ));

    if (_selectedFriends.isNotEmpty) {
      itemsToShow.add(Wrap(
        spacing: 8,
        runSpacing: 4,
        children: _selectedFriends
            .map((Contact friend) => SelectedFriendChip(
                  onPressed: _resetFriend,
                  selectedFriend: friend,
                ))
            .toList(),
      ));
      itemsToShow.add(Row(children: [
        Expanded(
          child: Card(
            child: Padding(
              child: HangoutForm(
                notifyParent: widget.notifyParent,
                selectedFriends: _selectedFriends,
              ),
              padding: EdgeInsets.all(16),
            ),
          ),
        ),
      ]));
    }

    return Scaffold(
      body: GestureDetector(
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: ListView(
              shrinkWrap: true,
              scrollDirection: Axis.vertical,
              children: itemsToShow,
            ),
          ),
        ),
        onTap: () {
          FocusScope.of(context).requestFocus(new FocusNode());
        },
      ),
    );
  }
}

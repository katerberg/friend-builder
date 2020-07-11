import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:friend_builder/contacts.dart';

class LogPage extends StatefulWidget {
  @override
  _LogPageState createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
  Contact _selectedFriend;

  static const TextStyle _headerStyle =
      TextStyle(fontSize: 30, fontWeight: FontWeight.bold);

  Future<List<Contact>> _getSuggestions(String pattern) async {
    ContactPermission contactPermission =
        await ContactPermissionService().getContacts();
    if (!contactPermission.missingPermission) {
      return Future.value(contactPermission.contacts
          .where((element) =>
              element.displayName.toLowerCase().contains(pattern.toLowerCase()))
          .toList());
    }
    return Future.value([]);
  }

  void _setFriend(Contact friend) {
    setState(() {
      _selectedFriend = friend;
    });
  }

  void _resetFriend() {
    _setFriend(null);
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> itemsToShow = [];

    itemsToShow.add(TypeAheadField(
      textFieldConfiguration: TextFieldConfiguration(
          autofocus: _selectedFriend == null,
          autocorrect: false,
          cursorColor: Theme.of(context).cursorColor,
          style: DefaultTextStyle.of(context)
              .style
              .copyWith(fontStyle: FontStyle.italic),
          decoration: InputDecoration(border: OutlineInputBorder())),
      suggestionsCallback: (pattern) async {
        return await _getSuggestions(pattern);
      },
      itemBuilder: (context, suggestion) {
        return ListTile(
          leading: Icon(Icons.person_add),
          title: Text(suggestion.displayName),
        );
      },
      onSuggestionSelected: _setFriend,
    ));

    if (_selectedFriend != null) {
      itemsToShow.add(Wrap(
        spacing: 8.0,
        runSpacing: 4.0,
        children: <Widget>[
          InputChip(
            avatar: CircleAvatar(
              backgroundColor: Colors.grey.shade800,
              child: Text(_selectedFriend.initials()),
            ),
            label: Text(_selectedFriend.displayName),
            onPressed: _resetFriend,
          ),
        ],
      ));
      itemsToShow.add(Text(
        _selectedFriend.displayName,
        style: _headerStyle,
      ));
    } else {
      itemsToShow.insert(
        0,
        Text(
          'Who are you hanging out with?',
          style: _headerStyle,
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: _selectedFriend != null
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: itemsToShow,
          ),
        ),
      ),
    );
  }
}

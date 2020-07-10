import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:friend_builder/contacts.dart';

class LogPage extends StatefulWidget {
  @override
  _LogPageState createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
  String _friend;

  Future<List<String>> _getSuggestions(String pattern) async {
    ContactPermission contactPermission =
        await new ContactPermissionService().getContacts();
    if (!contactPermission.missingPermission) {
      return Future.value(contactPermission.contacts
          .where((element) =>
              element.displayName.toLowerCase().contains(pattern.toLowerCase()))
          .map((e) => e.displayName)
          .toList());
    }
    return Future.value(List.generate(3, (index) {
      return pattern + 'no';
    }));
  }

  void _setFriend(String friend) {
    setState(() {
      _friend = friend;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> itemsToShow = [];

    itemsToShow.add(TypeAheadField(
      textFieldConfiguration: TextFieldConfiguration(
          autofocus: _friend == null,
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
          title: Text(suggestion),
        );
      },
      onSuggestionSelected: (friend) {
        _setFriend(friend);
      },
    ));

    if (_friend != null) {
      itemsToShow.add(new Text(_friend));
    } else {
      itemsToShow.insert(
        0,
        new Text(
          'Who are you hanging out with?',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: _friend != null
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: itemsToShow,
          ),
        ),
      ),
    );
  }
}

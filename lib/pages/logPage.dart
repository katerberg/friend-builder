import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:friend_builder/contacts.dart';

class LogPage extends StatefulWidget {
  @override
  _LogPageState createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
  String _contactSearch;

  Future<void> _handleContactSearch(String searchParam) async {
    _contactSearch = searchParam;
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TypeAheadField(
              textFieldConfiguration: TextFieldConfiguration(
                  autofocus: true,
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
                  // subtitle: Text('\$${suggestion['price']}'),
                );
              },
              onSuggestionSelected: (suggestion) {},
            ),
            // TextField(
            //   autocorrect: false,
            //   enableSuggestions: false,
            //   cursorColor: Theme.of(context).cursorColor,
            //   onChanged: _handleContactSearch,
            //   decoration: InputDecoration(
            //     icon: Icon(Icons.person),
            //     filled: false,
            //     labelText: 'Friend name',
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}

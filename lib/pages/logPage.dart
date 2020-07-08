import 'package:flutter/material.dart';

class LogPage extends StatefulWidget {
  @override
  _LogPageState createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
  String _contactSearch;

  Future<void> _handleContactSearch(String searchParam) async {
    _contactSearch = searchParam;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              autocorrect: false,
              enableSuggestions: false,
              cursorColor: Theme.of(context).cursorColor,
              onChanged: _handleContactSearch,
              decoration: InputDecoration(
                icon: Icon(Icons.person),
                filled: false,
                labelText: 'Friend name',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class NoItemsFound extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(8, 32, 8, 32),
      child: Text(
        'No contact found',
        style: TextStyle(fontStyle: FontStyle.italic),
      ),
    );
  }
}

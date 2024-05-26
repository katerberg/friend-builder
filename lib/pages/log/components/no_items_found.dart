import 'package:flutter/material.dart';

class NoItemsFound extends StatelessWidget {
  const NoItemsFound({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(8, 32, 8, 32),
      child: Text(
        'No contact found',
        style: TextStyle(fontStyle: FontStyle.italic),
      ),
    );
  }
}

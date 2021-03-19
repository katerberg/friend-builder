import 'package:flutter/material.dart';

class ResultBubble extends StatelessWidget {
  final String text;

  ResultBubble({this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.only(left: 8),
        child: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColorDark,
          child: Text(text),
        ));
  }
}

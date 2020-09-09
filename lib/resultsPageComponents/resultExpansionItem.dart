import 'package:flutter/material.dart';

class ResultExpansionItem extends StatelessWidget {
  final String text;
  final IconData iconItem;

  ResultExpansionItem({@required this.text, @required this.iconItem});

  @override
  Widget build(BuildContext context) {
    var iconColor = Color(0xFF777777);
    var textColor = Theme.of(context).textTheme.bodyText1.color;
    return Row(
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(0, 8, 8, 8),
          child: Icon(
            iconItem,
            size: 24,
            color: iconColor,
          ),
        ),
        Flexible(
            child: Text(
          text,
          overflow: TextOverflow.ellipsis,
          maxLines: 8,
          style: TextStyle(
            fontSize: 14.0,
            color: textColor,
          ),
        )),
      ],
    );
  }
}

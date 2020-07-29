import 'package:flutter/material.dart';
import 'package:friend_builder/data/hangout.dart';
import 'package:friend_builder/resultsPageComponents/resultMenu.dart';
import 'package:friend_builder/resultsPageComponents/resultBubbles.dart';

class ClosedResult extends StatelessWidget {
  final Hangout hangout;
  final void Function(Hangout) onDelete;
  final void Function(Hangout) onEdit;

  ClosedResult({
    Key key,
    @required this.hangout,
    @required this.onDelete,
    @required this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        hangout.dateWithoutYear(),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ResultBubbles(
                          contacts: hangout.contacts
                            ..sort((a, b) =>
                                a?.displayName
                                    ?.compareTo(b?.displayName ?? '') ??
                                0)),
                      Expanded(
                        child: Container(
                          alignment: Alignment.centerRight,
                          child: ResultMenu(
                            hangout: hangout,
                            onEdit: onEdit,
                            onDelete: onDelete,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

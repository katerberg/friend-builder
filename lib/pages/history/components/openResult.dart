import 'package:flutter/material.dart';
import 'package:friend_builder/data/hangout.dart';
import 'package:friend_builder/pages/history/components/resultBubbles.dart';
import 'package:friend_builder/pages/history/components/resultExpansionItem.dart';
import 'package:friend_builder/pages/history/components/resultMenu.dart';

class OpenResult extends StatelessWidget {
  final Hangout hangout;
  final void Function(Hangout) onDelete;
  final void Function(Hangout) onEdit;

  OpenResult({
    @required this.hangout,
    @required this.onDelete,
    @required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(8),
      padding: EdgeInsets.all(8),
      color: Color(0xffefefef),
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
                        style: TextStyle(fontWeight: FontWeight.w700),
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
                hangout.notes != ''
                    ? ResultExpansionItem(
                        iconItem: Icons.note, text: hangout.notes)
                    : SizedBox.shrink(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

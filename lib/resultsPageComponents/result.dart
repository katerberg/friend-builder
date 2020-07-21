import 'package:flutter/material.dart';
import 'package:friend_builder/data/hangout.dart';
import 'package:friend_builder/resultsPageComponents/resultBubbles.dart';

class Result extends StatelessWidget {
  final Hangout hangout;
  final void Function(Hangout) onDelete;

  Result({
    Hangout hangout,
    void Function(Hangout) onDelete,
  })  : this.hangout = hangout,
        this.onDelete = onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text(
                    hangout.dateWithoutYear(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ResultBubbles(contacts: hangout.contacts),
                  Expanded(
                    child: Container(
                      alignment: Alignment.centerRight,
                      child: PopupMenuButton(
                        icon: Icon(Icons.more_vert),
                        onSelected: (result) => onDelete(hangout),
                        itemBuilder: (context) => <PopupMenuEntry<String>>[
                          PopupMenuItem<String>(
                            value: 'Delete',
                            child: ListTile(
                              leading: const Icon(Icons.delete),
                              title: Text('Delete'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    ]);
  }
}

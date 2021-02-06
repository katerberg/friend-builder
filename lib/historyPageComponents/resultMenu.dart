import 'package:flutter/material.dart';
import 'package:friend_builder/data/hangout.dart';

class ResultMenu extends StatelessWidget {
  final Hangout hangout;
  final void Function(Hangout) onDelete;
  final void Function(Hangout) onEdit;

  ResultMenu({
    @required this.hangout,
    @required this.onDelete,
    @required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      icon: Icon(Icons.more_vert),
      onSelected: (result) {
        switch (result) {
          case 'Delete':
            onDelete(hangout);
            break;
          case 'Edit':
            onEdit(hangout);
            break;
        }
      },
      itemBuilder: (context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'Edit',
          child: ListTile(
            leading: const Icon(Icons.edit),
            title: Text('Edit'),
          ),
        ),
        PopupMenuItem<String>(
          value: 'Delete',
          child: ListTile(
            leading: const Icon(Icons.delete),
            title: Text('Delete'),
          ),
        ),
      ],
    );
  }
}

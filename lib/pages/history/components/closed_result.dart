import 'package:flutter/material.dart';
import 'package:friend_builder/data/hangout.dart';
import 'package:friend_builder/pages/history/components/result_menu.dart';
import 'package:friend_builder/pages/history/components/result_bubbles.dart';

class ClosedResult extends StatelessWidget {
  final Hangout hangout;
  final Function(Hangout)? onDelete;
  final void Function(Hangout)? onEdit;

  const ClosedResult({
    super.key,
    required this.hangout,
    this.onDelete,
    this.onEdit,
  });

  void _onEdit(Hangout hangout) {
    print('one');
    onEdit?.call(hangout);
  }

  void _onDelete(Hangout hangout) {
    onDelete?.call(hangout);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        hangout.dateWithoutYear(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ResultBubbles(
                          contacts: hangout.contacts
                            ..sort((a, b) =>
                                a.displayName.compareTo(b.displayName))),
                      (onDelete != null && onEdit != null)
                          ? Expanded(
                              child: Container(
                                alignment: Alignment.centerRight,
                                child: ResultMenu(
                                  hangout: hangout,
                                  onEdit: _onEdit,
                                  onDelete: _onDelete,
                                ),
                              ),
                            )
                          : Container(),
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

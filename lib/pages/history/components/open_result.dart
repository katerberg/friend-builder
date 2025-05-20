import 'package:flutter/material.dart';
import 'package:friend_builder/data/hangout.dart';
import 'package:friend_builder/pages/friends/components/contact_tile.dart';
import 'package:friend_builder/pages/history/components/result_bubbles.dart';
import 'package:friend_builder/pages/history/components/result_expansion_item.dart';
import 'package:friend_builder/pages/history/components/result_menu.dart';

class OpenResult extends StatelessWidget {
  final Hangout hangout;
  final void Function(Hangout)? onDelete;
  final void Function(Hangout)? onEdit;

  const OpenResult({
    super.key,
    required this.hangout,
    this.onDelete,
    this.onEdit,
  });

  void _onEdit(Hangout hangout) {
    onEdit?.call(hangout);
  }

  void _onDelete(Hangout hangout) {
    onDelete?.call(hangout);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(8),
      color: const Color(0xffefefef),
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
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      ResultBubbles(
                          contacts: hangout.contacts
                            ..sort((a, b) =>
                                a.displayName.compareTo(b.displayName))),
                      (onEdit != null && onDelete != null)
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
                          : Container()
                    ],
                  ),
                ),
                hangout.notes != ''
                    ? ResultExpansionItem(
                        iconItem: Icons.note, text: hangout.notes)
                    : const SizedBox.shrink(),
                ...(hangout.contacts.toList().map((c) => ContactTile(
                      contact: c,
                    ))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:friend_builder/contacts_permission.dart';
import 'package:friend_builder/data/encodable_contact.dart';
import 'package:friend_builder/data/hangout.dart';
import 'package:friend_builder/pages/history/components/hangout_when_label.dart';
import 'package:friend_builder/pages/history/components/result_menu.dart';
import 'package:friend_builder/pages/history/components/result_bubbles.dart';

class ClosedResult extends StatelessWidget {
  final Hangout hangout;
  final void Function(Hangout)? onDelete;
  final void Function(Hangout)? onEdit;
  final void Function(Hangout)? onRepeat;

  const ClosedResult({
    super.key,
    required this.hangout,
    this.onDelete,
    this.onEdit,
    this.onRepeat,
  });

  bool get _showActions =>
      onDelete != null && onEdit != null && onRepeat != null;

  @override
  Widget build(BuildContext context) {
    final sortedContacts = List<EncodableContact>.from(hangout.contacts)
      ..sort((a, b) => a.safeDisplayName.compareTo(b.safeDisplayName));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 40),
        child: Row(
          children: [
            Expanded(
              child: HangoutWhenLabel(
                hangout: hangout,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ResultBubbles(contacts: sortedContacts),
            if (_showActions)
              ResultMenu(
                hangout: hangout,
                onEdit: onEdit!,
                onDelete: onDelete!,
                onRepeat: onRepeat!,
              ),
          ],
        ),
      ),
    );
  }
}

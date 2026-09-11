import 'package:flutter/material.dart';
import 'package:friend_builder/data/encodable_contact.dart';
import 'package:friend_builder/data/hangout.dart';
import 'package:friend_builder/pages/history/components/hangout_when_label.dart';
import 'package:friend_builder/pages/history/components/result_bubbles.dart';

/// History-style closed hangout row without edit / delete / repeat actions.
class ContactHangoutHistoryRow extends StatelessWidget {
  final Hangout hangout;

  const ContactHangoutHistoryRow({
    super.key,
    required this.hangout,
  });

  @override
  Widget build(BuildContext context) {
    final sortedContacts = List<EncodableContact>.from(hangout.contacts)
      ..sort((a, b) => a.displayName.compareTo(b.displayName));

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
                      Expanded(
                        child: HangoutWhenLabel(
                          hangout: hangout,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ResultBubbles(contacts: sortedContacts),
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

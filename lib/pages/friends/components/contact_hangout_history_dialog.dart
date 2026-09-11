import 'package:flutter/material.dart';
import 'package:friend_builder/data/hangout.dart';
import 'package:friend_builder/pages/friends/components/contact_hangout_history_row.dart';

class ContactHangoutHistoryDialog extends StatelessWidget {
  final String contactName;
  final List<Hangout> hangouts;

  const ContactHangoutHistoryDialog({
    super.key,
    required this.contactName,
    required this.hangouts,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hangouts with $contactName'),
      ),
      body: ListView.builder(
        itemCount: hangouts.length,
        itemBuilder: (context, index) {
          final hangout = hangouts[index];
          return InkWell(
            onTap: () => Navigator.pop(context, hangout),
            child: ContactHangoutHistoryRow(hangout: hangout),
          );
        },
      ),
    );
  }
}

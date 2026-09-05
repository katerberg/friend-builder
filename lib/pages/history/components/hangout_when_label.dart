import 'package:flutter/material.dart';
import 'package:friend_builder/data/hangout.dart';

/// History date/time label. Long-press shows local and UTC instants.
class HangoutWhenLabel extends StatelessWidget {
  final Hangout hangout;
  final TextStyle? style;

  const HangoutWhenLabel({
    super.key,
    required this.hangout,
    this.style,
  });

  void _showDebugDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hangout time'),
        content: Text(hangout.debugLocalAndUtc()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showDebugDialog(context),
      child: Text(
        hangout.dateTimeWithoutYear(),
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
      ),
    );
  }
}

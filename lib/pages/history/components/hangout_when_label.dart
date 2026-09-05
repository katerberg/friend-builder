import 'package:flutter/material.dart';
import 'package:friend_builder/data/hangout.dart';

/// History date/time label. Triple-tap shows local and UTC instants.
class HangoutWhenLabel extends StatefulWidget {
  final Hangout hangout;
  final TextStyle? style;

  const HangoutWhenLabel({
    super.key,
    required this.hangout,
    this.style,
  });

  @override
  State<HangoutWhenLabel> createState() => _HangoutWhenLabelState();
}

class _HangoutWhenLabelState extends State<HangoutWhenLabel> {
  int _tapCount = 0;
  DateTime? _lastTapAt;

  void _handleTap() {
    final now = DateTime.now();
    if (_lastTapAt == null ||
        now.difference(_lastTapAt!) > const Duration(milliseconds: 500)) {
      _tapCount = 0;
    }
    _lastTapAt = now;
    _tapCount++;
    if (_tapCount < 3) {
      return;
    }
    _tapCount = 0;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hangout time'),
        content: Text(widget.hangout.debugLocalAndUtc()),
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
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: Text(
        widget.hangout.dateTimeWithoutYear(),
        style: widget.style,
      ),
    );
  }
}

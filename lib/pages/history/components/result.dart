import 'package:flutter/material.dart';
import 'package:friend_builder/data/hangout.dart';
import 'package:friend_builder/pages/history/components/openResult.dart';
import 'package:friend_builder/pages/history/components/closedResult.dart';

class Result extends StatefulWidget {
  final Hangout hangout;
  final void Function(Hangout) onDelete;
  final void Function(Hangout) onEdit;

  Result({
    @required this.hangout,
    @required this.onDelete,
    @required this.onEdit,
  });

  @override
  _ResultState createState() => _ResultState();
}

class _ResultState extends State<Result> {
  bool isOpen = false;

  void _handleResultTap() {
    setState(() {
      isOpen = !isOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _handleResultTap,
      child: isOpen
          ? OpenResult(
              hangout: widget.hangout,
              onDelete: widget.onDelete,
              onEdit: widget.onEdit,
            )
          : ClosedResult(
              hangout: widget.hangout,
              onDelete: widget.onDelete,
              onEdit: widget.onEdit,
            ),
    );
  }
}

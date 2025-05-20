import 'package:flutter/material.dart';
import 'package:friend_builder/data/hangout.dart';
import 'package:friend_builder/pages/history/components/open_result.dart';
import 'package:friend_builder/pages/history/components/closed_result.dart';

class Result extends StatefulWidget {
  final Hangout hangout;
  final void Function(Hangout)? onDelete;
  final void Function(Hangout)? onEdit;

  const Result({
    super.key,
    required this.hangout,
    this.onDelete,
    this.onEdit,
  });

  @override
  ResultState createState() => ResultState();
}

class ResultState extends State<Result> {
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

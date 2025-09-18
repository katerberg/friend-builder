import 'package:flutter/material.dart';
import 'package:friend_builder/data/hangout.dart';
import 'package:friend_builder/pages/history/components/open_result.dart';
import 'package:friend_builder/pages/history/components/closed_result.dart';

class Result extends StatefulWidget {
  final Hangout hangout;
  final void Function(Hangout) onDelete;
  final void Function(Hangout) onEdit;
  final bool initiallyOpen;

  const Result({
    super.key,
    required this.hangout,
    required this.onDelete,
    required this.onEdit,
    this.initiallyOpen = false,
  });

  @override
  ResultState createState() => ResultState();
}

class ResultState extends State<Result> {
  late bool isOpen;

  @override
  void initState() {
    super.initState();
    isOpen = widget.initiallyOpen;
  }

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

import 'package:flutter/material.dart';
import 'package:friend_builder/storage.dart';
import 'package:friend_builder/data/hangout.dart';
import 'package:friend_builder/resultsPageComponents/result.dart';
import 'package:friend_builder/resultsPageComponents/editDialog.dart';

class ResultsPage extends StatefulWidget {
  final Storage storage = Storage();
  final List<Hangout> hangouts;
  final void Function() updateHangouts;

  ResultsPage({
    Key key,
    @required this.hangouts,
    @required this.updateHangouts,
  }) : super(key: key);

  @override
  _ResultsPageState createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  void _onDelete(Hangout hangout) {
    widget.storage.getHangouts().then((hangouts) {
      widget.storage
          .saveHangouts(
              hangouts..removeWhere((element) => element.id == hangout.id))
          .then((file) {
        widget.updateHangouts();
      });
    });
  }

  void _onEdit(Hangout hangout) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => EditDialog(
          hangout: hangout,
          selectedFriends: hangout.contacts,
          onSubmit: widget.updateHangouts,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  Widget _getResults() {
    if (widget.hangouts == null) {
      return Center(child: CircularProgressIndicator());
    }
    if (widget.hangouts.length == 0) {
      return Center(child: Text('No results yet!'));
    }
    widget.hangouts.sort((h0, h1) => h0.when.isAfter(h1.when) ? -1 : 1);

    return ListView(
      shrinkWrap: true,
      scrollDirection: Axis.vertical,
      children: widget.hangouts
          .map((h) => Result(
                hangout: h,
                onDelete: _onDelete,
                onEdit: _onEdit,
              ))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: (Text('Hangouts')),
      ),
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: _getResults(),
        ),
      ),
    );
  }
}

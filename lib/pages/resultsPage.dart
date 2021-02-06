import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:friend_builder/storage.dart';
import 'package:friend_builder/data/hangout.dart';
import 'package:friend_builder/historyPageComponents/result.dart';
import 'package:friend_builder/historyPageComponents/editDialog.dart';

class ResultsPage extends StatefulWidget {
  final Storage storage = Storage();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  ResultsPage({
    @required this.flutterLocalNotificationsPlugin,
  });

  @override
  _ResultsPageState createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  List<Hangout> _hangouts;

  @override
  void initState() {
    super.initState();
    _refreshHangouts();
  }

  void _refreshHangouts() {
    widget.storage.getHangouts().then((hangouts) {
      setState(() {
        _hangouts = hangouts;
      });
    });
  }

  void _onDelete(Hangout hangout) {
    widget.storage.getHangouts().then((hangouts) {
      widget.storage
          .saveHangouts(
              hangouts..removeWhere((element) => element.id == hangout.id))
          .then((file) {
        setState(() {
          _hangouts = hangouts;
        });
      });
    });
  }

  void _onEdit(Hangout hangout) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => EditDialog(
          flutterLocalNotificationsPlugin:
              widget.flutterLocalNotificationsPlugin,
          hangout: hangout,
          selectedFriends: hangout.contacts,
          onSubmit: _refreshHangouts,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  Widget _getResults() {
    if (_hangouts == null) {
      return Center(child: CircularProgressIndicator());
    }
    if (_hangouts.length == 0) {
      return Center(child: Text('No results yet!'));
    }
    _hangouts.sort((h0, h1) => h0.when.isAfter(h1.when) ? -1 : 1);

    return ListView(
      shrinkWrap: true,
      scrollDirection: Axis.vertical,
      children: _hangouts
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
        child: _getResults(),
      ),
    );
  }
}

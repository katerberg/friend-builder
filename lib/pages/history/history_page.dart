import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:friend_builder/storage.dart';
import 'package:friend_builder/data/hangout.dart';
import 'package:friend_builder/pages/history/components/result.dart';
import 'package:friend_builder/pages/history/components/edit_dialog.dart';
import 'package:friend_builder/utils/notification_helper.dart';

class HistoryPage extends StatefulWidget {
  final Storage storage = Storage();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  final Hangout? initialHangout;

  HistoryPage({
    super.key,
    required this.flutterLocalNotificationsPlugin,
    this.initialHangout,
  });

  @override
  HistoryPageState createState() => HistoryPageState();
}

class HistoryPageState extends State<HistoryPage> {
  List<Hangout> _hangouts = [];

  @override
  void initState() {
    super.initState();
    _refreshHangouts();
  }

  void _refreshHangouts() {
    widget.storage.getHangouts().then((hangouts) {
      if (hangouts != null) {
        setState(() {
          _hangouts = hangouts;
        });
      }
    });
  }

  void _onDelete(Hangout hangout) {
    widget.storage.deleteHangout(hangout).then((_) {
      setState(() {
        _hangouts = _hangouts
          ..removeWhere((element) => element.id == hangout.id);
      });
      scheduleNextNotification(widget.flutterLocalNotificationsPlugin);
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
    if (_hangouts.isEmpty) {
      return const Center(child: Text('No results yet!'));
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
                initiallyOpen: widget.initialHangout?.id == h.id,
              ))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: (const Text('Hangouts')),
      ),
      body: SafeArea(
        child: _getResults(),
      ),
    );
  }
}

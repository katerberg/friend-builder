import 'package:flutter/material.dart';
import 'package:friend_builder/storage.dart';
import 'package:friend_builder/data/hangout.dart';
import 'package:friend_builder/resultsPageComponents/result.dart';

class ResultsPage extends StatefulWidget {
  final Storage storage = Storage();

  @override
  _ResultsPageState createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  List<Hangout> _hangouts;

  @override
  void initState() {
    super.initState();
    widget.storage.getHangouts().then((value) {
      setState(() {
        _hangouts = value;
      });
    });
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
      children: _hangouts.map((h) => Result(hangout: h)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: _getResults(),
        ),
      ),
    );
  }
}

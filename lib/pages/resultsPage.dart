import 'package:flutter/material.dart';
import 'package:friend_builder/storage.dart';

class ResultsPage extends StatefulWidget {
  final Storage storage = Storage();

  @override
  _ResultsPageState createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  List<HangoutData> _hangouts;

  @override
  void initState() {
    super.initState();
    widget.storage.getHangouts().then((value) {
      setState(() {
        _hangouts = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: _hangouts == null
              ? Center(child: CircularProgressIndicator())
              : ListView(
                  shrinkWrap: true,
                  scrollDirection: Axis.vertical,
                  children: _hangouts.map((h) => Text(h.howMany)).toList(),
                ),
        ),
      ),
    );
  }
}

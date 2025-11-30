import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:friend_builder/contacts_permission.dart';
import 'package:friend_builder/storage.dart';
import 'package:friend_builder/data/hangout.dart';
import 'package:friend_builder/pages/history/components/result.dart';
import 'package:friend_builder/pages/history/components/edit_dialog.dart';
import 'package:friend_builder/utils/notification_helper.dart';

class HistoryPage extends StatefulWidget {
  final Storage storage = Storage();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  final Hangout? initialHangout;
  final Function(Contact)? onNavigateToFriend;

  HistoryPage({
    super.key,
    required this.flutterLocalNotificationsPlugin,
    this.initialHangout,
    this.onNavigateToFriend,
  });

  @override
  HistoryPageState createState() => HistoryPageState();
}

class HistoryPageState extends State<HistoryPage> {
  final List<Hangout> _hangouts = [];
  final ScrollController _scrollController = ScrollController();
  static const int _pageSize = 20;
  int _currentOffset = 0;
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadMoreHangouts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      if (kDebugMode) {
        print('Loading more hangouts');
      }
      _loadMoreHangouts();
    }
  }

  Future<void> _loadMoreHangouts() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newHangouts = await widget.storage.getHangoutsPaginated(
        limit: _pageSize,
        offset: _currentOffset,
      );

      setState(() {
        _hangouts.addAll(newHangouts);
        _currentOffset += newHangouts.length;
        _hasMore = newHangouts.length == _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _refreshHangouts() async {
    setState(() {
      _hangouts.clear();
      _currentOffset = 0;
      _hasMore = true;
    });
    await _loadMoreHangouts();
  }

  void _onDelete(Hangout hangout) {
    widget.storage.deleteHangout(hangout).then((_) {
      setState(() {
        _hangouts.removeWhere((element) => element.id == hangout.id);
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
    if (_hangouts.isEmpty && !_isLoading) {
      return const Center(child: Text('No results yet!'));
    }

    if (_hangouts.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _hangouts.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _hangouts.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final hangout = _hangouts[index];
        return Result(
          hangout: hangout,
          onDelete: _onDelete,
          onEdit: _onEdit,
          onNavigateToFriend: widget.onNavigateToFriend,
          initiallyOpen: widget.initialHangout?.id == hangout.id,
        );
      },
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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:friend_builder/contacts_permission.dart';
import 'package:friend_builder/storage.dart';
import 'package:friend_builder/data/hangout.dart';
import 'package:friend_builder/pages/history/components/result.dart';
import 'package:friend_builder/pages/history/components/edit_dialog.dart';
import 'package:friend_builder/utils/notification_helper.dart';
import 'package:friend_builder/pages/stats/stats_page.dart';
import 'package:friend_builder/shared/settings_modal.dart';
import 'package:friend_builder/shared/debug_notification_menu.dart';
import 'package:friend_builder/theme_notifier.dart';

class HistoryPage extends StatefulWidget {
  final Storage storage = Storage();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  final ThemeNotifier themeNotifier;
  final Hangout? initialHangout;
  final Function(Contact)? onNavigateToFriend;

  HistoryPage({
    super.key,
    required this.flutterLocalNotificationsPlugin,
    required this.themeNotifier,
    this.initialHangout,
    this.onNavigateToFriend,
  });

  @override
  HistoryPageState createState() => HistoryPageState();
}

class HistoryPageState extends State<HistoryPage> {
  final List<Hangout> _hangouts = [];
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _itemKeys = {};
  static const int _pageSize = 20;
  int _currentOffset = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  bool _hasScrolledToInitial = false;
  bool _showingStats = false;
  Hangout? _initialHangout;

  @override
  void initState() {
    super.initState();
    _initialHangout = widget.initialHangout;
    _scrollController.addListener(_onScroll);
    _loadMoreHangouts().then((_) {
      if (_initialHangout != null) {
        _scrollToInitialHangout();
      }
    });
  }

  void _scrollToInitialHangout() {
    if (_hasScrolledToInitial) return;

    final index = _hangouts.indexWhere((h) => h.id == _initialHangout?.id);

    if (index != -1) {
      _hasScrolledToInitial = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients && mounted) {
          final key = _itemKeys[index];
          if (key?.currentContext != null) {
            Scrollable.ensureVisible(
              key!.currentContext!,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              alignment: 0.1,
            );
          } else {
            const estimatedItemHeight = 90.0;
            final targetPosition = index * estimatedItemHeight;

            _scrollController.animateTo(
              targetPosition,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
        }
      });
    } else if (_hasMore && !_isLoading) {
      _loadMoreHangouts().then((_) => _scrollToInitialHangout());
    }
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
    final hangoutIndex =
        _hangouts.indexWhere((element) => element.id == hangout.id);

    setState(() {
      _hangouts.removeWhere((element) => element.id == hangout.id);
    });

    widget.storage.deleteHangout(hangout).then((_) {
      scheduleNextNotification(widget.flutterLocalNotificationsPlugin);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Hangout deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            widget.storage.createHangout(hangout).then((_) {
              setState(() {
                _hangouts.insert(hangoutIndex, hangout);
              });
              scheduleNextNotification(widget.flutterLocalNotificationsPlugin);
            });
          },
        ),
        duration: const Duration(seconds: 5),
      ),
    );
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
          onDelete: () => _onDelete(hangout),
          isNewHangout: false,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  void _onRepeat(Hangout originalHangout) async {
    // Create a new hangout with today's date, same participants and notes
    final repeatedHangout = Hangout(
      contacts: List.from(originalHangout.contacts),
      notes: originalHangout.notes,
      when: DateTime.now(),
    );

    // Open the edit dialog for the newly created hangout
    // Note: Don't save to database until user explicitly saves
    if (!mounted) return;
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => EditDialog(
          flutterLocalNotificationsPlugin:
              widget.flutterLocalNotificationsPlugin,
          hangout: repeatedHangout,
          selectedFriends: repeatedHangout.contacts,
          onSubmit: _refreshHangouts,
          onDelete: () =>
              {}, // No-op for repeat - hangout doesn't exist in DB yet
          isNewHangout: true,
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
        final isInitial = _initialHangout?.id == hangout.id;

        if (isInitial && !_itemKeys.containsKey(index)) {
          _itemKeys[index] = GlobalKey();
        }

        return Container(
          key: _itemKeys[index],
          child: Result(
            hangout: hangout,
            onDelete: _onDelete,
            onEdit: _onEdit,
            onRepeat: _onRepeat,
            onNavigateToFriend: widget.onNavigateToFriend,
            initiallyOpen: isInitial,
          ),
        );
      },
    );
  }

  void _openStats() {
    setState(() {
      _showingStats = true;
    });
  }

  void _closeStats() {
    setState(() {
      _showingStats = false;
    });
  }

  Widget? _buildLeading() {
    if (_showingStats) {
      return IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Back to hangouts',
        onPressed: _closeStats,
      );
    }

    final statsButton = IconButton(
      icon: const Icon(Icons.bar_chart),
      tooltip: 'Stats',
      onPressed: _openStats,
    );

    if (kDebugMode) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          statsButton,
          DebugNotificationMenu(
            flutterLocalNotificationsPlugin:
                widget.flutterLocalNotificationsPlugin,
          ),
        ],
      );
    }

    return statsButton;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _buildLeading(),
        leadingWidth: _showingStats ? null : (kDebugMode ? 96 : null),
        title: Text(_showingStats ? 'Top Friends' : 'Hangouts'),
        actions: _showingStats
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => SettingsModal(
                        flutterLocalNotificationsPlugin:
                            widget.flutterLocalNotificationsPlugin,
                        themeNotifier: widget.themeNotifier,
                      ),
                    );
                  },
                ),
              ],
      ),
      body: SafeArea(
        child: _showingStats
            ? StatsPage(storage: widget.storage)
            : _getResults(),
      ),
    );
  }
}

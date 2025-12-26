import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:friend_builder/contacts_permission.dart';
import 'package:collection/collection.dart';
import 'package:friend_builder/missing_permission.dart';
import 'package:friend_builder/utils/string_utils.dart';
import 'package:friend_builder/pages/friends/components/contact_scheduling_dialog.dart';
import 'package:friend_builder/data/hangout.dart';
import 'package:friend_builder/data/friend.dart';
import 'package:friend_builder/data/frequency.dart';
import 'package:friend_builder/storage.dart';
import 'package:friend_builder/pages/friends/components/contact_tile.dart';
import 'package:friend_builder/pages/friends/components/skeleton_contact_tile.dart';
import 'package:friend_builder/utils/notification_helper.dart';
import 'package:friend_builder/utils/contact_sorting.dart';
import 'package:friend_builder/shared/settings_modal.dart';

class FriendsPage extends StatefulWidget {
  final Storage storage = Storage();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  final Function(Hangout)? onNavigateToHistory;
  final Contact? initialContact;

  FriendsPage({
    super.key,
    required this.flutterLocalNotificationsPlugin,
    this.onNavigateToHistory,
    this.initialContact,
  });

  @override
  FriendsPageState createState() => FriendsPageState();
}

class FriendsPageContact {
  Contact contact;
  Frequency? frequency;
  Hangout? latestHangout;

  FriendsPageContact({
    required this.contact,
    required Map<String, Hangout?> latestHangoutMap,
    required Map<String, Friend?> friendMap,
  }) {
    Friend? friend = friendMap[contact.id];
    frequency = friend?.isContactable == true ? friend?.frequency : null;
    latestHangout = latestHangoutMap[contact.id];
  }
}

class FriendsPageState extends State<FriendsPage> {
  Iterable<Contact> _contacts = [];
  Iterable<Contact> _visibleContacts = [];
  List<Contact> _hangoutContacts = [];
  List<Contact> _unusedContacts = [];
  List<Friend> _friends = [];
  bool _missingPermission = false;
  bool _isLoading = true;
  final TextEditingController typeaheadController =
      TextEditingController(text: '');

  Map<String, Hangout?> _latestHangoutMap = {};
  Map<String, Friend?> _friendMap = {};
  final Map<String, FriendsPageContact> _contactCache = {};

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _getContacts();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }

    await Future.wait([_refreshFriends(), _refreshHangouts()]);

    if (mounted) {
      await _sortContacts();

      if (widget.initialContact != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final matchingContact = _contacts.firstWhereOrNull(
            (c) => c.id == widget.initialContact!.id,
          );
          if (matchingContact != null) {
            _handleContactPress(matchingContact);
          }
        });
      }
    }
  }

  void _buildLatestHangoutMap(List<Hangout> hangouts) {
    final Map<String, Hangout?> newMap = {};

    for (final hangout in hangouts) {
      for (final contact in hangout.contacts) {
        final existingHangout = newMap[contact.identifier];
        if (existingHangout == null ||
            hangout.when.isAfter(existingHangout.when)) {
          newMap[contact.identifier] = hangout;
        }
      }
    }

    _latestHangoutMap = newMap;
    _contactCache.clear();
  }

  void _buildFriendMap(List<Friend> friends) {
    _friendMap = {for (var friend in friends) friend.contactIdentifier: friend};
    _contactCache.clear();
  }

  FriendsPageContact _getOrCreateContactData(Contact contact) {
    return _contactCache.putIfAbsent(
      contact.id,
      () => FriendsPageContact(
        contact: contact,
        latestHangoutMap: _latestHangoutMap,
        friendMap: _friendMap,
      ),
    );
  }

  Future<void> _refreshHangouts() async {
    var hangouts =
        await widget.storage.getHangoutsPaginated(limit: 100, offset: 0);
    if (mounted) {
      setState(() {
        _buildLatestHangoutMap(hangouts);
      });
    }

    if (hangouts.length == 100) {
      _loadRemainingHangouts(100, hangouts);
    }
  }

  void _loadRemainingHangouts(
      int offset, List<Hangout> accumulatedHangouts) async {
    const int pageSize = 100;
    var moreHangouts = await widget.storage
        .getHangoutsPaginated(limit: pageSize, offset: offset);

    if (mounted && moreHangouts.isNotEmpty) {
      accumulatedHangouts.addAll(moreHangouts);
      setState(() {
        _buildLatestHangoutMap(accumulatedHangouts);
      });
      _sortContacts();

      if (moreHangouts.length == pageSize) {
        _loadRemainingHangouts(offset + pageSize, accumulatedHangouts);
      }
    }
  }

  Future<void> _refreshFriends() async {
    var friends = await Storage.getFriends();
    if (mounted) {
      setState(() {
        _friends = friends ?? [];
        _buildFriendMap(_friends);
      });
    }
  }

  Future<void> _getContacts() async {
    var contactPermission = await ContactPermissionService().getContacts();
    if (mounted) {
      setState(() {
        _missingPermission = contactPermission.missingPermission;
        _contacts = contactPermission.contacts;
        _visibleContacts = contactPermission.contacts;
      });
    }
  }

  void _handleContactsFilter(Iterable<Contact> contacts) {
    setState(() {
      _visibleContacts = contacts;
    });
    _sortContacts(); // Fire and forget - UI will update when sort completes
  }

  Future<void> _sortContacts() async {
    final sortableContacts = _visibleContacts.map((c) {
      final friend = _friendMap[c.id];
      final hangout = _latestHangoutMap[c.id];
      return SortableContact(
        id: c.id,
        displayName: c.displayName,
        frequencyValue: friend?.frequency.value,
        lastHangoutDate: hangout?.when,
        isContactable: friend?.isContactable ?? false,
      );
    }).toList();

    final result = await compute(sortContactsForDisplay, sortableContacts);

    if (!mounted) return;

    final contactMap = {for (var c in _visibleContacts) c.id: c};

    setState(() {
      _hangoutContacts = result.hangoutContactIds
          .map((id) => contactMap[id])
          .whereType<Contact>()
          .toList();
      _unusedContacts = result.unusedContactIds
          .map((id) => contactMap[id])
          .whereType<Contact>()
          .toList();
    });
  }

  void _clearTextField() {
    typeaheadController.text = '';
    FocusScope.of(context).requestFocus(FocusNode());
    _handleContactChange('');
  }

  Future<void> _handleContactPress(Contact? contact) async {
    List<Friend>? friends = await Storage.getFriends();
    Friend? friend = friends?.firstWhereOrNull(
      (element) => element.contactIdentifier == contact?.id,
    );
    if (contact == null) {
      return;
    }
    Friend? result = await Navigator.push<Friend>(
      // ignore: use_build_context_synchronously
      context,
      MaterialPageRoute(
        builder: (context) => ContactSchedulingDialog(
            flutterLocalNotificationsPlugin:
                widget.flutterLocalNotificationsPlugin,
            contact: contact,
            friend: friend,
            onNavigateToHistory: widget.onNavigateToHistory),
        fullscreenDialog: true,
      ),
    );
    if (result == null) {
      return;
    }
    scheduleNextNotification(widget.flutterLocalNotificationsPlugin);
    if (friends != null) {
      var index = friends.indexWhere(
          (element) => element.contactIdentifier == result.contactIdentifier);
      if (index == -1) {
        friends.add(result);
      } else {
        friends[index] = result;
      }
    } else {
      friends = [result];
    }
    _clearTextField();
    widget.storage.saveFriends(friends).then((_) {
      _refreshFriends().then((_) {
        _sortContacts();
      });
    });
  }

  void _handleContactChange(String pattern) {
    var exactMatches = _contacts.where((element) =>
        (element.displayName).toLowerCase().contains(pattern.toLowerCase()));
    if (exactMatches.isNotEmpty) {
      return _handleContactsFilter(exactMatches.toList()
        ..sort((a, b) => (a.displayName).compareTo(b.displayName)));
    }
    var matchingLevel = _contacts.where((element) =>
        StringUtils.getComparison(element.displayName, pattern) > 0.3);
    _handleContactsFilter(matchingLevel.isNotEmpty ? matchingLevel : _contacts);
  }

  Widget _buildSearchField() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        textCapitalization: TextCapitalization.sentences,
        autocorrect: false,
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search),
        ),
        controller: typeaheadController,
        onChanged: _handleContactChange,
      ),
    );
  }

  Widget _buildContactTile(Contact contact, {bool withFrequency = false}) {
    if (withFrequency) {
      final contactData = _getOrCreateContactData(contact);
      return ContactTile(
        contact: contactData.contact,
        onPressed: _handleContactPress,
        frequency: contactData.frequency,
        latestHangout: contactData.latestHangout,
      );
    }
    return ContactTile(contact: contact, onPressed: _handleContactPress);
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_missingPermission) {
      body = const MissingPermission(
        isWhite: true,
      );
    } else if (_isLoading) {
      body = ListView.builder(
        itemCount: 11,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildSearchField();
          }
          return const SkeletonContactTile();
        },
      );
    } else {
      final filteredUnusedContacts =
          _unusedContacts.where((c) => c.displayName != '').toList();
      final hasDivider = _hangoutContacts.isNotEmpty;

      final totalItems = 1 +
          _hangoutContacts.length +
          (hasDivider ? 1 : 0) +
          filteredUnusedContacts.length;

      body = ListView.builder(
        itemCount: totalItems,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildSearchField();
          }

          final hangoutIndex = index - 1;
          if (hangoutIndex < _hangoutContacts.length) {
            return _buildContactTile(
              _hangoutContacts[hangoutIndex],
              withFrequency: true,
            );
          }

          if (hasDivider && hangoutIndex == _hangoutContacts.length) {
            return const Divider();
          }

          final unusedIndex =
              hangoutIndex - _hangoutContacts.length - (hasDivider ? 1 : 0);
          return _buildContactTile(filteredUnusedContacts[unusedIndex]);
        },
      );
    }

    return GestureDetector(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Contacts'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => SettingsModal(
                    flutterLocalNotificationsPlugin:
                        widget.flutterLocalNotificationsPlugin,
                  ),
                );
              },
            ),
          ],
        ),
        body: body,
      ),
      onTap: () {
        if (mounted) {
          FocusScope.of(context).requestFocus(FocusNode());
        }
      },
    );
  }
}

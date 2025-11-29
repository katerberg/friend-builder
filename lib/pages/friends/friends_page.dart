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
import 'package:friend_builder/utils/scheduling.dart';

class FriendsPage extends StatefulWidget {
  final Storage storage = Storage();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  final Function(Hangout)? onNavigateToHistory;

  FriendsPage({
    super.key,
    required this.flutterLocalNotificationsPlugin,
    this.onNavigateToHistory,
  });

  @override
  FriendsPageState createState() => FriendsPageState();
}

class FriendsPageContact {
  Contact contact;
  Frequency? frequency;
  Hangout? latestHangout;

  FriendsPageContact(
      this.contact, List<Hangout> hangouts, List<Friend> friends) {
    Friend? friend = friends
        .firstWhereOrNull((element) => element.contactIdentifier == contact.id);
    frequency = friend?.isContactable == true ? friend?.frequency : null;
    latestHangout = hangouts.isEmpty
        ? null
        : hangouts.reduce((value, hangout) {
            if (hangout.hasContact(contact) &&
                (value.when.compareTo(hangout.when) < 0 ||
                    !value.hasContact(contact))) {
              return hangout;
            }
            return value;
          });
    latestHangout = latestHangout != null && latestHangout!.hasContact(contact)
        ? latestHangout
        : null;
  }
}

class FriendsPageState extends State<FriendsPage> {
  Iterable<Contact> _contacts = [];
  Iterable<Contact> _visibleContacts = [];
  List<Contact> _hangoutContacts = [];
  List<Contact> _unusedContacts = [];
  List<Hangout> _hangouts = [];
  List<Friend> _friends = [];
  bool _missingPermission = false;
  bool _isLoading = true;
  final TextEditingController typeaheadController =
      TextEditingController(text: '');

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
      _sortContacts();
    }
  }

  Future<void> _refreshHangouts() async {
    var hangouts = await widget.storage.getHangouts();
    if (mounted) {
      setState(() {
        _hangouts = hangouts ?? [];
      });
    }
  }

  Future<void> _refreshFriends() async {
    var friends = await Storage.getFriends();
    if (mounted) {
      setState(() {
        _friends = friends ?? [];
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
    _sortContacts();
  }

  int _compareContactsByName(Contact? c1, Contact? c2) {
    return (c1?.displayName ?? '').compareTo(c2?.displayName ?? '');
  }

  int _compareContactsByTimeAndName(Contact c1, Contact c2) {
    var cOne = FriendsPageContact(c1, _hangouts, _friends);
    var cTwo = FriendsPageContact(c2, _hangouts, _friends);
    int days1 = Scheduling.daysLeft(
        cOne.frequency ?? Frequency.fromType('Weekly'),
        cOne.latestHangout?.when);
    int days2 = Scheduling.daysLeft(
        cTwo.frequency ?? Frequency.fromType('Weekly'),
        cTwo.latestHangout?.when);
    return days1 - days2 == 0
        ? (c1.displayName).compareTo(c2.displayName)
        : days1 - days2;
  }

  void _sortContacts() {
    setState(() {
      _hangoutContacts = _visibleContacts
          .toList()
          .where((c) => _friends.any((element) =>
              element.contactIdentifier == c.id && element.isContactable))
          .toList()
        ..sort(_compareContactsByTimeAndName);
      _unusedContacts = _visibleContacts
          .toList()
          .where((c) => !_friends.any((element) =>
              element.contactIdentifier == c.id && element.isContactable))
          .toList()
        ..sort(_compareContactsByName);
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

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_missingPermission) {
      body = const MissingPermission(
        isWhite: true,
      );
    } else if (_isLoading) {
      body = ListView(
        children: [
          Container(
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
          ),
          ...List.generate(10, (index) => const SkeletonContactTile()),
        ],
      );
    } else {
      var safeHangoutContacts = _hangoutContacts;
      body = ListView(
        children: [
          Container(
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
          ),
          ...(safeHangoutContacts
              .map((c) => FriendsPageContact(c, _hangouts, _friends))
              .toList()
              .map((c) => ContactTile(
                    contact: c.contact,
                    onPressed: _handleContactPress,
                    frequency: c.frequency,
                    latestHangout: c.latestHangout,
                  ))),
          safeHangoutContacts.isNotEmpty
              ? const Divider()
              : const SizedBox.shrink(),
          ...(_unusedContacts).whereNot((c) => c.displayName == '').map(
              (c) => ContactTile(contact: c, onPressed: _handleContactPress)),
        ],
      );
    }

    return GestureDetector(
      child: Scaffold(
        appBar: AppBar(
          title: (const Text('Contacts')),
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

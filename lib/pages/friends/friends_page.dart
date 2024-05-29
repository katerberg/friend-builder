import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:friend_builder/contacts.dart';
import 'package:collection/collection.dart';
import 'package:friend_builder/utils/string_utils.dart';
import 'package:friend_builder/pages/friends/components/contact_scheduling.dart';
import 'package:friend_builder/data/hangout.dart';
import 'package:friend_builder/data/friend.dart';
import 'package:friend_builder/storage.dart';
import 'package:friend_builder/pages/friends/components/contact_tile.dart';
import 'package:friend_builder/utils/notification_helper.dart';
import 'package:friend_builder/utils/scheduling.dart';
import 'package:permission_handler/permission_handler.dart';

class FriendsPage extends StatefulWidget {
  final Storage storage = Storage();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  FriendsPage({super.key, required this.flutterLocalNotificationsPlugin});

  @override
  FriendsPageState createState() => FriendsPageState();
}

class FriendsPageContact {
  Contact contact;
  String? frequency;
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
  final TextEditingController typeaheadController =
      TextEditingController(text: '');

  @override
  void initState() {
    Future.wait([_refreshFriends(), _getContacts(), _refreshHangouts()])
        .then((list) => _sortContacts());
    super.initState();
  }

  Future<void> _refreshHangouts() async {
    var hangouts = await widget.storage.getHangouts();
    setState(() {
      _hangouts = hangouts ?? [];
    });
  }

  Future<void> _refreshFriends() async {
    var friends = await Storage.getFriends();
    setState(() {
      _friends = friends ?? [];
    });
  }

  Future<void> _getContacts() async {
    var contactPermission = await ContactPermissionService().getContacts();
    setState(() {
      _missingPermission = contactPermission.missingPermission;
      _contacts = contactPermission.contacts;
      _visibleContacts = contactPermission.contacts;
    });
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
        cOne.frequency ?? 'Weekly', cOne.latestHangout?.when);
    int days2 = Scheduling.daysLeft(
        cTwo.frequency ?? 'Weekly', cTwo.latestHangout?.when);
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

  void _upsertNotifications(Friend result, Contact contact) {
    List<Hangout> contactHangouts = _hangouts
        .where((element) =>
            element.contacts.any((hc) => hc.identifier == contact.id))
        .toList();
    DateTime latestTime = contactHangouts.isEmpty
        ? DateTime.now()
        : contactHangouts
            .reduce((value, element) =>
                element.when.compareTo(value.when) > 0 ? element : value)
            .when;
    scheduleNotification(
      widget.flutterLocalNotificationsPlugin,
      contact.id.hashCode,
      'Want to chat with ${contact.displayName}?',
      "It's been a minute!",
      Scheduling.howLong(latestTime, result.frequency),
    );
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
        builder: (context) =>
            ContactSchedulingDialog(contact: contact, friend: friend),
        fullscreenDialog: true,
      ),
    );
    if (result == null) {
      return;
    }
    if (result.isContactable == true) {
      _upsertNotifications(result, contact);
    } else {
      cancelNotification(
          widget.flutterLocalNotificationsPlugin, contact.id.hashCode);
    }
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

  void _handleContactPermissionRequest() {
    openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_missingPermission) {
      body = Center(
        child: Column(
          children: [
            Container(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: const Text(
                  'Missing contacts permission',
                )),
            OutlinedButton(
              onPressed: _handleContactPermissionRequest,
              child: const Text('Change Permissions'),
            )
          ],
        ),
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
          ...(_unusedContacts).map(
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

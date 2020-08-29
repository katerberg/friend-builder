import 'package:flutter/material.dart';
import 'package:friend_builder/stringUtils.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:friend_builder/contactPageComponents/contactScheduling.dart';
import 'package:friend_builder/data/hangout.dart';
import 'package:friend_builder/data/friend.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:friend_builder/storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:friend_builder/contactPageComponents/contactTile.dart';
import 'package:friend_builder/notificationHelper.dart';
import 'package:friend_builder/schedulingUtils.dart';

class ContactsPage extends StatefulWidget {
  final Storage storage = Storage();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  ContactsPage({@required this.flutterLocalNotificationsPlugin});

  @override
  _ContactsPageState createState() => _ContactsPageState();
}

class ContactPageContact {
  Contact contact;
  String frequency;
  Hangout latestHangout;

  ContactPageContact(
      Contact contact, List<Hangout> hangouts, List<Friend> friends) {
    this.contact = contact;
    Friend friend = friends.firstWhere(
        (element) => element.contactIdentifier == contact.identifier,
        orElse: () => null);
    this.frequency = friend?.isContactable == true ? friend?.frequency : null;
    this.latestHangout = hangouts.length < 1
        ? null
        : hangouts.reduce((value, hangout) {
            if (hangout.hasContact(contact) &&
                (value.when.compareTo(hangout.when) < 0 ||
                    !value.hasContact(contact))) {
              return hangout;
            }
            return value;
          });
    this.latestHangout =
        this.latestHangout != null && this.latestHangout.hasContact(contact)
            ? this.latestHangout
            : null;
  }
}

class _ContactsPageState extends State<ContactsPage> {
  Iterable<Contact> _contacts;
  Iterable<Contact> _visibleContacts;
  List<Contact> _hangoutContacts;
  List<Contact> _unusedContacts;
  List<Hangout> _hangouts;
  List<Friend> _friends;
  bool _missingPermission = false;
  final TextEditingController typeaheadController =
      TextEditingController(text: '');

  @override
  void initState() {
    Future.wait([_refreshFriends(), _getContacts(), _refreshHangouts()])
        .then((list) {
      _sortContacts();
    });
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
    bool missingPermission = await _isMissingPermission();
    final Iterable<Contact> contacts = await ContactsService.getContacts();
    setState(() {
      _missingPermission = missingPermission;
      _contacts = contacts;
      _visibleContacts = contacts;
    });
  }

  void _handleContactsFilter(Iterable<Contact> contacts) {
    setState(() {
      _visibleContacts = contacts;
    });
    _sortContacts();
  }

  int _compareContactsByName(Contact c1, Contact c2) {
    return (c1?.displayName ?? '').compareTo(c2?.displayName ?? '');
  }

  int _compareContactsByTimeAndName(Contact c1, Contact c2) {
    var cOne = ContactPageContact(c1, _hangouts, _friends);
    var cTwo = ContactPageContact(c2, _hangouts, _friends);
    int days1 =
        SchedulingUtils.daysLeft(cOne.frequency, cOne.latestHangout?.when);
    int days2 =
        SchedulingUtils.daysLeft(cTwo.frequency, cTwo.latestHangout?.when);
    return days1 - days2 == 0
        ? (c1?.displayName ?? '').compareTo(c2?.displayName ?? '')
        : days1 - days2;
  }

  void _sortContacts() {
    setState(() {
      _hangoutContacts = _visibleContacts
          .toList()
          .where((c) => _friends.any((element) =>
              element.contactIdentifier == c.identifier &&
              element.isContactable))
          .toList()
            ..sort(_compareContactsByTimeAndName);
      _unusedContacts = _visibleContacts
          .toList()
          .where((c) => !_friends.any((element) =>
              element.contactIdentifier == c.identifier &&
              element.isContactable))
          .toList()
            ..sort(_compareContactsByName);
    });
  }

  Future<PermissionStatus> _getPermission() async {
    final PermissionStatus permission = await Permission.contacts.status;
    if (permission != PermissionStatus.granted &&
        permission != PermissionStatus.denied) {
      final Map<Permission, PermissionStatus> permissionStatus =
          await [Permission.contacts].request();
      return permissionStatus[Permission.contacts] ??
          PermissionStatus.undetermined;
    } else {
      return permission;
    }
  }

  Future<bool> _isMissingPermission() async {
    final PermissionStatus permissionStatus = await _getPermission();
    if (permissionStatus == PermissionStatus.granted) {
      return false;
    } else {
      return true;
    }
  }

  void _clearTextField() {
    typeaheadController.text = '';
    FocusScope.of(context).requestFocus(new FocusNode());
    _handleContactSelection('');
  }

  Future<void> _handleContactPress(Contact contact) async {
    List<Friend> friends = await Storage.getFriends();
    Friend friend = friends.firstWhere(
        (element) => element.contactIdentifier == contact.identifier,
        orElse: () => null);
    Friend result = await Navigator.push<Friend>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ContactSchedulingDialog(contact: contact, friend: friend),
        fullscreenDialog: true,
      ),
    );
    if (result.isContactable) {
      List<Hangout> contactHangouts = _hangouts
          .where((element) =>
              element.contacts.any((hc) => hc.identifier == contact.identifier))
          .toList();
      DateTime latestTime = contactHangouts.isEmpty
          ? DateTime.now()
          : contactHangouts
              .reduce((value, element) =>
                  element.when.compareTo(value.when) > 0 ? element : value)
              .when;
      scheduleNotification(
        widget.flutterLocalNotificationsPlugin,
        contact.identifier.hashCode,
        'Want to chat with ' + contact.displayName + '?',
        "It's been a minute!",
        SchedulingUtils.howLong(latestTime, result.frequency),
      );
    } else {
      cancelNotification(
          widget.flutterLocalNotificationsPlugin, contact.identifier.hashCode);
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
    Storage.saveFriends(friends).then((_) {
      _refreshFriends().then((_) {
        _sortContacts();
      });
    });
  }

  void _handleContactSelection(String pattern) {
    var exactMatches = _contacts.where((element) => (element?.displayName ?? '')
        .toLowerCase()
        .contains(pattern.toLowerCase()));
    if (exactMatches.length > 0) {
      return _handleContactsFilter(exactMatches.toList()
        ..sort(
            (a, b) => (a?.displayName ?? '').compareTo(b?.displayName ?? '')));
    }
    var matchingLevel = _contacts.where((element) =>
        StringUtils.getComparison(element?.displayName, pattern) > 0.3);
    _handleContactsFilter(matchingLevel.length > 0 ? matchingLevel : _contacts);
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_missingPermission) {
      body = Center(
        child: Text(
          'Missing contacts permission',
        ),
      );
    } else if (_contacts == null || _hangouts == null) {
      body = Center(child: const CircularProgressIndicator());
    } else {
      body = ListView(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            child: TextField(
              textCapitalization: TextCapitalization.sentences,
              autocorrect: false,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
              ),
              controller: typeaheadController,
              onChanged: _handleContactSelection,
            ),
          ),
          ...(_hangoutContacts
              .map((c) => ContactPageContact(c, _hangouts, _friends))
              .toList()
              .map((c) => ContactTile(
                    contact: c.contact,
                    onPressed: _handleContactPress,
                    frequency: c.frequency,
                    latestHangout: c.latestHangout,
                  ))),
          _hangoutContacts.isNotEmpty ? Divider() : SizedBox.shrink(),
          ..._unusedContacts.map(
              (c) => ContactTile(contact: c, onPressed: _handleContactPress)),
        ],
      );
    }

    return GestureDetector(
      child: Scaffold(
        appBar: AppBar(
          title: (Text('Contacts')),
        ),
        body: body,
      ),
      onTap: () {
        FocusScope.of(context).requestFocus(new FocusNode());
      },
    );
  }
}

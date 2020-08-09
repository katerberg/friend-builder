import 'package:flutter/material.dart';
import 'package:friend_builder/contactPageComponents/contactScheduling.dart';
import 'package:friend_builder/data/hangout.dart';
import 'package:friend_builder/data/friend.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:friend_builder/storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:friend_builder/contactPageComponents/contactTile.dart';

class ContactsPage extends StatefulWidget {
  final Storage storage = Storage();
  @override
  _ContactsPageState createState() => _ContactsPageState();
}

class ContactPageContact {
  Contact contact;
  Hangout latestHangout;

  ContactPageContact(Contact contact, List<Hangout> hangouts) {
    this.contact = contact;
    this.latestHangout = hangouts.reduce((value, hangout) {
      var contacts = hangout.contacts
          .where((c) => c.identifier == this.contact.identifier);
      if (contacts.length == 1 && value.when.compareTo(hangout.when) < 0) {
        return hangout;
      }
      return value;
    });
  }
}

class _ContactsPageState extends State<ContactsPage> {
  Iterable<Contact> _contacts;
  List<Contact> _hangoutContacts;
  List<Contact> _unusedContacts;
  List<Hangout> _hangouts;
  bool _missingPermission = false;

  @override
  void initState() {
    Future.wait([_getContacts(), _refreshHangouts()]).then((list) {
      _sortContacts();
    });
    super.initState();
  }

  Future<void> _refreshHangouts() async {
    var hangouts = await widget.storage.getHangouts();
    setState(() {
      _hangouts = hangouts;
    });
  }

  Future<void> _getContacts() async {
    bool missingPermission = await _isMissingPermission();
    final Iterable<Contact> contacts = await ContactsService.getContacts();
    setState(() {
      _missingPermission = missingPermission;
      _contacts = contacts;
    });
  }

  int _compareContacts(Contact c1, Contact c2) {
    return (c1?.displayName ?? '').compareTo(c2?.displayName ?? '');
  }

  void _sortContacts() {
    setState(() {
      _hangoutContacts = _contacts
          .toList()
          .where((c) => _hangouts.any((element) =>
              element.contacts.any((hc) => hc.identifier == c.identifier)))
          .toList()
            ..sort(_compareContacts);
      _unusedContacts = _contacts
          .toList()
          .where((c) => !_hangouts.any((element) =>
              element.contacts.any((hc) => hc.identifier == c.identifier)))
          .toList()
            ..sort(_compareContacts);
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
    Storage.saveFriends(friends);
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
          ...(_hangoutContacts
                  .map((c) => ContactPageContact(c, _hangouts))
                  .toList()
                    ..sort((c1, c2) => (c1?.latestHangout?.when ??
                            DateTime.now())
                        .compareTo(c2?.latestHangout?.when ?? DateTime.now())))
              .map((c) => ContactTile(
                    contact: c.contact,
                    onPressed: _handleContactPress,
                    isBold: true,
                    latestHangout: c.latestHangout,
                  )),
          _hangoutContacts.isNotEmpty ? Divider() : SizedBox.shrink(),
          ..._unusedContacts.map(
              (c) => ContactTile(contact: c, onPressed: _handleContactPress)),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: (Text('Contacts')),
      ),
      body: body,
    );
  }
}

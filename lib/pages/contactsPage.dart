import 'package:flutter/material.dart';
import 'package:friend_builder/data/hangout.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:friend_builder/data/encodableContact.dart';
import 'package:friend_builder/storage.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactsPage extends StatefulWidget {
  final Storage storage = Storage();
  @override
  _ContactsPageState createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  Iterable<Contact> _contacts;
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

  void _sortContacts() {
    setState(() {
      _contacts = _contacts.toList()
        ..sort((c1, c2) {
          var c1Exists = _hangouts.any((element) =>
              element.contacts.any((c) => c.identifier == c1.identifier));
          var c2Exists = _hangouts.any((element) =>
              element.contacts.any((c) => c.identifier == c2.identifier));
          if ((c1Exists || c2Exists) && (!c1Exists || !c2Exists)) {
            return c1Exists ? -1 : 1;
          }
          return (c1?.displayName ?? '').compareTo(c2?.displayName ?? '');
        });
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

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_missingPermission) {
      body = Center(
        child: Text(
          'Missing contacts permission',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      );
    } else if (_contacts == null || _hangouts == null) {
      body = Center(child: const CircularProgressIndicator());
    } else {
      // _contacts.sort((c1,c2) => )
      body = ListView(
        children: _contacts
            .map((c) => ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 2, horizontal: 18),
                  leading: EncodableContact.fromContact(c).getAvatar(context),
                  title: Text(c?.displayName ?? ''),
                  //This can be further expanded to showing contacts detail
                  // onPressed().
                ))
            .toList(),
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

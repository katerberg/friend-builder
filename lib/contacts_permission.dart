import 'dart:typed_data';
import 'package:friend_builder/permissions.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

export 'package:flutter_contacts/flutter_contacts.dart' show Contact;

class ContactPermission {
  final Iterable<Contact> contacts;
  final bool missingPermission;
  const ContactPermission(
    this.missingPermission,
    this.contacts,
  );
}

class ContactPermissionService {
  var permissionsUtils = PermissionsUtils();

  static final Map<String, Uint8List?> _photoCache = {};

  Future<ContactPermission> getContacts() async {
    bool missingPermission =
        await permissionsUtils.isMissingPermission(Permission.contacts);
    List<Contact> contacts = await FlutterContacts.getContacts(
        withPhoto: false, withProperties: true);
    return ContactPermission(missingPermission, contacts);
  }

  static Future<Uint8List?> getContactPhoto(String contactId) async {
    if (_photoCache.containsKey(contactId)) {
      return _photoCache[contactId];
    }

    final contact =
        await FlutterContacts.getContact(contactId, withPhoto: true);
    final photo = contact?.photo;

    _photoCache[contactId] = photo;

    return photo;
  }
}

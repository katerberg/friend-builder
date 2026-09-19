import 'dart:typed_data';
import 'package:friend_builder/permissions.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

export 'package:flutter_contacts/flutter_contacts.dart' show Contact;

extension ContactFields on Contact {
  String get safeId => id ?? '';
  String get safeDisplayName => displayName ?? '';
  Uint8List? get photoBytes => photo?.fullSize ?? photo?.thumbnail;
}

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
    final contacts = await FlutterContacts.getAll(
      properties: ContactProperties.allProperties,
    );
    return ContactPermission(missingPermission, contacts);
  }

  static Future<Uint8List?> getContactPhoto(String contactId) async {
    if (_photoCache.containsKey(contactId)) {
      return _photoCache[contactId];
    }

    final contact = await FlutterContacts.get(
      contactId,
      properties: {
        ContactProperty.photoFullRes,
        ContactProperty.photoThumbnail,
      },
    );
    final photo =
        contact?.photo?.fullSize ?? contact?.photo?.thumbnail;

    _photoCache[contactId] = photo;

    return photo;
  }
}

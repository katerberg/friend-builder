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

  Future<ContactPermission> getContacts() async {
    bool missingPermission =
        await permissionsUtils.isMissingPermission(Permission.contacts);
    List<Contact> contacts = await FlutterContacts.getContacts(
        withPhoto: true, withProperties: true);
    return ContactPermission(missingPermission, contacts);
  }
}

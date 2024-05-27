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
  Future<ContactPermission> getContacts() async {
    bool missingPermission = await _isMissingPermission();
    List<Contact> contacts = await FlutterContacts.getContacts(
        withPhoto: true, withProperties: true);
    return ContactPermission(missingPermission, contacts);
  }

  Future<PermissionStatus?> _getPermission() async {
    final PermissionStatus permission = await Permission.contacts.request();

    if (permission != PermissionStatus.granted &&
        permission != PermissionStatus.denied) {
      final Map<Permission, PermissionStatus> permissionStatus =
          await [Permission.contacts].request();
      return permissionStatus[Permission.contacts];
    } else {
      return permission;
    }
  }

  Future<bool> _isMissingPermission() async {
    final PermissionStatus? permissionStatus = await _getPermission();
    if (permissionStatus == PermissionStatus.granted) {
      return false;
    } else {
      return true;
    }
  }
}

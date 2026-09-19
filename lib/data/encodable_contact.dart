import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class EncodableContact extends Contact {
  final String middleName;
  final String givenName;
  final String identifier;
  final String familyName;
  final Uint8List? avatar;

  EncodableContact({
    required String displayName,
    required this.middleName,
    required this.givenName,
    required this.identifier,
    required this.familyName,
    this.avatar,
  }) : super(
          id: identifier,
          displayName: displayName,
          name: Name(
            first: givenName,
            middle: middleName,
            last: familyName,
          ),
          photo: avatar != null ? Photo(fullSize: avatar) : null,
        );

  factory EncodableContact.fromContact(Contact contact) {
    if (contact is EncodableContact) {
      return EncodableContact(
        displayName: contact.displayName ?? '',
        middleName: contact.middleName,
        givenName: contact.givenName,
        identifier: contact.identifier.isNotEmpty
            ? contact.identifier
            : (contact.id ?? ''),
        familyName: contact.familyName,
        avatar: contact.avatar ??
            contact.photo?.fullSize ??
            contact.photo?.thumbnail,
      );
    }
    return EncodableContact(
      displayName: contact.displayName ?? '',
      middleName: contact.name?.middle ?? '',
      givenName: contact.name?.first ?? '',
      identifier: contact.id ?? '',
      familyName: contact.name?.last ?? '',
      avatar: contact.photo?.fullSize ?? contact.photo?.thumbnail,
    );
  }

  CircleAvatar getAvatar(context, [double? fontSize]) {
    if (avatar == null) {
      return CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor,
        child: Text(
          initials(),
          style: TextStyle(fontSize: fontSize ?? 14, color: Colors.white),
        ),
      );
    }
    return CircleAvatar(
      backgroundImage: MemoryImage(avatar!),
    );
  }

  String initials() {
    return ((givenName.isNotEmpty == true ? givenName[0] : "") +
            (familyName.isNotEmpty == true ? familyName[0] : ""))
        .toUpperCase();
  }

  factory EncodableContact.fromJson(Map<String, dynamic> parsedJson) {
    return EncodableContact(
      displayName: parsedJson['displayName'] ?? "",
      middleName: parsedJson['middleName'] ?? "",
      givenName: parsedJson['givenName'] ?? "",
      identifier: parsedJson['identifier'] ?? "",
      familyName: parsedJson['familyName'] ?? "",
      avatar: parsedJson['avatar'] == null
          ? null
          : Uint8List.fromList(parsedJson['avatar'].cast<int>()),
    );
  }

  factory EncodableContact.fromMap(Map<String, dynamic> parsedJson) {
    return EncodableContact(
      displayName: parsedJson['displayName'] ?? "",
      middleName: parsedJson['middleName'] ?? "",
      givenName: parsedJson['givenName'] ?? "",
      identifier: parsedJson['identifier'] ?? "",
      familyName: parsedJson['familyName'] ?? "",
      avatar: parsedJson['avatar'] == null
          ? null
          : Uint8List.fromList(parsedJson['avatar'].cast<int>()),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "avatar": avatar,
      "displayName": displayName,
      "middleName": middleName,
      "givenName": givenName,
      "identifier": identifier,
      "familyName": familyName,
    };
  }
}

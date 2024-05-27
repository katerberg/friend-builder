import 'package:friend_builder/contacts.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';

class EncodableContact extends Contact {
  @override
  // ignore: overridden_fields
  String displayName = "";
  String middleName = "";
  String givenName = "";
  String identifier = "";
  String familyName = "";
  Uint8List? avatar;

  EncodableContact({
    required this.displayName,
    required this.middleName,
    required this.givenName,
    required this.identifier,
    required this.familyName,
    this.avatar,
  });

  EncodableContact.fromContact(Contact contact) {
    displayName = contact.displayName;
    middleName = contact.name.middle;
    givenName = contact.name.first;
    identifier = contact.id;
    familyName = contact.name.last;
    avatar = contact.photo;
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
  Map<String, dynamic> toJson({withPhoto = true, withThumbnail = true}) {
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

import 'package:friend_builder/contacts.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';

class EncodableContact extends Contact {
  String displayName;
  String middleName;
  String givenName;
  String familyName;
  Uint8List avatar;
  DateTime birthday;

  EncodableContact({
    this.displayName,
    this.middleName,
    this.givenName,
    this.familyName,
    this.birthday,
    this.avatar,
  });

  EncodableContact.fromContact(Contact contact) {
    this.displayName = contact.displayName;
    this.middleName = contact.middleName;
    this.givenName = contact.givenName;
    this.familyName = contact.familyName;
    this.birthday = contact.birthday;
    this.avatar = contact.avatar;
  }

  CircleAvatar getAvatar(context, [double fontSize]) {
    return (avatar != null && avatar.isNotEmpty)
        ? CircleAvatar(
            backgroundImage: MemoryImage(avatar),
          )
        : CircleAvatar(
            child: Text(
              initials(),
              style: TextStyle(fontSize: fontSize ?? 14),
            ),
            backgroundColor: Theme.of(context).accentColor,
          );
  }

  String initials() {
    return ((this.givenName?.isNotEmpty == true ? this.givenName[0] : "") +
            (this.familyName?.isNotEmpty == true ? this.familyName[0] : ""))
        .toUpperCase();
  }

  factory EncodableContact.fromJson(Map<String, dynamic> parsedJson) {
    return new EncodableContact(
      displayName: parsedJson['displayName'] ?? "",
      middleName: parsedJson['middleName'] ?? "",
      givenName: parsedJson['givenName'] ?? "",
      familyName: parsedJson['familyName'] ?? "",
      avatar: parsedJson['avatar'] == null
          ? null
          : new Uint8List.fromList(parsedJson['avatar'].cast<int>()),
      birthday: parsedJson['birthday'] != null
          ? DateTime.parse(parsedJson['birthday'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "avatar": this.avatar,
      "displayName": this.displayName,
      "middleName": this.middleName,
      "givenName": this.givenName,
      "familyName": this.familyName,
      "birthday":
          this.birthday != null ? this.birthday.toIso8601String() : null,
    };
  }
}

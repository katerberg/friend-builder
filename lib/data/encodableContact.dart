import 'package:friend_builder/contacts.dart';

class EncodableContact {
  String displayName;
  String middleName;
  String givenName;
  String familyName;
  DateTime birthday;

  EncodableContact(
      {this.displayName,
      this.middleName,
      this.givenName,
      this.familyName,
      this.birthday});

  EncodableContact.fromContact(Contact contact) {
    this.displayName = contact.displayName;
    this.middleName = contact.middleName;
    this.givenName = contact.givenName;
    this.familyName = contact.familyName;
    this.birthday = contact.birthday;
  }

  String initials() {
    return ((this.givenName?.isNotEmpty == true ? this.givenName[0] : "") +
            (this.familyName?.isNotEmpty == true ? this.familyName[0] : ""))
        .toUpperCase();
  }

  factory EncodableContact.fromJson(Map<String, dynamic> parsedJson) {
    print('parsing json');
    return new EncodableContact(
      displayName: parsedJson['displayName'] ?? "",
      middleName: parsedJson['middleName'] ?? "",
      givenName: parsedJson['givenName'] ?? "",
      familyName: parsedJson['familyName'] ?? "",
      birthday: parsedJson['birthday'] != null
          ? DateTime.parse(parsedJson['birthday'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "displayName": this.displayName,
      "middleName": this.middleName,
      "givenName": this.givenName,
      "familyName": this.familyName,
      "birthday":
          this.birthday != null ? this.birthday.toIso8601String() : null,
    };
  }
}

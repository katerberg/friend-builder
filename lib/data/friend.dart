import 'package:uuid/uuid.dart';

class Friend {
  String contactIdentifier;

  Friend({
    this.contactIdentifier,
  });

  factory Friend.fromJson(Map<String, dynamic> parsedJson) {
    return new Friend(
      contactIdentifier: parsedJson['contactIdentifier'] ?? Uuid().v4(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "contactIdentifier": this.contactIdentifier,
    };
  }
}

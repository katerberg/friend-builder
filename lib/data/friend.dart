import 'package:uuid/uuid.dart';

class Friend {
  String contactIdentifier;
  String frequency;
  String notes;
  bool isContactable;

  Friend(
      {required this.contactIdentifier,
      required this.notes,
      required this.frequency,
      required this.isContactable});

  factory Friend.fromJson(Map<String, dynamic> parsedJson) {
    return Friend(
      contactIdentifier: parsedJson['contactIdentifier'] ?? const Uuid().v4(),
      notes: parsedJson['notes'] ?? '',
      frequency: parsedJson['frequency'] ?? 'Weekly',
      isContactable: parsedJson['isContactable'] ?? false,
    );
  }

  factory Friend.fromMap(Map<String, dynamic> parsedJson) {
    return Friend(
      contactIdentifier: parsedJson['contactIdentifier'] ?? const Uuid().v4(),
      notes: parsedJson['notes'] ?? '',
      frequency: parsedJson['frequency'] ?? 'Weekly',
      isContactable: parsedJson['isContactable'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "contactIdentifier": contactIdentifier,
      "notes": notes,
      "frequency": frequency,
      "isContactable": isContactable,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      "contactIdentifier": contactIdentifier,
      "notes": notes,
      "frequency": frequency,
      "isContactable": isContactable ? 1 : 0,
    };
  }
}

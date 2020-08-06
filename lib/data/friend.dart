import 'package:uuid/uuid.dart';

class Friend {
  String contactIdentifier;
  String frequency;
  String notes;

  Friend({
    this.contactIdentifier,
    this.notes,
    this.frequency,
  });

  factory Friend.fromJson(Map<String, dynamic> parsedJson) {
    return new Friend(
      contactIdentifier: parsedJson['contactIdentifier'] ?? Uuid().v4(),
      notes: parsedJson['notes'] ?? '',
      frequency: parsedJson['frequency'] ?? 'Weekly',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "contactIdentifier": this.contactIdentifier,
      "notes": this.notes,
      "frequency": this.frequency,
    };
  }
}

import 'package:uuid/uuid.dart';

class Friend {
  String contactIdentifier;
  String frequency;
  String notes;
  bool isContactable;

  Friend(
      {this.contactIdentifier, this.notes, this.frequency, this.isContactable});

  factory Friend.fromJson(Map<String, dynamic> parsedJson) {
    return new Friend(
      contactIdentifier: parsedJson['contactIdentifier'] ?? Uuid().v4(),
      notes: parsedJson['notes'] ?? '',
      frequency: parsedJson['frequency'] ?? 'Weekly',
      isContactable: parsedJson['isContactable'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "contactIdentifier": this.contactIdentifier,
      "notes": this.notes,
      "frequency": this.frequency,
      "isContactable": this.isContactable,
    };
  }
}

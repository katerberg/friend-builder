import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:friend_builder/data/frequency.dart';

class Friend {
  String contactIdentifier;
  Frequency frequency;
  String notes;
  bool isContactable;

  Friend(
      {required this.contactIdentifier,
      required this.notes,
      required this.frequency,
      required this.isContactable});

  factory Friend.fromMap(Map<String, dynamic> parsedJson) {
    Frequency freq;
    if (parsedJson['frequency'] is String) {
      String freqString = parsedJson['frequency'] ?? 'Weekly';
      try {
        final decoded = jsonDecode(freqString);
        if (decoded is Map<String, dynamic>) {
          freq = Frequency.fromJson(decoded);
        } else {
          freq = Frequency.fromString(freqString);
        }
      } catch (e) {
        freq = Frequency.fromString(freqString);
      }
    } else {
      freq = Frequency.fromType('Weekly');
    }

    return Friend(
      contactIdentifier: parsedJson['contactIdentifier'] ?? const Uuid().v4(),
      notes: parsedJson['notes'] ?? '',
      frequency: freq,
      isContactable: parsedJson['isContactable'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "contactIdentifier": contactIdentifier,
      "notes": notes,
      "frequency": frequency.toJson(),
      "isContactable": isContactable,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      "contactIdentifier": contactIdentifier,
      "notes": notes,
      "frequency": jsonEncode(frequency.toJson()),
      "isContactable": isContactable ? 1 : 0,
    };
  }
}

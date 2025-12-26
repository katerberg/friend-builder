import 'package:uuid/uuid.dart';

class SnoozeReminder {
  final String id;
  final String contactIdentifier;
  final DateTime snoozeUntil;

  SnoozeReminder({
    String? id,
    required this.contactIdentifier,
    required this.snoozeUntil,
  }) : id = id ?? const Uuid().v4();

  factory SnoozeReminder.fromMap(Map<String, dynamic> map) {
    return SnoozeReminder(
      id: map['id'] as String,
      contactIdentifier: map['contactIdentifier'] as String,
      snoozeUntil: DateTime.parse(map['snoozeUntil'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'contactIdentifier': contactIdentifier,
      'snoozeUntil': snoozeUntil.toIso8601String(),
    };
  }
}

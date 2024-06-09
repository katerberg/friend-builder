import 'package:friend_builder/data/encodable_contact.dart';
import 'package:friend_builder/contacts_permission.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class Hangout {
  List<EncodableContact> contacts = [];
  final String id;
  String notes = '';
  DateTime when = DateTime.now();

  Hangout(
      {String? id,
      required this.contacts,
      required this.notes,
      required this.when})
      : id = id ?? const Uuid().v4();

  String dateWithYear() => DateFormat.yMMMMd().format(when);
  String dateWithoutYear() => DateFormat.MMMMd().format(when);

  bool hasContact(Contact contact) {
    return contacts.any((element) => element.identifier == contact.id);
  }

  factory Hangout.fromJson(Map<String, dynamic> parsedJson) {
    return Hangout(
      id: parsedJson['id'] ?? const Uuid().v4(),
      contacts: (parsedJson['contacts'] as List)
          .map((c) => EncodableContact.fromJson(c))
          .toList(),
      notes: parsedJson['notes'] ?? parsedJson['where'] ?? "",
      when: DateTime.parse(parsedJson['when']),
    );
  }

  factory Hangout.fromMap(Map<String, dynamic> parsed) {
    return Hangout(
      id: parsed['id'] ?? const Uuid().v4(),
      contacts: [],
      notes: parsed['notes'] ?? "",
      when: DateTime.parse(parsed['whenOccurred']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "contacts": contacts,
      "notes": notes,
      "when": when.toIso8601String(),
    };
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "notes": notes,
      "when": when.toIso8601String(),
    };
  }
}

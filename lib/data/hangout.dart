import 'package:friend_builder/data/encodable_contact.dart';
import 'package:friend_builder/contacts_permission.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

bool parseIsAllDay(Object? value) => value == true || value == 1;

class Hangout {
  List<EncodableContact> contacts = [];
  final String id;
  String notes = '';
  DateTime when;
  bool isAllDay;

  Hangout(
      {String? id,
      required this.contacts,
      required this.notes,
      required DateTime when,
      this.isAllDay = false})
      : id = id ?? const Uuid().v4(),
        when = when.isUtc ? when.toLocal() : when;

  String dateWithYear() => DateFormat.yMMMMd().format(when);

  String dateTimeWithoutYear() {
    if (isAllDay) {
      return DateFormat.MMMMd().format(when);
    }
    return DateFormat.MMMMd().add_jm().format(when);
  }

  /// Hidden inspect copy: local and UTC representations of [when].
  String debugLocalAndUtc() {
    final formatter = DateFormat.yMMMMd().add_jms();
    return 'Local: ${formatter.format(when)}\nUTC: ${formatter.format(when.toUtc())}';
  }

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
      isAllDay: parseIsAllDay(parsedJson['isAllDay']),
    );
  }

  factory Hangout.fromMap(Map<String, dynamic> parsed) {
    return Hangout(
      id: parsed['id'] ?? const Uuid().v4(),
      contacts: [],
      notes: parsed['notes'] ?? "",
      when: DateTime.parse(parsed['whenOccurred']),
      isAllDay: parseIsAllDay(parsed['isAllDay']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "contacts": contacts,
      "notes": notes,
      "when": when.toIso8601String(),
      "isAllDay": isAllDay,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "notes": notes,
      "when": when.toIso8601String(),
      "isAllDay": isAllDay ? 1 : 0,
    };
  }
}

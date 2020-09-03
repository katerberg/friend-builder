import 'package:friend_builder/data/encodableContact.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class Hangout {
  List<EncodableContact> contacts = [];
  final String id;
  String notes = '';
  DateTime when = DateTime.now();

  Hangout({String id, this.contacts, this.notes, this.when})
      : this.id = id ?? Uuid().v4();

  String dateWithYear() => DateFormat.yMMMMd().format(this.when);
  String dateWithoutYear() => DateFormat.MMMMd().format(this.when);

  bool hasContact(Contact contact) {
    return this
        .contacts
        .any((element) => element.identifier == contact.identifier);
  }

  factory Hangout.fromJson(Map<String, dynamic> parsedJson) {
    return new Hangout(
      id: parsedJson['id'] ?? Uuid().v4(),
      contacts: (parsedJson['contacts'] as List)
          .map((c) => EncodableContact.fromJson(c))
          .toList(),
      notes: parsedJson['notes'] ?? parsedJson['where'] ?? "",
      when: DateTime.parse(parsedJson['when']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": this.id,
      "contacts": this.contacts,
      "notes": this.notes,
      "when": this.when.toIso8601String(),
    };
  }
}

import 'package:flutter_contacts/flutter_contacts.dart';

/// Digits (and optional leading +) suitable for a `tel:` URL.
String dialStringFromPhoneNumber(String number) {
  final buffer = StringBuffer();
  for (var index = 0; index < number.length; index++) {
    final character = number[index];
    if (character == '+' && buffer.isEmpty) {
      buffer.write(character);
    } else if (_isDigit(character)) {
      buffer.write(character);
    }
  }
  return buffer.toString();
}

bool _isDigit(String character) {
  final codeUnit = character.codeUnitAt(0);
  return codeUnit >= 0x30 && codeUnit <= 0x39;
}

String phoneLabelDisplayName(Phone phone) {
  if (phone.label == PhoneLabel.custom && phone.customLabel.isNotEmpty) {
    return phone.customLabel;
  }
  switch (phone.label) {
    case PhoneLabel.iPhone:
      return 'iPhone';
    case PhoneLabel.mobile:
      return 'mobile';
    case PhoneLabel.home:
      return 'home';
    case PhoneLabel.work:
      return 'work';
    case PhoneLabel.main:
      return 'main';
    case PhoneLabel.workMobile:
      return 'work mobile';
    case PhoneLabel.other:
      return 'other';
    default:
      return phone.label.name;
  }
}

List<Map<String, String>> carPlayPhonesFromContact(Contact contact) {
  final phones = <Map<String, String>>[];
  for (final phone in contact.phones) {
    final rawNumber =
        phone.normalizedNumber.isNotEmpty ? phone.normalizedNumber : phone.number;
    final dialString = dialStringFromPhoneNumber(rawNumber);
    if (dialString.isEmpty) {
      continue;
    }
    phones.add({
      'label': phoneLabelDisplayName(phone),
      'number': dialString,
    });
  }
  return phones;
}

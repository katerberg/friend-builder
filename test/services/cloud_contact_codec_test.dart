import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friend_builder/data/encodable_contact.dart';
import 'package:friend_builder/services/cloud_contact_codec.dart';

EncodableContact _contact(String id, String first, String last) =>
    EncodableContact(
      displayName: '$first $last',
      middleName: '',
      givenName: first,
      identifier: id,
      familyName: last,
    );

void main() {
  group('CloudContactCodec.encode', () {
    test('uploads only identifiers', () {
      final encoded = CloudContactCodec.encode([
        _contact('a', 'Ada', 'Lovelace'),
        _contact('b', 'Alan', 'Turing'),
      ]);

      expect(encoded, [
        {'identifier': 'a'},
        {'identifier': 'b'},
      ]);
    });
  });

  group('CloudContactCodec.decode', () {
    test('rebuilds names from the device contact', () {
      const device = Contact(
        id: 'a',
        displayName: 'Ada Lovelace',
        name: Name(first: 'Ada', last: 'Lovelace'),
      );

      final decoded =
          CloudContactCodec.decode({'identifier': 'a'}, {'a': device});

      expect(decoded.identifier, 'a');
      expect(decoded.displayName, 'Ada Lovelace');
      expect(decoded.givenName, 'Ada');
      expect(decoded.familyName, 'Lovelace');
    });

    test('falls back to names on legacy cloud entries', () {
      final decoded = CloudContactCodec.decode({
        'identifier': 'gone',
        'displayName': 'Old Name',
        'givenName': 'Old',
        'familyName': 'Name',
      }, {});

      expect(decoded.displayName, 'Old Name');
      expect(CloudContactCodec.needsNameBackfill(decoded), isFalse);
    });

    test('uses a placeholder when the contact is gone', () {
      final decoded = CloudContactCodec.decode({'identifier': 'gone'}, {});

      expect(decoded.identifier, 'gone');
      expect(decoded.displayName, unknownContactName);
      expect(CloudContactCodec.needsNameBackfill(decoded), isTrue);
    });
  });

  group('legacy scrubbing', () {
    test('detects and strips personal fields', () {
      final legacy = [
        {'identifier': 'a', 'displayName': 'Ada', 'givenName': 'Ada'},
        {'identifier': 'b'},
      ];

      expect(CloudContactCodec.containsPersonalFields(legacy), isTrue);
      final stripped = CloudContactCodec.stripPersonalFields(legacy);
      expect(stripped, [
        {'identifier': 'a'},
        {'identifier': 'b'},
      ]);
      expect(CloudContactCodec.containsPersonalFields(stripped), isFalse);
    });
  });

  group('needsNameBackfill', () {
    test('is false for a named contact', () {
      expect(
        CloudContactCodec.needsNameBackfill(_contact('a', 'Ada', 'Lovelace')),
        isFalse,
      );
    });

    test('is true for an empty name', () {
      expect(
        CloudContactCodec.needsNameBackfill(EncodableContact(
          displayName: '',
          middleName: '',
          givenName: '',
          identifier: 'a',
          familyName: '',
        )),
        isTrue,
      );
    });
  });
}

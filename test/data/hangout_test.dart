import 'package:flutter_test/flutter_test.dart';
import 'package:friend_builder/data/hangout.dart';
import 'package:intl/intl.dart';

void main() {
  group('Hangout when', () {
    test('preserves local evening time instead of forcing noon', () {
      final evening = DateTime(2024, 8, 22, 18, 45, 30);
      final hangout = Hangout(contacts: [], notes: '', when: evening);

      expect(hangout.when, evening);
      expect(hangout.when.isUtc, isFalse);
    });

    test('converts UTC input to local', () {
      final utcEvening = DateTime.utc(2024, 8, 22, 18, 45);
      final hangout = Hangout(contacts: [], notes: '', when: utcEvening);

      expect(hangout.when.isUtc, isFalse);
      expect(hangout.when, utcEvening.toLocal());
    });

    test('toMap serializes the stored instant without noon normalization', () {
      final evening = DateTime(2024, 8, 22, 18, 45, 30);
      final hangout = Hangout(
        id: 'hangout-1',
        contacts: [],
        notes: 'notes',
        when: evening,
      );

      expect(hangout.toMap()['when'], evening.toIso8601String());
    });

    test('fromMap restores the stored instant', () {
      final evening = DateTime(2024, 8, 22, 18, 45, 30);
      final hangout = Hangout.fromMap({
        'id': 'hangout-1',
        'notes': 'notes',
        'whenOccurred': evening.toIso8601String(),
      });

      expect(hangout.when, evening);
    });

    test('toJson and fromJson round-trip preserve the instant', () {
      final evening = DateTime(2024, 8, 22, 18, 45, 30);
      final original = Hangout(
        id: 'hangout-1',
        contacts: [],
        notes: 'coffee',
        when: evening,
      );

      final restored = Hangout.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.notes, original.notes);
      expect(restored.when, evening);
    });

    test('dateTimeWithoutYear includes month, day, and time', () {
      final evening = DateTime(2024, 8, 22, 18, 45);
      final hangout = Hangout(contacts: [], notes: '', when: evening);
      final expected = DateFormat.MMMMd().add_jm().format(evening);

      expect(hangout.dateTimeWithoutYear(), expected);
    });

    test('debugLocalAndUtc includes local and UTC lines', () {
      final evening = DateTime(2024, 8, 22, 18, 45, 30);
      final hangout = Hangout(contacts: [], notes: '', when: evening);
      final debugText = hangout.debugLocalAndUtc();
      final formatter = DateFormat.yMMMMd().add_jms();

      expect(debugText, contains('Local: ${formatter.format(evening)}'));
      expect(debugText, contains('UTC: ${formatter.format(evening.toUtc())}'));
    });
  });
}

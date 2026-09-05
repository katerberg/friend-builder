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

    test('defaults isAllDay to false', () {
      final hangout = Hangout(
        contacts: [],
        notes: '',
        when: DateTime(2024, 8, 22, 18, 45),
      );

      expect(hangout.isAllDay, isFalse);
    });

    test('toMap serializes the stored instant and isAllDay', () {
      final evening = DateTime(2024, 8, 22, 18, 45, 30);
      final hangout = Hangout(
        id: 'hangout-1',
        contacts: [],
        notes: 'notes',
        when: evening,
        isAllDay: true,
      );

      expect(hangout.toMap()['when'], evening.toIso8601String());
      expect(hangout.toMap()['isAllDay'], 1);
    });

    test('fromMap restores the stored instant and isAllDay', () {
      final evening = DateTime(2024, 8, 22, 18, 45, 30);
      final hangout = Hangout.fromMap({
        'id': 'hangout-1',
        'notes': 'notes',
        'whenOccurred': evening.toIso8601String(),
        'isAllDay': 1,
      });

      expect(hangout.when, evening);
      expect(hangout.isAllDay, isTrue);
    });

    test('fromMap treats missing isAllDay as false', () {
      final hangout = Hangout.fromMap({
        'id': 'hangout-1',
        'notes': 'notes',
        'whenOccurred': DateTime(2024, 8, 22).toIso8601String(),
      });

      expect(hangout.isAllDay, isFalse);
    });

    test('toJson and fromJson round-trip preserve the instant and isAllDay', () {
      final evening = DateTime(2024, 8, 22, 18, 45, 30);
      final original = Hangout(
        id: 'hangout-1',
        contacts: [],
        notes: 'coffee',
        when: evening,
        isAllDay: true,
      );

      final restored = Hangout.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.notes, original.notes);
      expect(restored.when, evening);
      expect(restored.isAllDay, isTrue);
    });

    test('dateTimeWithoutYear includes month, day, and time when timed', () {
      final evening = DateTime(2024, 8, 22, 18, 45);
      final hangout = Hangout(contacts: [], notes: '', when: evening);
      final expected = DateFormat.MMMMd().add_jm().format(evening);

      expect(hangout.dateTimeWithoutYear(), expected);
    });

    test('dateTimeWithoutYear omits time when isAllDay', () {
      final midnight = DateTime(2024, 8, 22);
      final hangout = Hangout(
        contacts: [],
        notes: '',
        when: midnight,
        isAllDay: true,
      );
      final expected = DateFormat.MMMMd().format(midnight);

      expect(hangout.dateTimeWithoutYear(), expected);
      expect(hangout.dateTimeWithoutYear(), isNot(contains(':')));
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

import 'package:flutter_test/flutter_test.dart';
import 'package:friend_builder/data/frequency.dart';
import 'package:friend_builder/utils/due_friend_urgency.dart';

void main() {
  group('dueFriendUrgencyLabel', () {
    test('returns Never seen when there is no hangout', () {
      expect(
        dueFriendUrgencyLabel(
          latestHangoutWhen: null,
          frequency: Frequency.fromType('Weekly'),
        ),
        'Never seen!',
      );
    });

    test('returns days to go when still within frequency window', () {
      final latestHangoutWhen =
          DateTime.now().subtract(const Duration(days: 2));
      expect(
        dueFriendUrgencyLabel(
          latestHangoutWhen: latestHangoutWhen,
          frequency: Frequency.fromType('Weekly'),
        ),
        '5 days to go',
      );
    });

    test('returns days late when overdue', () {
      final latestHangoutWhen =
          DateTime.now().subtract(const Duration(days: 10));
      expect(
        dueFriendUrgencyLabel(
          latestHangoutWhen: latestHangoutWhen,
          frequency: Frequency.fromType('Weekly'),
        ),
        '3 days late',
      );
    });
  });
}

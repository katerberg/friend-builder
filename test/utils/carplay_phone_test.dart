import 'package:flutter_test/flutter_test.dart';
import 'package:friend_builder/utils/carplay_phone.dart';

void main() {
  group('dialStringFromPhoneNumber', () {
    test('keeps digits and leading plus', () {
      expect(dialStringFromPhoneNumber('+1 (555) 123-4567'), '+15551234567');
    });

    test('strips letters and punctuation without a plus', () {
      expect(dialStringFromPhoneNumber('(555) 123-4567'), '5551234567');
    });

    test('returns empty for non-numeric input', () {
      expect(dialStringFromPhoneNumber('n/a'), '');
    });
  });
}

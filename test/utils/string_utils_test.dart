import 'package:friend_builder/utils/string_utils.dart';
import 'package:test/test.dart';

void main() {
  group('getComparison', () {
    test('gives no value to single character exact matches', () {
      var comparison = StringUtils.getComparison('Alex Svitnev', 'N');

      expect(comparison, 0.0);
    });

    test('finds exact matches of two characters', () {
      var comparison = StringUtils.getComparison('Alex Svitnev', 'Ne');

      expect(comparison, greaterThanOrEqualTo(0.1));
    });

    test('matches exact match', () {
      var comparison =
          StringUtils.getComparison('Alex Svitnev', 'Alex Svitnev');

      expect(comparison, greaterThanOrEqualTo(0.9));
    });
  });
}

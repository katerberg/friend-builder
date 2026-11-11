import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friend_builder/theme_notifier.dart';

void main() {
  group('ThemeNotifier.iconNameFor', () {
    test('maps each palette color to its own icon', () {
      final names = ThemeNotifier.colorOptions
          .map((option) => ThemeNotifier.iconNameFor(option.color))
          .toList();
      expect(names, everyElement(isNotNull));
      expect(names.toSet().length, ThemeNotifier.colorOptions.length);
    });

    test('labels match their colors', () {
      final byName = {
        for (final option in ThemeNotifier.colorOptions) option.name: option,
      };
      expect(byName['Black']!.color, const Color(0xFF2C2C2C));
      expect(byName['Coral']!.color, const Color(0xFFD88876));
    });

    test('default and unknown colors use the default icon', () {
      expect(ThemeNotifier.iconNameFor(ThemeNotifier.defaultColor), isNull);
      expect(ThemeNotifier.iconNameFor(const Color(0xFF123456)), isNull);
    });
  });
}

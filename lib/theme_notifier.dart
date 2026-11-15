import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/app_icon_service.dart';

const String themeColorKey = 'theme_color';

/// A selectable theme color and the app icon variant that matches it.
class ThemeColorOption {
  final String name;
  final Color color;

  /// Native alternate icon name; null means the default icon.
  final String? iconName;

  const ThemeColorOption(this.name, this.color, this.iconName);
}

class ThemeNotifier extends ChangeNotifier {
  static const Color defaultColor = Color(0xFF2898D5);

  static const List<ThemeColorOption> colorOptions = [
    ThemeColorOption('Soft Sky Blue', Color(0xFF7EB8DA), 'Sky'),
    ThemeColorOption('Mint Green', Color(0xFF6FC9A3), 'Mint'),
    ThemeColorOption('Blush Pink', Color(0xFFE67B9C), 'Pink'),
    ThemeColorOption('Peach', Color(0xFFE89668), 'Peach'),
    ThemeColorOption('Lavender', Color(0xFFAE7FD8), 'Lavender'),
    ThemeColorOption('Golden Yellow', Color(0xFFE6BD52), 'Yellow'),
    ThemeColorOption('Coral', Color(0xFFD88876), 'Coral'),
    ThemeColorOption('Black', Color(0xFF2C2C2C), 'Black'),
  ];

  /// The icon variant for [color], or null for the default icon.
  static String? iconNameFor(Color color) {
    for (final option in colorOptions) {
      if (option.color.toARGB32() == color.toARGB32()) {
        return option.iconName;
      }
    }
    return null;
  }

  Color _themeColor = defaultColor;

  Color get themeColor => _themeColor;

  ThemeNotifier() {
    _loadThemeColor();
  }

  Future<void> _loadThemeColor() async {
    final preferences = await SharedPreferences.getInstance();
    final colorValue = preferences.getInt(themeColorKey);
    if (colorValue != null) {
      _themeColor = Color(colorValue);
      notifyListeners();
    }
  }

  Future<void> setThemeColor(Color color) async {
    if (_themeColor == color) return;

    _themeColor = color;
    notifyListeners();

    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(themeColorKey, color.toARGB32());
    await AppIconService.setIcon(iconNameFor(color));
  }

  static Future<Color> getSavedColor() async {
    final preferences = await SharedPreferences.getInstance();
    final colorValue = preferences.getInt(themeColorKey);
    return colorValue != null ? Color(colorValue) : defaultColor;
  }
}

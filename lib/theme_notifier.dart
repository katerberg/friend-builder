import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String themeColorKey = 'theme_color';

class ThemeNotifier extends ChangeNotifier {
  static const Color defaultColor = Color(0xFF2898D5);

  static const List<Color> pastelColors = [
    Color(0xFF7EB8DA), // Soft Sky Blue
    Color(0xFF6FC9A3), // Mint Green
    Color(0xFFE67B9C), // Blush Pink
    Color(0xFFE89668), // Peach
    Color(0xFFAE7FD8), // Lavender
    Color(0xFFE6BD52), // Golden Yellow
    Color(0xFFD88876), // Coral
    Color(0xFF2C2C2C), // Black
  ];

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
  }

  static Future<Color> getSavedColor() async {
    final preferences = await SharedPreferences.getInstance();
    final colorValue = preferences.getInt(themeColorKey);
    return colorValue != null ? Color(colorValue) : defaultColor;
  }
}

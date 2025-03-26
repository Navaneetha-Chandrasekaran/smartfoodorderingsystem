import 'package:flutter/material.dart';
import 'light_mode.dart';
import 'dark_mode.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;  // Default mode

  bool get isDarkMode => _isDarkMode;
  ThemeData get themeData => _isDarkMode ? darkMode : lightMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();  // ✅ Ensure rebuild is triggered
  }
}

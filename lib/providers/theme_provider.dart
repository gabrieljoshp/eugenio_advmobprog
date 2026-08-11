import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDark = false;
  bool get isDark => _isDark;

  ThemeData get lightTheme => ThemeData.light();
  ThemeData get darkTheme => ThemeData.dark();

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }
}

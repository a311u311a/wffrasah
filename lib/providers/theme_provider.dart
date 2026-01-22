import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_theme.dart';
import '../constants.dart';

class ThemeProvider with ChangeNotifier {
  static const String _darkModeKey = 'isDarkMode';

  late ThemeData _selectedTheme;
  bool _isDarkMode = false;
  
  // الاحتفاظ باللون الأساسي من Constants
  Color get _primaryColor => Constants.primaryColor;

  ThemeProvider() {
    _selectedTheme = AppThemes.lightTheme;
    _loadFromPrefs();
  }

  ThemeData get getTheme => _selectedTheme;
  bool get getIsDarkMode => _isDarkMode;
  Color get primaryColor => _primaryColor;

  // تحميل الإعدادات من SharedPreferences
  Future<void> _loadFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_darkModeKey) ?? false;
    _updateTheme();
  }

  // تغيير وضع الليل/النهار
  void toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    _updateTheme();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, _isDarkMode);
  }

  // تحديث الثيم بناءً على الخيارات الحالية
  void _updateTheme() {
    _selectedTheme = _isDarkMode
        ? AppThemes.generateTheme(Brightness.dark, _primaryColor)
        : AppThemes.generateTheme(Brightness.light, _primaryColor);
    notifyListeners();
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts
import 'constants.dart';

class AppThemes {
  // دالة لتوليد الثيم بناءً على السطوع واللون الأساسي اختيارياً
  static ThemeData generateTheme(Brightness brightness, Color primaryColor) {
    bool isDark = brightness == Brightness.dark;

    return ThemeData(
      brightness: brightness,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: isDark ? Colors.black : Colors.white,
      // fontFamily: 'Tajawal', // Removed manual font family
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? Colors.black : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
      textTheme: GoogleFonts.tajawalTextTheme(
        TextTheme(
          bodyLarge: TextStyle(color: isDark ? Colors.white : Colors.black),
          bodyMedium:
              TextStyle(color: isDark ? Colors.white70 : Colors.black54),
        ),
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: brightness,
      ),
    );
  }

  // الثيمات الافتراضية القديمة (للتوافق)
  static ThemeData lightTheme =
      generateTheme(Brightness.light, Constants.primaryColor);
  static ThemeData darkTheme =
      generateTheme(Brightness.dark, Constants.primaryColor);
}

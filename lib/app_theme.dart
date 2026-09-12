import 'package:flutter/material.dart';
import 'constants.dart';

class AppThemes {
  // دالة لتوليد الثيم بناءً على السطوع واللون الأساسي اختيارياً
  static ThemeData generateTheme(Brightness brightness, Color primaryColor) {
    final bool isDark = brightness == Brightness.dark;
    final Color background =
        isDark ? Constants.darkBackgroundColor : Constants.backgroundColor;
    final Color surface =
        isDark ? Constants.darkSurfaceColor : Constants.surfaceColor;
    final Color textColor = isDark ? Colors.white : Constants.textColor;
    final Color secondaryTextColor =
        isDark ? const Color(0xFFD2D0DF) : Constants.secondaryTextColor;
    final Color borderColor =
        isDark ? const Color(0xFF343348) : Constants.borderColor;
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: brightness,
      primary: primaryColor,
      secondary: Constants.accentColor,
      surface: surface,
      error: Constants.errorColor,
    );
    final TextTheme baseTextTheme =
        _buildTextTheme(textColor, secondaryTextColor);

    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      primaryColor: primaryColor,
      fontFamily: Constants.primaryFontFamily,
      scaffoldBackgroundColor: background,
      colorScheme: colorScheme,
      textTheme: baseTextTheme,
      primaryTextTheme: baseTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: baseTextTheme.titleLarge?.copyWith(
          fontFamily: Constants.displayFontFamily,
          fontWeight: FontWeight.w800,
          color: primaryColor,
        ),
        iconTheme: IconThemeData(color: textColor, size: 24),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.24 : 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Constants.radiusLarge),
          side: BorderSide(color: borderColor, width: 1),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor:
            isDark ? const Color(0xFF262538) : Constants.primarySoftColor,
        selectedColor: primaryColor,
        disabledColor:
            isDark ? const Color(0xFF222231) : const Color(0xFFF2F1F7),
        labelStyle: baseTextTheme.labelLarge?.copyWith(
          color: primaryColor,
          fontWeight: FontWeight.w700,
        ),
        secondaryLabelStyle: baseTextTheme.labelLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
        side: BorderSide(color: borderColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Constants.radiusMedium),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? const Color(0xFF2D2C3E) : Constants.mutedBorderColor,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Constants.spacingL,
          vertical: Constants.spacingM,
        ),
        hintStyle: baseTextTheme.bodyMedium?.copyWith(
          color: Constants.disabledTextColor,
          fontWeight: FontWeight.w600,
        ),
        labelStyle: baseTextTheme.bodyMedium?.copyWith(
          color: secondaryTextColor,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Constants.radiusMedium),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Constants.radiusMedium),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Constants.radiusMedium),
          borderSide: BorderSide(color: primaryColor, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Constants.radiusMedium),
          borderSide: const BorderSide(color: Constants.errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Constants.radiusMedium),
          borderSide: const BorderSide(color: Constants.errorColor, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize:
              const Size(Constants.buttonHeight, Constants.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: Constants.spacingXL,
            vertical: Constants.spacingM,
          ),
          textStyle: baseTextTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Constants.radiusButton),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          minimumSize:
              const Size(Constants.buttonHeight, Constants.buttonHeight),
          side: BorderSide(color: borderColor, width: 1.2),
          padding: const EdgeInsets.symmetric(
            horizontal: Constants.spacingXL,
            vertical: Constants.spacingM,
          ),
          textStyle: baseTextTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Constants.radiusButton),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          minimumSize: const Size(44, 44),
          textStyle: baseTextTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: primaryColor,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withValues(alpha: 0.72),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? const Color(0xFF272637) : Constants.textColor,
        contentTextStyle: baseTextTheme.bodyMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Constants.radiusMedium),
        ),
      ),
    );
  }

  // الثيمات الافتراضية القديمة (للتوافق)
  static ThemeData lightTheme =
      generateTheme(Brightness.light, Constants.primaryColor);
  static ThemeData darkTheme =
      generateTheme(Brightness.dark, Constants.primaryColor);

  static TextTheme _buildTextTheme(Color textColor, Color secondaryTextColor) {
    const String fontFamily = Constants.primaryFontFamily;

    TextStyle style({
      required double size,
      FontWeight weight = FontWeight.w500,
      Color? color,
      double height = 1.35,
    }) {
      return TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: const [Constants.displayFontFamily],
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: 0,
        color: color ?? textColor,
      );
    }

    return TextTheme(
      displayLarge: style(
        size: 34,
        weight: FontWeight.w800,
        height: 1.2,
      ).copyWith(fontFamily: Constants.displayFontFamily),
      displayMedium: style(
        size: 30,
        weight: FontWeight.w800,
        height: 1.2,
      ).copyWith(fontFamily: Constants.displayFontFamily),
      displaySmall: style(
        size: 26,
        weight: FontWeight.w800,
        height: 1.25,
      ).copyWith(fontFamily: Constants.displayFontFamily),
      headlineLarge: style(
        size: 24,
        weight: FontWeight.w800,
        height: 1.25,
      ).copyWith(fontFamily: Constants.displayFontFamily),
      headlineMedium: style(
        size: 22,
        weight: FontWeight.w800,
        height: 1.28,
      ).copyWith(fontFamily: Constants.displayFontFamily),
      headlineSmall: style(
        size: 20,
        weight: FontWeight.w800,
        height: 1.3,
      ).copyWith(fontFamily: Constants.displayFontFamily),
      titleLarge: style(
        size: 20,
        weight: FontWeight.w800,
        height: 1.3,
      ).copyWith(fontFamily: Constants.displayFontFamily),
      titleMedium: style(size: 17, weight: FontWeight.w700, height: 1.35),
      titleSmall: style(size: 15, weight: FontWeight.w700, height: 1.35),
      bodyLarge: style(size: 16, height: 1.55),
      bodyMedium: style(size: 14, color: secondaryTextColor, height: 1.5),
      bodySmall: style(size: 12, color: secondaryTextColor, height: 1.45),
      labelLarge: style(size: 15, weight: FontWeight.w800, height: 1.25),
      labelMedium: style(size: 13, weight: FontWeight.w700, height: 1.25),
      labelSmall: style(size: 11, weight: FontWeight.w700, height: 1.25),
    );
  }
}

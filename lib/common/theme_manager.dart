import 'package:flutter/material.dart';

/// Legacy per-field palette kept for FullscreenClockPage & FloatingClockService
/// which render outside the normal Theme tree.
class AppThemeData {
  final String name;
  final Brightness brightness;
  final Color bgColor;
  final Color cardColor;
  final Color primaryColor;
  final Color accentColor;
  final Color textColor;
  final Color subTextColor;
  final Color dividerColor;

  const AppThemeData({
    required this.name,
    required this.brightness,
    required this.bgColor,
    required this.cardColor,
    required this.primaryColor,
    required this.accentColor,
    required this.textColor,
    required this.subTextColor,
    required this.dividerColor,
  });

  /// Generate a full Material 3 ThemeData from this palette.
  ThemeData get themeData {
    final cs = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: brightness,
      surface: bgColor,
    ).copyWith(
      primary: primaryColor,
      secondary: accentColor,
      onSurface: textColor,
      surfaceContainerHighest: cardColor,
      outline: dividerColor,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: cs,
      scaffoldBackgroundColor: bgColor,
      cardColor: cardColor,
      dividerColor: dividerColor,
      appBarTheme: AppBarTheme(
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: primaryColor.withValues(alpha: 0.18),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primaryColor);
          }
          return IconThemeData(color: subTextColor);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: primaryColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            );
          }
          return TextStyle(color: subTextColor, fontSize: 11);
        }),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: dividerColor),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryColor;
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor.withValues(alpha: 0.4);
          }
          return null;
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryColor,
        thumbColor: primaryColor,
        inactiveTrackColor: primaryColor.withValues(alpha: 0.2),
        overlayColor: primaryColor.withValues(alpha: 0.12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: brightness == Brightness.dark ? Colors.black : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardColor,
        contentTextStyle: TextStyle(color: textColor),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: DividerThemeData(color: dividerColor, space: 1, thickness: 1),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryColor;
          return subTextColor;
        }),
      ),
    );
  }
}

class ThemeManager {
  static const AppThemeData lightTheme = AppThemeData(
    name: '极简白',
    brightness: Brightness.light,
    bgColor: Color(0xFFF8FAFC),
    cardColor: Colors.white,
    primaryColor: Color(0xFF4F46E5),
    accentColor: Color(0xFF0EA5E9),
    textColor: Color(0xFF0F172A),
    subTextColor: Color(0xFF64748B),
    dividerColor: Color(0xFFE2E8F0),
  );

  /// Single active theme — always light.
  static AppThemeData getTheme([int index = 0]) => lightTheme;
}

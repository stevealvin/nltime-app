import 'package:flutter/material.dart';

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
}

class ThemeManager {
  static const List<AppThemeData> themes = [
    AppThemeData(
      name: 'OLED 深邃暗黑',
      brightness: Brightness.dark,
      bgColor: Color(0xFF090D16),
      cardColor: Color(0xFF131A2A),
      primaryColor: Color(0xFF00E5FF),
      accentColor: Color(0xFF7C4DFF),
      textColor: Colors.white,
      subTextColor: Color(0xFF94A3B8),
      dividerColor: Color(0xFF1E293B),
    ),
    AppThemeData(
      name: '赛博霓虹',
      brightness: Brightness.dark,
      bgColor: Color(0xFF0D0B18),
      cardColor: Color(0xFF1B1633),
      primaryColor: Color(0xFFFF2A85),
      accentColor: Color(0xFF00F5D4),
      textColor: Colors.white,
      subTextColor: Color(0xFFA78BFA),
      dividerColor: Color(0xFF2E2454),
    ),
    AppThemeData(
      name: '极简工作室 (浅色)',
      brightness: Brightness.light,
      bgColor: Color(0xFFF8FAFC),
      cardColor: Colors.white,
      primaryColor: Color(0xFF4F46E5),
      accentColor: Color(0xFF0EA5E9),
      textColor: Color(0xFF0F172A),
      subTextColor: Color(0xFF64748B),
      dividerColor: Color(0xFFE2E8F0),
    ),
    AppThemeData(
      name: '翡翠科技',
      brightness: Brightness.dark,
      bgColor: Color(0xFF081410),
      cardColor: Color(0xFF102820),
      primaryColor: Color(0xFF00E676),
      accentColor: Color(0xFF1DE9B6),
      textColor: Colors.white,
      subTextColor: Color(0xFF6EE7B7),
      dividerColor: Color(0xFF1B382D),
    ),
  ];

  static AppThemeData getTheme(int index) {
    if (index < 0 || index >= themes.length) return themes[0];
    return themes[index];
  }
}

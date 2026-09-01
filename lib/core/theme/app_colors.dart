import 'package:material_ui/material_ui.dart';

/// OmniFlow 统一调色板与语义颜色规范
class AppColors {
  AppColors._();

  // 品牌核心色 (Teal & Emerald 科技绿)
  static const Color primary = Color(0xFF0D9488); // Teal 600
  static const Color primaryLight = Color(0xFF14B8A6); // Teal 500
  static const Color primaryDark = Color(0xFF0F766E); // Teal 700
  static const Color primaryGlow = Color(0xFF2DD4BF); // Teal 400

  // 辅助色 (Indigo & Sky 算力与连接)
  static const Color accentIndigo = Color(0xFF6366F1); // Indigo 500
  static const Color accentSky = Color(0xFF0EA5E9); // Sky 500
  static const Color accentPurple = Color(0xFFA855F7); // Purple 500

  // 状态语义色
  static const Color success = Color(0xFF10B981); // Emerald 500 (>50% 额度 / 健康)
  static const Color warning = Color(0xFFF59E0B); // Amber 500 (15%~50% 警告)
  static const Color danger = Color(0xFFF43F5E); // Rose 500 (<=15% 危险 / 异常)
  static const Color info = Color(0xFF3B82F6); // Blue 500

  // 浅色模式背景与面板
  static const Color lightBg = Color(0xFFF8FAFC); // Slate 50
  static const Color lightSurface = Colors.white;
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardBorder = Color(0xFFE2E8F0); // Slate 200
  static const Color lightTextPrimary = Color(0xFF0F172A); // Slate 900
  static const Color lightTextSecondary = Color(0xFF64748B); // Slate 500
  static const Color lightTextTertiary = Color(0xFF94A3B8); // Slate 400

  // 深色模式背景与面板 (深空黑与微蓝底蕴)
  static const Color darkBg = Color(0xFF0A0D14); // Very dark slate
  static const Color darkSurface = Color(0xFF111827); // Gray 900
  static const Color darkCard = Color(0xFF151C2C);
  static const Color darkCardBorder = Color(0xFF1E293B); // Slate 800
  static const Color darkTextPrimary = Color(0xFFF8FAFC); // Slate 50
  static const Color darkTextSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color darkTextTertiary = Color(0xFF64748B); // Slate 500

  /// 根据额度百分比获取语义颜色
  static Color getQuotaColor(double percentage) {
    if (percentage > 50) return success;
    if (percentage > 15) return warning;
    return danger;
  }

  /// 获取 Provider 专属品牌色
  static Color getProviderColor(String provider) {
    switch (provider.toLowerCase()) {
      case 'google-antigravity':
      case 'google-aistudio':
        return accentIndigo;
      case 'openai-codex':
      case 'openai-compatible':
        return primary;
      default:
        return accentPurple;
    }
  }
}

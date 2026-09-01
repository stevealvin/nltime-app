import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/app_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_container.dart';
import '../../../shared/views/app_webview_page.dart';
import '../../clock/services/app_service.dart';

/// Apple 极简分组风格设置页面 (Inset Grouped Architecture)
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final packageInfo = AppService.packageInfo;
  late TextEditingController _baseUrlController;
  bool _isTestingPing = false;
  int? _pingResultMs;
  String? _pingError;

  @override
  void initState() {
    super.initState();
    _baseUrlController = TextEditingController(text: AppStorage.baseUrl);
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    super.dispose();
  }

  Future<void> _handleTestConnection() async {
    final url = _baseUrlController.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _isTestingPing = true;
      _pingResultMs = null;
      _pingError = null;
    });

    HapticFeedback.lightImpact();

    try {
      final latency = await ApiClient.ping(url);
      await AppStorage.setBaseUrl(url);
      setState(() {
        _pingResultMs = latency;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已连通 OmniFlow 服务端 ($latency ms) 并保存配置'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _pingError = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('连接失败: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isTestingPing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('系统与偏好设置'),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // 1. 服务端连接设置分组
          _buildSectionHeader('服务端连接', isDark),
          _buildServerGroup(context, isDark),
          const SizedBox(height: 16),

          // 2. 外观主题分段滑块 (永不换行)
          _buildSectionHeader('外观主题', isDark),
          _buildThemeSegmentGroup(context, isDark),
          const SizedBox(height: 16),

          // 3. 关于应用
          _buildSectionHeader('关于', isDark),
          _buildAboutGroup(context, isDark),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// 分组标题
  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  /// 1. 服务端配置分组
  Widget _buildServerGroup(BuildContext context, bool isDark) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.globe, size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'API 接口地址',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
              ),
              if (_pingResultMs != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$_pingResultMs ms',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _baseUrlController,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: '如: https://om.nle.lol',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _isTestingPing ? null : _handleTestConnection,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isTestingPing
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('测速保存', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          if (_pingError != null) ...[
            const SizedBox(height: 8),
            Text(
              '连接失败: $_pingError',
              style: const TextStyle(fontSize: 11, color: AppColors.danger),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  /// 2. 主题外观切换 (Apple 风格平滑分段滑块，永不折行)
  Widget _buildThemeSegmentGroup(BuildContext context, bool isDark) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppStorage.themeModeNotifier,
      builder: (context, currentMode, _) {
        return GlassContainer(
          padding: const EdgeInsets.all(6),
          borderRadius: 16,
          child: Row(
            children: [
              _buildSegmentPill(
                context,
                title: '跟随系统',
                icon: LucideIcons.smartphone,
                isSelected: currentMode == ThemeMode.system,
                isDark: isDark,
                onTap: () => AppStorage.setThemeMode(ThemeMode.system),
              ),
              _buildSegmentPill(
                context,
                title: '极简浅色',
                icon: LucideIcons.sun,
                isSelected: currentMode == ThemeMode.light,
                isDark: isDark,
                onTap: () => AppStorage.setThemeMode(ThemeMode.light),
              ),
              _buildSegmentPill(
                context,
                title: '深空深色',
                icon: LucideIcons.moon,
                isSelected: currentMode == ThemeMode.dark,
                isDark: isDark,
                onTap: () => AppStorage.setThemeMode(ThemeMode.dark),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSegmentPill(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextSecondary),
              ),
              const SizedBox(width: 5),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                      : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextSecondary),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 3. 关于应用分组
  Widget _buildAboutGroup(BuildContext context, bool isDark) {
    return GlassContainer(
      padding: EdgeInsets.zero,
      borderRadius: 18,
      child: Column(
        children: [
          ListTile(
            dense: true,
            leading: const Icon(LucideIcons.sparkles, size: 16, color: AppColors.primary),
            title: const Text('应用全称', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            trailing: Text(
              '星环流动 OmniFlow',
              style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            ),
          ),
          Divider(height: 1, thickness: 0.5, color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
          ListTile(
            dense: true,
            leading: const Icon(LucideIcons.info, size: 16, color: AppColors.accentSky),
            title: const Text('版本号', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            trailing: Text(
              'v${packageInfo.version}+${packageInfo.buildNumber}',
              style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            ),
          ),
          Divider(height: 1, thickness: 0.5, color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
          ListTile(
            dense: true,
            leading: const Icon(LucideIcons.externalLink, size: 16, color: AppColors.accentIndigo),
            title: const Text('官方网站', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            trailing: const Icon(LucideIcons.chevronRight, size: 14),
            onTap: () => AppWebViewPage.open(context, url: 'https://om.nle.lol', title: '星环流动 OmniFlow'),
          ),
        ],
      ),
    );
  }
}

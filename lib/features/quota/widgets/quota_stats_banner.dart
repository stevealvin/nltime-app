import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_container.dart';
import '../models/quota_model.dart';

/// 算力配额统计概览横幅 (Apple Glassmorphism Banner)
class QuotaStatsBanner extends StatelessWidget {
  final List<ApiKeyConfig> keys;
  final VoidCallback? onProbeAll;

  const QuotaStatsBanner({
    super.key,
    required this.keys,
    this.onProbeAll,
  });

  @override
  Widget build(BuildContext context) {
    final total = keys.length;
    final tokenPlaneCount = keys.where((k) => k.type == 'token-plane').length;
    final apiKeyCount = keys.where((k) => k.type == 'api-key').length;
    final healthyCount = keys.where((k) => k.status == 'active').length;

    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: 22,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                context,
                label: '全部资产',
                value: total.toString(),
                icon: LucideIcons.layers,
                iconColor: AppColors.primary,
              ),
              _buildDivider(context),
              _buildStatItem(
                context,
                label: 'TokenPlane',
                value: tokenPlaneCount.toString(),
                icon: LucideIcons.sparkles,
                iconColor: AppColors.accentIndigo,
              ),
              _buildDivider(context),
              _buildStatItem(
                context,
                label: 'API Key',
                value: apiKeyCount.toString(),
                icon: LucideIcons.key,
                iconColor: AppColors.accentSky,
              ),
              _buildDivider(context),
              _buildStatItem(
                context,
                label: '健康在线',
                value: healthyCount.toString(),
                icon: LucideIcons.shieldCheck,
                iconColor: AppColors.success,
              ),
            ],
          ),
          if (onProbeAll != null && keys.isNotEmpty) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onProbeAll,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(LucideIcons.refreshCw, size: 13, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text(
                      '一键探针巡检全部资产',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 1,
      height: 32,
      color: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : const Color(0xFFE2E8F0),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }
}

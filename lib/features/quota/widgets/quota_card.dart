import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_container.dart';
import '../../../core/utils/countdown_helper.dart';
import '../models/quota_model.dart';
import '../services/quota_service.dart';

/// 算力配额与 API Key 卡片组件
class QuotaCard extends StatefulWidget {
  final ApiKeyConfig item;

  const QuotaCard({
    super.key,
    required this.item,
  });

  @override
  State<QuotaCard> createState() => _QuotaCardState();
}

class _QuotaCardState extends State<QuotaCard> {
  bool _isProbing = false;
  bool _isExpanded = false;
  Timer? _timer;
  int _secondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    _initCountdown();
  }

  @override
  void didUpdateWidget(covariant QuotaCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item != widget.item) {
      _initCountdown();
    }
  }

  void _initCountdown() {
    _timer?.cancel();
    final quota = widget.item.tokenQuota;
    if (quota != null) {
      _secondsRemaining = CountdownHelper.getRemainingSeconds(
        quota.nextResetTime,
        quota.secondsRemaining,
      );

      if (_secondsRemaining > 0) {
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() {
              if (_secondsRemaining > 0) {
                _secondsRemaining--;
              } else {
                _timer?.cancel();
              }
            });
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _handleProbe() async {
    if (_isProbing) return;
    setState(() => _isProbing = true);
    HapticFeedback.lightImpact();
    try {
      await QuotaService.probeQuota(widget.item.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已刷新 [${widget.item.name}] 配额探针'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('探针检测异常: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProbing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final item = widget.item;
    final isTokenPlane = item.type == 'token-plane';
    final quota = item.tokenQuota;
    final quotaInfo = item.quotaInfo;

    final remainingPercentage = quota?.remainingPercentage ?? 100.0;
    final quotaColor = AppColors.getQuotaColor(remainingPercentage);
    final providerColor = AppColors.getProviderColor(item.provider);

    return GlassContainer(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      borderRadius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶行：Provider 徽章 + 资源名称 + 操作按钮
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 状态圆点
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.status == 'active'
                      ? AppColors.success
                      : (item.status == 'error' ? AppColors.danger : AppColors.warning),
                  boxShadow: [
                    BoxShadow(
                      color: (item.status == 'active' ? AppColors.success : AppColors.danger)
                          .withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // 资源名称与 Provider
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (quota?.planType != null && quota!.planType!.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accentIndigo.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              quota.planType!,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accentIndigo,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isTokenPlane
                          ? (item.email != null && item.email!.isNotEmpty
                              ? CountdownHelper.maskEmail(item.email)
                              : item.provider)
                          : CountdownHelper.maskApiKey(item.apiKey),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextSecondary,
                        fontFamily: isTokenPlane ? null : 'monospace',
                      ),
                    ),
                  ],
                ),
              ),

              // 探针刷新按钮
              IconButton(
                icon: _isProbing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(LucideIcons.refreshCw, size: 18, color: providerColor),
                tooltip: '探测此资源',
                onPressed: _isProbing ? null : _handleProbe,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Token Plane 额度大盘或 API Key 速率信息
          if (isTokenPlane && quota != null) ...[
            // 额度进度条与倒计时
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      '${remainingPercentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: quotaColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '可用额度',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
                if (_secondsRemaining > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentIndigo.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.clock, size: 12, color: AppColors.accentIndigo),
                        const SizedBox(width: 4),
                        Text(
                          CountdownHelper.formatCountdown(_secondsRemaining),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accentIndigo,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // 线性进度条
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (remainingPercentage / 100).clamp(0.0, 1.0),
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(quotaColor),
                minHeight: 6,
              ),
            ),

            // 子模型明细展开/收起
            if (quota.details.isNotEmpty) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '包含 ${quota.details.length} 个子模型分配',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    Icon(
                      _isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                      size: 16,
                      color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                    ),
                  ],
                ),
              ),
              if (_isExpanded) ...[
                const SizedBox(height: 8),
                ...quota.details.map((detail) => _buildDetailRow(context, detail, isDark)),
              ],
            ],
          ] else if (quotaInfo != null) ...[
            // API Key 探针延迟与限制信息
            Row(
              children: [
                if (quotaInfo.latencyMs != null)
                  _buildTag(
                    context,
                    label: '${quotaInfo.latencyMs} ms',
                    icon: LucideIcons.zap,
                    color: AppColors.accentSky,
                    isDark: isDark,
                  ),
                if (quotaInfo.remainingRequests != null) ...[
                  const SizedBox(width: 8),
                  _buildTag(
                    context,
                    label: 'RPM 剩余: ${quotaInfo.remainingRequests}',
                    icon: LucideIcons.gauge,
                    color: AppColors.success,
                    isDark: isDark,
                  ),
                ],
              ],
            ),
          ] else ...[
            Text(
              '尚未执行探针探测，点击右上方刷新按钮获取实时额度',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, QuotaDetailItem detail, bool isDark) {
    final detailColor = AppColors.getQuotaColor(detail.remainingPercentage);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: detailColor,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                detail.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          Text(
            '${detail.remainingPercentage.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: detailColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'coupon_model.dart';
import 'mt_account_store.dart';
import 'mt_coupon_api.dart';
import 'mt_passport.dart';

/// Coupon page — pure content widget, no inner Scaffold.
/// Mounted inside AppPage's IndexedStack which provides the single root Scaffold.
class CouponPage extends StatefulWidget {
  const CouponPage({super.key});

  @override
  State<CouponPage> createState() => _CouponPageState();
}

enum _Phase { idle, working, qrcode, polling, done }

class _CouponPageState extends State<CouponPage> {
  _Phase _phase = _Phase.idle;
  String _qrUrl = '';
  IssueResult? _result;
  String _statusText = '';
  String _errorText = '';

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await MtAccountStore.init();
    if (!mounted) return;
    setState(() {});
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  // ── 登录流程 ────────────────────────────────────────────────

  Future<void> _startLogin() async {
    setState(() {
      _phase = _Phase.working;
      _errorText = '';
      _statusText = '正在初始化登录引擎…';
    });

    try {
      await MtPassport.init();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.idle;
        _errorText = '登录引擎初始化失败：$e';
      });
      return;
    }

    if (!mounted) return;
    setState(() => _statusText = '正在获取登录二维码…');

    final code = await MtPassport.getAuthCode();
    if (!code.ok || code.qrCodeUrl.isEmpty) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.idle;
        _errorText = code.message.isNotEmpty ? code.message : '获取二维码失败';
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _phase = _Phase.qrcode;
      _qrUrl = code.qrCodeUrl;
      _statusText = '';
    });

    await _pollForToken();
  }

  Future<void> _pollForToken() async {
    if (!mounted) return;
    setState(() {
      _phase = _Phase.polling;
      _statusText = '等待扫码确认…';
    });

    final poll = await MtPassport.pollToken(timeout: const Duration(minutes: 5));

    if (!mounted) return;

    if (!poll.ok || poll.token.isEmpty) {
      setState(() {
        _phase = _Phase.idle;
        _errorText = poll.message.isNotEmpty ? poll.message : '未获取到 token';
      });
      return;
    }

    final alias = MtAccountStore.nextAlias();
    await MtAccountStore.saveAccount(MtAccount(
      alias: alias,
      token: poll.token,
      deviceToken: poll.deviceToken,
      addedAt: DateTime.now().millisecondsSinceEpoch,
    ));

    if (!mounted) return;
    setState(() {
      _phase = _Phase.idle;
      _statusText = '';
    });
    _snack('已登录并保存为「$alias」');
  }

  // ── 领券流程 ────────────────────────────────────────────────

  Future<void> _claim() async {
    final account = MtAccountStore.active;
    if (account == null) {
      _snack('请先登录账号');
      return;
    }

    setState(() {
      _phase = _Phase.working;
      _errorText = '';
      _statusText = '正在领取…';
    });

    final result = await MtCouponApi.issueCoupon(account.token);

    if (!mounted) return;
    setState(() {
      _phase = _Phase.done;
      _result = result;
      _statusText = '';
      if (!result.ok) {
        _errorText = result.message;
      }
    });
  }

  // ── 账号操作 ────────────────────────────────────────────────

  Future<void> _switchAccount(String alias) async {
    await MtAccountStore.setActive(alias);
    if (!mounted) return;
    setState(() {
      _result = null;
      _errorText = '';
      _phase = _Phase.idle;
    });
  }

  Future<void> _deleteAccount(String alias) async {
    await MtAccountStore.deleteAccount(alias);
    if (!mounted) return;
    setState(() {
      _result = null;
      _errorText = '';
      _phase = _Phase.idle;
    });
    _snack('已删除「$alias」');
  }

  /// 导入电脑上的设备指纹（dfpid），实现设备身份继承。
  /// 数据来源：电脑端 ~/.cliguard/cliguard-info.json 的内容。
  Future<void> _importDfpid() async {
    if (!mounted) return;
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('导入设备指纹（dfpid）'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '把电脑上 ~/.cliguard/cliguard-info.json 的完整内容粘贴到下方，'
              '手机将沿用电脑的设备身份，避免被识别为全新设备。',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 5,
              minLines: 3,
              decoration: const InputDecoration(
                hintText: '{"localid":"...","dfpid":"...","timestamp":...}',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('导入'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final raw = controller.text.trim();
    if (raw.isEmpty) {
      _snack('内容为空，未导入');
      return;
    }
    await MtPassport.setDeviceFingerprintFromJson(raw);
    if (!mounted) return;
    _snack(MtPassport.isReady ? '已导入，重启 App 后生效' : '已导入，下次登录时生效');
  }

  // ── 界面 ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _buildAccountBar(cs),
          const SizedBox(height: 12),
          if (_errorText.isNotEmpty) ...[
            _buildError(cs),
            const SizedBox(height: 12),
          ],
          _buildActionArea(cs),
          if (_result != null && _result!.ok) ...[
            const SizedBox(height: 16),
            _buildCouponList(cs),
          ],
        ],
      ),
    );
  }

  Widget _buildAccountBar(ColorScheme cs) {
    return ValueListenableBuilder<List<MtAccount>>(
      valueListenable: MtAccountStore.accountsNotifier,
      builder: (context, accounts, _) {
        if (accounts.isEmpty) {
          return _card(
            cs,
            child: Row(
              children: [
                Icon(LucideIcons.userRoundPlus, size: 18, color: cs.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '尚未登录任何账号',
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          );
        }

        return ValueListenableBuilder<String?>(
          valueListenable: MtAccountStore.activeAliasNotifier,
          builder: (context, activeAlias, _) {
            final active = MtAccountStore.active;
            return _card(
              cs,
              child: Row(
                children: [
                  Icon(LucideIcons.userRound, size: 18, color: cs.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          active?.alias ?? '未选择账号',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        if (active != null)
                          Text(
                            active.maskedToken,
                            style: TextStyle(
                                fontSize: 11, color: cs.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: '账号管理',
                    icon: Icon(LucideIcons.settings2,
                        size: 18, color: cs.onSurfaceVariant),
                    onSelected: (value) {
                      if (value == '__delete__' && active != null) {
                        _deleteAccount(active.alias);
                      } else if (value == '__import_dfpid__') {
                        _importDfpid();
                      } else {
                        _switchAccount(value);
                      }
                    },
                    itemBuilder: (context) => [
                      for (final a in accounts)
                        PopupMenuItem<String>(
                          value: a.alias,
                          child: Row(
                            children: [
                              if (a.alias == activeAlias)
                                Icon(LucideIcons.check,
                                    size: 16, color: cs.primary),
                              if (a.alias == activeAlias)
                                const SizedBox(width: 6),
                              Text(a.alias),
                            ],
                          ),
                        ),
                      const PopupMenuDivider(),
                      const PopupMenuItem<String>(
                        value: '__import_dfpid__',
                        child: Row(
                          children: [
                            Icon(LucideIcons.fingerprint, size: 16),
                            SizedBox(width: 8),
                            Text('导入设备指纹（dfpid）'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: '__delete__',
                        child: Row(
                          children: [
                            Icon(LucideIcons.trash2, size: 16),
                            SizedBox(width: 8),
                            Text('删除当前账号'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildError(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.circleAlert, size: 16, color: cs.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorText,
              style: TextStyle(fontSize: 12, color: cs.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionArea(ColorScheme cs) {
    final hasAccount = MtAccountStore.hasAccount;
    final busy = _phase == _Phase.working || _phase == _Phase.polling;

    return _card(
      cs,
      child: Column(
        children: [
          if (_phase == _Phase.qrcode || _phase == _Phase.polling) ...[
            Text(
              '用美团 App 扫码登录',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: QrImageView(
                data: _qrUrl,
                version: QrVersions.auto,
                size: 180,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            if (_statusText.isNotEmpty)
              Text(
                _statusText,
                style: TextStyle(fontSize: 12, color: cs.primary),
              ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => setState(() {
                _phase = _Phase.idle;
                _qrUrl = '';
                _statusText = '';
              }),
              icon: const Icon(LucideIcons.x, size: 16),
              label: const Text('取消'),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: busy ? null : (hasAccount ? _claim : _startLogin),
                icon: busy
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.onPrimary,
                        ),
                      )
                    : Icon(hasAccount
                        ? LucideIcons.ticket
                        : LucideIcons.scanQrCode),
                label: Text(hasAccount
                    ? (_phase == _Phase.working ? '领取中…' : '立即领券')
                    : '扫码登录'),
              ),
            ),
            if (_statusText.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                _statusText,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ],
            if (hasAccount) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: busy ? null : _startLogin,
                icon: const Icon(LucideIcons.userRoundPlus, size: 16),
                label: const Text('添加其他账号'),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildCouponList(ColorScheme cs) {
    final result = _result!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.ticket, size: 16, color: cs.primary),
            const SizedBox(width: 6),
            Text(
              '本次领到 ${result.count} 张',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            Text(
              '合计 ¥${result.totalAmount.toStringAsFixed(result.totalAmount == result.totalAmount.roundToDouble() ? 0 : 1)}',
              style: TextStyle(fontSize: 13, color: cs.primary),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (final coupon in result.coupons)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildCouponItem(cs, coupon),
          ),
      ],
    );
  }

  Widget _buildCouponItem(ColorScheme cs, Coupon coupon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Column(
              children: [
                Text(
                  '¥${coupon.discountAmount}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: cs.primary,
                  ),
                ),
                Text(
                  coupon.tabName,
                  style:
                      TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coupon.couponName,
                  style: const TextStyle(fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(LucideIcons.tag, size: 11, color: cs.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        coupon.useCondition,
                        style: TextStyle(
                            fontSize: 11, color: cs.onSurfaceVariant),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(LucideIcons.calendar,
                        size: 11, color: cs.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      coupon.expireTime,
                      style:
                          TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(ColorScheme cs, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: child,
    );
  }
}

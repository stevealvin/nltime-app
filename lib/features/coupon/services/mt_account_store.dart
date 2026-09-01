import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/coupon_model.dart';

/// 多账号存储。风格对齐 AppService：静态成员 + ValueNotifier 驱动 UI。
///
/// 注意：token 属于凭据，此处用 SharedPreferences 明文存储（与项目现有做法一致）。
/// 若后续要提高安全性，可替换为 flutter_secure_storage，接口保持不变。
class MtAccountStore {
  static late SharedPreferences prefs;

  static const String _prefsKeyAccounts = 'mt_accounts';
  static const String _prefsKeyActiveAlias = 'mt_active_alias';

  /// 账号列表变化通知
  static final ValueNotifier<List<MtAccount>> accountsNotifier =
      ValueNotifier<List<MtAccount>>(<MtAccount>[]);

  /// 当前激活账号别名
  static final ValueNotifier<String?> activeAliasNotifier =
      ValueNotifier<String?>(null);

  static Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
    _reload();
  }

  static List<MtAccount> get accounts => accountsNotifier.value;

  static MtAccount? get active {
    final alias = activeAliasNotifier.value;
    if (alias == null) return null;
    for (final a in accountsNotifier.value) {
      if (a.alias == alias) return a;
    }
    return null;
  }

  static bool get hasAccount => accountsNotifier.value.isNotEmpty;

  static void _reload() {
    final raw = prefs.getString(_prefsKeyAccounts);
    final list = <MtAccount>[];
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              list.add(MtAccount.fromJson(item));
            }
          }
        }
      } catch (_) {
        // 数据损坏时按空列表处理，避免启动崩溃
      }
    }
    accountsNotifier.value = list;

    final active = prefs.getString(_prefsKeyActiveAlias);
    activeAliasNotifier.value =
        (active != null && list.any((a) => a.alias == active)) ? active : null;
  }

  static Future<void> _persist() async {
    final encoded =
        jsonEncode(accountsNotifier.value.map((a) => a.toJson()).toList());
    await prefs.setString(_prefsKeyAccounts, encoded);
  }

  /// 新增或覆盖同名账号，并设为激活
  static Future<void> saveAccount(MtAccount account) async {
    final list = List<MtAccount>.of(accountsNotifier.value);
    list.removeWhere((a) => a.alias == account.alias);
    list.add(account);
    accountsNotifier.value = list;
    await _persist();
    await setActive(account.alias);
  }

  static Future<void> deleteAccount(String alias) async {
    final list = List<MtAccount>.of(accountsNotifier.value)
      ..removeWhere((a) => a.alias == alias);
    accountsNotifier.value = list;
    await _persist();

    if (activeAliasNotifier.value == alias) {
      await setActive(list.isNotEmpty ? list.first.alias : null);
    }
  }

  static Future<void> setActive(String? alias) async {
    activeAliasNotifier.value = alias;
    if (alias == null) {
      await prefs.remove(_prefsKeyActiveAlias);
    } else {
      await prefs.setString(_prefsKeyActiveAlias, alias);
    }
  }

  /// 生成不重复的默认别名：账号_1、账号_2 ...
  static String nextAlias() {
    final existing = accountsNotifier.value.map((a) => a.alias).toSet();
    var i = existing.length + 1;
    while (existing.contains('账号_$i')) {
      i++;
    }
    return '账号_$i';
  }
}

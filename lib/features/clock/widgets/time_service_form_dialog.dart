import 'package:material_ui/material_ui.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../settings/services/theme_manager.dart';
import '../models/time_service_model.dart';

class TimeServiceFormData {
  final String name;
  final String url;
  final TimeParseType parseType;
  final String? customKey;

  TimeServiceFormData({
    required this.name,
    required this.url,
    required this.parseType,
    this.customKey,
  });
}

class PresetItem {
  final String name;
  final String url;
  final TimeParseType parseType;
  final String? customKey;

  const PresetItem({
    required this.name,
    required this.url,
    required this.parseType,
    this.customKey,
  });
}

class TimeServiceFormDialog extends StatefulWidget {
  final TimeService? service;
  final AppThemeData? theme; // nullable — falls back to ambient M3 theme

  const TimeServiceFormDialog({
    super.key,
    this.service,
    this.theme,
  });

  static Future<TimeServiceFormData?> show(
    BuildContext context, {
    TimeService? service,
    AppThemeData? theme,
  }) {
    return showDialog<TimeServiceFormData>(
      context: context,
      barrierDismissible: true,
      builder: (context) => TimeServiceFormDialog(
        service: service,
        theme: theme,
      ),
    );
  }

  @override
  State<TimeServiceFormDialog> createState() => _TimeServiceFormDialogState();
}

class _TimeServiceFormDialogState extends State<TimeServiceFormDialog> {
  late TextEditingController _nameController;
  late TextEditingController _urlController;
  late TextEditingController _customKeyController;

  late TimeParseType _parseType;
  bool _isTesting = false;
  String? _testSuccessInfo;
  String? _testErrorInfo;

  static const List<PresetItem> _presets = [
    PresetItem(
      name: '哔哩哔哩授时',
      url: 'https://api.bilibili.com/x/report/click/now',
      parseType: TimeParseType.customKey,
      customKey: 'now',
    ),
    PresetItem(
      name: '苏宁开放授时',
      url: 'https://f.m.suning.com/api/ct.do',
      parseType: TimeParseType.suning,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.service?.name ?? '');
    _urlController = TextEditingController(text: widget.service?.url ?? '');
    _customKeyController =
        TextEditingController(text: widget.service?.customKey ?? '');
    _parseType = widget.service?.parseType ?? TimeParseType.timestampMs;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _customKeyController.dispose();
    super.dispose();
  }

  void _applyPreset(PresetItem preset) {
    setState(() {
      _nameController.text = preset.name;
      _urlController.text = preset.url;
      _parseType = preset.parseType;
      _customKeyController.text = preset.customKey ?? '';
      _testSuccessInfo = null;
      _testErrorInfo = null;
    });
  }

  Future<void> _testConnection() async {
    final urlStr = _urlController.text.trim();
    if (urlStr.isEmpty) {
      setState(() {
        _testErrorInfo = '请先输入有效的 URL 地址';
        _testSuccessInfo = null;
      });
      return;
    }

    setState(() {
      _isTesting = true;
      _testSuccessInfo = null;
      _testErrorInfo = null;
    });

    final tempService = TimeService(
      id: 'test',
      name: _nameController.text.trim(),
      url: urlStr,
      isBuiltin: false,
      parseType: _parseType,
      customKey: _customKeyController.text.trim().isNotEmpty
          ? _customKeyController.text.trim()
          : null,
    );

    final sendTime = DateTime.now().millisecondsSinceEpoch;

    try {
      final res = await http.get(
        Uri.parse(urlStr),
        headers: {'User-Agent': 'NLTime/1.0'},
      ).timeout(const Duration(seconds: 4));

      final recvTime = DateTime.now().millisecondsSinceEpoch;
      final rtt = recvTime - sendTime;

      if (res.statusCode == 200) {
        final serverTimeMs = tempService.parseTimestampMs(res.body);
        if (serverTimeMs != null) {
          final timeFormatted = DateFormat('yyyy-MM-dd HH:mm:ss.SSS')
              .format(DateTime.fromMillisecondsSinceEpoch(serverTimeMs));
          if (mounted) {
            setState(() {
              _isTesting = false;
              _testSuccessInfo =
                  '✅ 测试成功！\n- RTT 延迟: $rtt ms\n- 节点响应时间: $timeFormatted';
            });
          }
          return;
        } else {
          if (mounted) {
            setState(() {
              _isTesting = false;
              _testErrorInfo =
                  '❌ 访问成功(200 OK)，但无法根据当前规则解析出时间戳，请检查数据格式或自定义 Key。';
            });
          }
          return;
        }
      } else {
        if (mounted) {
          setState(() {
            _isTesting = false;
            _testErrorInfo = '❌ HTTP 请求失败，响应码: ${res.statusCode}';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTesting = false;
          _testErrorInfo = '❌ 连接失败: $e';
        });
      }
    }
  }

  void _submit() {
    final name = _nameController.text.trim();
    var url = _urlController.text.trim();

    if (name.isEmpty || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('接口名称和 URL 地址不能为空')),
      );
      return;
    }

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    Navigator.of(context).pop(
      TimeServiceFormData(
        name: name,
        url: url,
        parseType: _parseType,
        customKey: _customKeyController.text.trim().isNotEmpty
            ? _customKeyController.text.trim()
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Resolve colors from optional AppThemeData or ambient Material 3 ColorScheme
    final cs = Theme.of(context).colorScheme;
    final t = widget.theme;
    final cardBg = t?.cardColor ?? cs.surfaceContainerHighest;
    final divider = t?.dividerColor ?? cs.outline;
    final textCol = t?.textColor ?? cs.onSurface;
    final subText = t?.subTextColor ?? cs.onSurface.withValues(alpha: 0.6);
    final primary = t?.primaryColor ?? cs.primary;
    final accent = t?.accentColor ?? cs.secondary;
    final bgCol = t?.bgColor ?? cs.surface;
    final isEditMode = widget.service != null;

    InputDecoration fieldDeco({
      required String hint,
      required IconData icon,
      Color? iconColor,
    }) =>
        InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: subText.withValues(alpha: 0.6), fontSize: 13),
          prefixIcon: Icon(icon, color: iconColor ?? primary, size: 20),
          filled: true,
          fillColor: bgCol,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: primary, width: 1.5),
          ),
        );

    return Dialog(
      backgroundColor: cardBg,
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: divider, width: 1.5),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isEditMode
                              ? Icons.edit_rounded
                              : Icons.add_link_rounded,
                          color: primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isEditMode ? '编辑授时接口' : '添加授时服务器',
                        style: TextStyle(
                          color: textCol,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: subText),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Presets
              if (!isEditMode) ...[
                Text(
                  '快速导入公共授时预设',
                  style: TextStyle(
                    color: subText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _presets.map((p) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: ActionChip(
                          avatar: Icon(Icons.bolt_rounded,
                              size: 14, color: accent),
                          label: Text(p.name),
                          labelStyle:
                              TextStyle(color: textCol, fontSize: 11),
                          backgroundColor: bgCol,
                          side: BorderSide(color: divider),
                          onPressed: () => _applyPreset(p),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Name field
              Text('接口名称',
                  style: TextStyle(
                      color: textCol,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                style: TextStyle(color: textCol, fontSize: 14),
                decoration: fieldDeco(
                  hint: '如: 我的私有 NTP/HTTP 授时源',
                  icon: Icons.edit_note_rounded,
                ),
              ),
              const SizedBox(height: 16),

              // URL field
              Text('API Endpoint URL 地址',
                  style: TextStyle(
                      color: textCol,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: _urlController,
                style: TextStyle(color: textCol, fontSize: 14),
                keyboardType: TextInputType.url,
                decoration: fieldDeco(
                  hint: 'https://api.example.com/time',
                  icon: Icons.link_rounded,
                  iconColor: accent,
                ),
              ),
              const SizedBox(height: 16),

              // Parse type dropdown
              Text('响应数据解析规则',
                  style: TextStyle(
                      color: textCol,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: bgCol,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: divider),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<TimeParseType>(
                    value: _parseType,
                    dropdownColor: cardBg,
                    isExpanded: true,
                    style: TextStyle(color: textCol, fontSize: 13),
                    icon: Icon(Icons.arrow_drop_down_rounded, color: primary),
                    items: const [
                      DropdownMenuItem(
                          value: TimeParseType.timestampMs,
                          child: Text('毫秒时间戳 (e.g. 1700000000000)')),
                      DropdownMenuItem(
                          value: TimeParseType.timestampSec,
                          child: Text('秒级时间戳 (e.g. 1700000000)')),
                      DropdownMenuItem(
                          value: TimeParseType.iso8601,
                          child: Text('ISO 8601 字符串 (e.g. 2026-07-28T...)')),
                      DropdownMenuItem(
                          value: TimeParseType.taobao,
                          child: Text('淘宝 API 格式 (data.t)')),
                      DropdownMenuItem(
                          value: TimeParseType.suning,
                          child: Text('苏宁 API 格式 (currentTime)')),
                      DropdownMenuItem(
                          value: TimeParseType.jd,
                          child: Text('京东 API 格式 (currentTime2)')),
                      DropdownMenuItem(
                          value: TimeParseType.customKey,
                          child: Text('自定义 JSON Key 提取')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _parseType = val);
                    },
                  ),
                ),
              ),

              // Custom key field
              if (_parseType == TimeParseType.customKey) ...[
                const SizedBox(height: 14),
                Text('JSON Key 字段名',
                    style: TextStyle(
                        color: textCol,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: _customKeyController,
                  style: TextStyle(color: textCol, fontSize: 14),
                  decoration: fieldDeco(
                    hint: '如: sys_time 或 timestamp',
                    icon: Icons.key_rounded,
                    iconColor: Colors.amber,
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Test button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: primary.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _isTesting ? null : _testConnection,
                  icon: _isTesting
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: primary),
                        )
                      : Icon(Icons.network_check_rounded,
                          color: primary, size: 18),
                  label: Text(
                    _isTesting ? '正在测试 API 连通性...' : '⚡ 测试接口连通性与解析',
                    style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ),
              ),

              if (_testSuccessInfo != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _testSuccessInfo!,
                    style: const TextStyle(
                        color: Colors.greenAccent, fontSize: 12, height: 1.4),
                  ),
                ),
              ],

              if (_testErrorInfo != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _testErrorInfo!,
                    style: const TextStyle(
                        color: Colors.redAccent, fontSize: 12, height: 1.4),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('取消', style: TextStyle(color: subText)),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _submit,
                    child: const Text('保存接口',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import '../../core/theme/app_colors.dart';

/// 应用内内置极简 WebView 浏览页面 (In-App WebView)
class AppWebViewPage extends StatefulWidget {
  final String url;
  final String? title;

  const AppWebViewPage({
    super.key,
    required this.url,
    this.title,
  });

  /// 快捷导航打开方法
  static void open(BuildContext context, {required String url, String? title}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AppWebViewPage(url: url, title: title),
      ),
    );
  }

  @override
  State<AppWebViewPage> createState() => _AppWebViewPageState();
}

class _AppWebViewPageState extends State<AppWebViewPage> {
  late final WebViewController _controller;
  String _currentUrl = '';
  String _pageTitle = '';
  double _progress = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.url;
    _pageTitle = widget.title ?? widget.url;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _progress = progress / 100.0;
                _isLoading = progress < 100;
              });
            }
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _currentUrl = url;
                _isLoading = true;
              });
            }
          },
          onPageFinished: (String url) async {
            if (mounted) {
              setState(() {
                _currentUrl = url;
                _isLoading = false;
              });
              try {
                final t = await _controller.getTitle();
                if (mounted && t != null && t.isNotEmpty) {
                  setState(() => _pageTitle = t);
                }
              } catch (_) {}

              // 注入前端 Blob/下载监听钩子
              try {
                await _controller.runJavaScript('''
                  (function() {
                    if (window.__flutterDownloadHooked) return;
                    window.__flutterDownloadHooked = true;
                    document.addEventListener('click', function(e) {
                      var target = e.target;
                      while (target && target.tagName !== 'A') {
                        target = target.parentElement;
                      }
                      if (target && target.tagName === 'A') {
                        var href = target.getAttribute('href') || '';
                        var download = target.getAttribute('download');
                        if (download !== null || href.startsWith('blob:') || href.startsWith('data:')) {
                          if (window.FlutterDownloadChannel && href.startsWith('blob:')) {
                            fetch(href).then(r => r.blob()).then(blob => {
                              var reader = new FileReader();
                              reader.onloadend = function() {
                                window.FlutterDownloadChannel.postMessage(JSON.stringify({
                                  name: download || 'download_file',
                                  data: reader.result
                                }));
                              };
                              reader.readAsDataURL(blob);
                            }).catch(console.error);
                          }
                        }
                      }
                    }, true);
                  })();
                ''');
              } catch (_) {}
            }
          },
          onNavigationRequest: (NavigationRequest request) async {
            final url = request.url;
            final uri = Uri.tryParse(url);

            // 1. 拦截非 http/https 自定义协议（如 intent://, market://, alipays://, weixin:// 等）
            if (uri != null && uri.scheme != 'http' && uri.scheme != 'https') {
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
              return NavigationDecision.prevent;
            }

            // 2. 拦截常见二进制下载文件链接，唤起系统下载器或外部浏览器安全下载
            final lowerUrl = url.toLowerCase();
            const downloadExtensions = [
              '.apk', '.zip', '.rar', '.7z', '.tar', '.gz',
              '.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx',
              '.mp3', '.mp4', '.avi', '.mov', '.dmg', '.exe', '.ipa'
            ];

            final isDownloadLink = downloadExtensions.any((ext) => lowerUrl.contains(ext));
            if (isDownloadLink && uri != null) {
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('已唤起系统下载器进行下载'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView resource error: ${error.description}');
          },
        ),
      )
      ..addJavaScriptChannel(
        'FlutterDownloadChannel',
        onMessageReceived: (JavaScriptMessage message) async {
          try {
            final data = jsonDecode(message.message) as Map<String, dynamic>;
            final fileName = data['name'] ?? 'download_${DateTime.now().millisecondsSinceEpoch}';
            final base64Data = data['data'] as String?;
            if (base64Data != null && base64Data.isNotEmpty) {
              final clean = base64Data.contains(',') ? base64Data.split(',').last : base64Data;
              final bytes = base64Decode(clean);
              final dir = Directory('/storage/emulated/0/Download');
              final saveDir = dir.existsSync() ? dir : Directory.systemTemp;
              final file = File('${saveDir.path}/$fileName');
              await file.writeAsBytes(bytes);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(LucideIcons.checkCircle2, color: Colors.white, size: 18),
                        const SizedBox(width: 10),
                        Expanded(child: Text('文件已保存至: ${file.path}')),
                      ],
                    ),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            }
          } catch (e) {
            debugPrint('Blob download error: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('下载保存失败: $e'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.red.shade700,
                ),
              );
            }
          }
        },
      )
      ..loadRequest(Uri.parse(widget.url));

    // Android 原生文件上传选择器与权限配置
    if (_controller.platform is AndroidWebViewController) {
      final androidController = _controller.platform as AndroidWebViewController;
      androidController.setMediaPlaybackRequiresUserGesture(false);
      androidController.setOnPlatformPermissionRequest((request) {
        request.grant();
      });
      androidController.setOnShowFileSelector((FileSelectorParams params) async {
        try {
          final ImagePicker picker = ImagePicker();
          if (params.mode == FileSelectorMode.openMultiple) {
            final List<XFile> medias = await picker.pickMultipleMedia();
            return medias.map((e) => Uri.file(e.path).toString()).toList();
          } else {
            final accept = params.acceptTypes.join(',').toLowerCase();
            if (accept.contains('video')) {
              final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
              if (video != null) return [Uri.file(video.path).toString()];
            } else {
              final XFile? media = await picker.pickMedia();
              if (media != null) return [Uri.file(media.path).toString()];
            }
          }
        } catch (e) {
          debugPrint('WebView file picker error: $e');
        }
        return [];
      });
    }
  }

  /// 提取域名 Host
  String get _domainHost {
    try {
      final uri = Uri.parse(_currentUrl);
      return uri.host.isNotEmpty ? uri.host : _currentUrl;
    } catch (_) {
      return _currentUrl;
    }
  }

  /// 底部快捷功能抽屉 (Action Sheet)
  void _showMoreActions(BuildContext context) {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 顶部小滑块
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // 网址概览
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.globe, size: 14, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _currentUrl,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Divider(
                  height: 1,
                  thickness: 0.5,
                  color: isDark ? Colors.white10 : Colors.black12,
                ),

                // 1. 复制链接
                ListTile(
                  dense: true,
                  leading: const Icon(LucideIcons.copy, size: 18),
                  title: const Text('复制链接', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: _currentUrl));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已复制当前链接到剪贴板'), duration: Duration(seconds: 1)),
                    );
                  },
                ),

                // 2. 在系统默认浏览器中打开
                ListTile(
                  dense: true,
                  leading: const Icon(LucideIcons.externalLink, size: 18, color: AppColors.primary),
                  title: const Text('在系统浏览器中打开', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final uri = Uri.parse(_currentUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                ),

                // 3. 刷新页面
                ListTile(
                  dense: true,
                  leading: const Icon(LucideIcons.refreshCw, size: 18),
                  title: const Text('刷新当前页面', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _controller.reload();
                  },
                ),

                // 4. 生成二维码分享
                ListTile(
                  dense: true,
                  leading: const Icon(LucideIcons.qrCode, size: 18),
                  title: const Text('二维码分享', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showQrDialog(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showQrDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Center(child: Text('网页二维码')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: _currentUrl,
                version: QrVersions.auto,
                size: 200,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _domainHost,
              style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _controller.canGoBack()) {
          await _controller.goBack();
        } else {
          if (context.mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, size: 20),
            onPressed: () async {
              if (await _controller.canGoBack()) {
                await _controller.goBack();
              } else {
                if (context.mounted) Navigator.of(context).pop();
              }
            },
          ),
          title: Text(
            _pageTitle,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            // 关闭按钮
            IconButton(
              icon: const Icon(LucideIcons.x, size: 18),
              tooltip: '关闭',
              onPressed: () => Navigator.of(context).pop(),
            ),
            // 更多操作按钮
            IconButton(
              icon: const Icon(LucideIcons.moreHorizontal, size: 20),
              tooltip: '更多选项',
              onPressed: () => _showMoreActions(context),
            ),
          ],
          bottom: _isLoading
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(2),
                  child: LinearProgressIndicator(
                    value: _progress > 0 ? _progress : null,
                    minHeight: 2,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                )
              : null,
        ),
        body: WebViewWidget(controller: _controller),
      ),
    );
  }
}

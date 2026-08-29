import 'package:flutter/material.dart';
import '../common/theme_manager.dart';

class AppDialog {
  /// Show a custom branded confirmation dialog matching the app theme.
  /// [theme] is optional — if null the dialog adapts to the ambient MaterialApp theme.
  static Future<bool?> confirm({
    required BuildContext context,
    AppThemeData? theme,
    required String title,
    required String message,
    String confirmText = '确认',
    String cancelText = '取消',
    Color? confirmColor,
    IconData icon = Icons.help_outline_rounded,
  }) {
    final cs = Theme.of(context).colorScheme;
    final cardBg = theme?.cardColor ?? cs.surfaceContainerHighest;
    final divider = theme?.dividerColor ?? cs.outline;
    final textCol = theme?.textColor ?? cs.onSurface;
    final subText = theme?.subTextColor ?? cs.onSurface.withValues(alpha: 0.6);
    final primary = confirmColor ?? theme?.primaryColor ?? cs.primary;

    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: divider, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 30,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: primary),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(color: textCol, fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                message,
                style: TextStyle(color: subText, fontSize: 14, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: divider),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text(
                        cancelText,
                        style: TextStyle(color: subText, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: Text(
                        confirmText,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show a floating branded SnackBar.
  /// [theme] is optional — falls back to ambient ColorScheme when null.
  static void showToast({
    required BuildContext context,
    AppThemeData? theme,
    required String message,
    bool isError = false,
    IconData? icon,
  }) {
    final cs = Theme.of(context).colorScheme;
    final cardBg = theme?.cardColor ?? cs.surfaceContainerHighest;
    final textCol = theme?.textColor ?? cs.onSurface;
    final accentCol = isError
        ? Colors.redAccent
        : (theme?.primaryColor ?? cs.primary);

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          backgroundColor: cardBg,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: accentCol, width: 1.2),
          ),
          content: Row(
            children: [
              Icon(
                icon ??
                    (isError
                        ? Icons.error_outline_rounded
                        : Icons.check_circle_outline_rounded),
                color: accentCol,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: textCol,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}

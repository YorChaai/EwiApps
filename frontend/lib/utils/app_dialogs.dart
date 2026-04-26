import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppDialogs {
  static Future<bool> showExitConfirmation(
    BuildContext context, {
    required bool isLogout,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Helper colors
    final titleColor = isDark ? AppTheme.cream : AppTheme.lightTextPrimary;
    final bodyColor = isDark
        ? AppTheme.textSecondary
        : AppTheme.lightTextSecondary;
    final cardColor = isDark ? AppTheme.card : AppTheme.lightCard;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: EdgeInsets.zero,
        title: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 48, 8),
              child: Row(
                children: [
                  Icon(
                    isLogout ? Icons.logout_rounded : Icons.exit_to_app_rounded,
                    color: AppTheme.danger,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isLogout ? 'Logout' : 'Keluar Aplikasi',
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(ctx, false),
                color: bodyColor.withValues(alpha: 0.5),
                splashRadius: 20,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isLogout
                  ? 'Apakah Anda yakin ingin keluar dari akun Anda?'
                  : 'Apakah Anda yakin ingin menutup aplikasi Exspan?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: bodyColor,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.danger,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  shadowColor: AppTheme.danger.withValues(alpha: 0.4),
                ),
                child: Text(
                  isLogout ? 'Keluar Sekarang' : 'Tutup Aplikasi',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );

    return result ?? false;
  }
}

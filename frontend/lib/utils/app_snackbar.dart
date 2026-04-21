import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Global key for root ScaffoldMessenger - ensures SnackBar shows correctly
/// even when called from dialogs, overlays, or after async gaps.
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Tampilkan SnackBar/toast secara global.
/// Gunakan ini ketika ScaffoldMessenger.of(context) tidak berhasil
/// (misalnya setelah async, di dalam dialog, atau context sudah disposed).
class AppSnackbar {
  static void show(
    String message, {
    bool isError = false,
    bool isSuccess = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = rootScaffoldMessengerKey.currentState;
    if (messenger == null) return;

    Color? backgroundColor;
    if (isError) backgroundColor = AppTheme.danger;
    if (isSuccess) backgroundColor = AppTheme.success;

    // ✅ Clear existing SnackBars to prevent stacking
    messenger.clearSnackBars();

    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void success(String message) => show(message, isSuccess: true);
  static void error(String message) => show(message, isError: true);
}

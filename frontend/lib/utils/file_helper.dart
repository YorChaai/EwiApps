import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class FileHelper {
  // Default path, but can be overridden by user
  static const String _defaultWindowsExportPath =
      'D:\\2. Organize\\1. Projects\\MiniProjectKPI_EWI\\data';

  static const String _prefsKey = 'windows_export_path';

  static Future<Directory> _resolveExportDirectory() async {
    if (Platform.isWindows) {
      // Try to get custom path from SharedPreferences first
      try {
        final prefs = await SharedPreferences.getInstance();
        final customPath = prefs.getString(_prefsKey);
        if (customPath != null && customPath.isNotEmpty) {
          return Directory(customPath);
        }
      } catch (_) {
        // Fallback to default if prefs fail
      }
      return Directory(_defaultWindowsExportPath);
    }

    if (Platform.isAndroid) {
  // simpan file ke storage aplikasi di android
      final dir = await getExternalStorageDirectory();
      return dir ?? await getApplicationDocumentsDirectory();
    }

    if (Platform.isIOS || Platform.isMacOS) {
      final dir = await getDownloadsDirectory();
      return dir ?? await getApplicationDocumentsDirectory();
    }

    return await getApplicationDocumentsDirectory();
  }

  static Future<String?> saveAndOpenFolder({
    required BuildContext context,
    required List<int> bytes,
    required String filename,
    String? successMessage,
  }) async {
    return saveFile(
      context: context,
      bytes: bytes,
      filename: filename,
      successMessage: successMessage,
    );
  }

  static Future<String?> saveAndOpenFile({
    required BuildContext context,
    required List<int> bytes,
    required String filename,
    String? successMessage,
  }) async {
    final savedPath = await saveFile(
      context: context,
      bytes: bytes,
      filename: filename,
      successMessage: successMessage,
    );
    if (savedPath != null) {
      await openFile(savedPath);
    }
    return savedPath;
  }

  static Future<String?> saveFile({
    required BuildContext context,
    required List<int> bytes,
    required String filename,
    String? successMessage,
  }) async {
    try {
      final dir = await _resolveExportDirectory();
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final stampedFilename = _ensureTimestampedFilename(filename);
      final initialPath = '${dir.path}/$stampedFilename';
      final file = await _resolveWritableFilePath(initialPath);
      await file.writeAsBytes(bytes, flush: true);

      if (context.mounted) {
        final path = file.path;

        // ✅ Clear any existing SnackBar first to prevent stacking
        final messenger = ScaffoldMessenger.of(context);
        messenger.clearSnackBars();

        // ✅ Use fixed behavior for reliable auto-dismiss
        final snackBar = SnackBar(
          content: Text(successMessage ?? 'File disimpan: $path'),
          backgroundColor: AppTheme.success,
          duration: const Duration(seconds: 10),
          action: SnackBarAction(
            label: 'BUKA FILE',
            textColor: Colors.white,
            onPressed: () => openFile(path),
          ),
          behavior: SnackBarBehavior.fixed,  // ✅ Fixed untuk reliable auto-dismiss
        );

        // ✅ Show SnackBar dan pastikan di-dismiss setelah duration
        messenger.showSnackBar(snackBar);

        // ✅ Force dismiss setelah 10 detik (fallback jika auto-dismiss gagal)
        Future.delayed(const Duration(seconds: 10), () {
          if (context.mounted) {
            messenger.hideCurrentSnackBar();
          }
        });
      }
      return file.path;
    } catch (e) {
      if (context.mounted) {
        // ✅ Clear any existing SnackBar first
        final messenger = ScaffoldMessenger.of(context);
        messenger.clearSnackBars();

        messenger.showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan file: $e'),
            backgroundColor: AppTheme.danger,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.fixed,
          ),
        );
      }
      return null;
    }
  }

  static Future<File> _resolveWritableFilePath(String preferredPath) async {
    final preferred = File(preferredPath);
    if (!await preferred.exists()) {
      return preferred;
    }

    final ts = formatTimestamp(DateTime.now());
    final dot = preferredPath.lastIndexOf('.');
    final base = dot > 0 ? preferredPath.substring(0, dot) : preferredPath;
    final ext = dot > 0 ? preferredPath.substring(dot) : '';

      // coba nama bertimestamp dulu biar tidak bentrok
    final candidate = File('${base}_$ts$ext');
    if (!await candidate.exists()) {
      return candidate;
    }

      // fallback kalau timestamp masih bentrok
    final millis = DateTime.now().millisecondsSinceEpoch;
    return File('${base}_${ts}_$millis$ext');
  }

  static String _ensureTimestampedFilename(String filename) {
    final dot = filename.lastIndexOf('.');
    final base = dot > 0 ? filename.substring(0, dot) : filename;
    final ext = dot > 0 ? filename.substring(dot) : '';
    final hasTimestamp = RegExp(r'_\d{8}_\d{4,6}(\b|_)').hasMatch(base);
    if (hasTimestamp) {
      return filename;
    }
    return '${base}_${formatTimestamp()}$ext';
  }

  static Future<void> openExportFolder() async {
    final dir = await _resolveExportDirectory();
    final uri = Uri.file(dir.path);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // fallback windows kalau uri.file gagal
      if (Platform.isWindows) {
        await Process.run('explorer.exe', [dir.path]);
      }
    }
  }

  static Future<void> openFile(String path) async {
    // Untuk Android, gunakan FileProvider dengan content:// URI
    if (Platform.isAndroid) {
      try {
        // Untuk Android 14+, kita perlu menggunakan FileProvider
        // Uri.parse dengan content:// scheme
        // Format: content://{applicationId}.fileprovider/files/{relative_path}
        final fileName = path.split('/').last;
        final contentUri = 'content://com.expense.expense_app.fileprovider/files/$fileName';

        final uri = Uri.parse(contentUri);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (e) {
        debugPrint('Failed to open file with FileProvider: $e');
      }
      // Show user-friendly error for Android
      debugPrint('File saved at: $path (manual navigation required)');
      return;
    }

    // Untuk Windows atau fallback
    final uri = Uri.file(path);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    if (Platform.isWindows) {
      await Process.run('cmd', ['/c', 'start', '', path]);
    }
  }

  static String formatTimestamp([DateTime? dateTime]) {
    final now = dateTime ?? DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
  }

  /// Set custom export path for Windows (optional)
  static Future<void> setWindowsExportPath(String path) async {
    if (!Platform.isWindows) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, path);
      debugPrint('Windows export path set to: $path');
    } catch (e) {
      debugPrint('Failed to set Windows export path: $e');
    }
  }

  /// Get current export path
  static Future<String> getExportPath() async {
    if (Platform.isWindows) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final customPath = prefs.getString(_prefsKey);
        if (customPath != null && customPath.isNotEmpty) {
          return customPath;
        }
      } catch (_) {
        // Fallback to default if prefs fail
      }
      return _defaultWindowsExportPath;
    }

    final dir = await _resolveExportDirectory();
    return dir.path;
  }
}

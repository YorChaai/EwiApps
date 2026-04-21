import 'package:flutter/material.dart';

/// Extension methods for BuildContext to simplify theme and platform checks
extension ThemeContextExtension on BuildContext {
  /// Check if current theme is dark mode
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// Check if current theme is light mode
  bool get isLight => Theme.of(this).brightness == Brightness.light;

  /// Get current theme brightness
  Brightness get brightness => Theme.of(this).brightness;

  /// Check if platform is Android
  bool get isAndroid => Theme.of(this).platform == TargetPlatform.android;

  /// Check if platform is iOS
  bool get isIOS => Theme.of(this).platform == TargetPlatform.iOS;

  /// Check if platform is Windows
  bool get isWindows => Theme.of(this).platform == TargetPlatform.windows;

  /// Check if platform is desktop (Windows, macOS, Linux)
  bool get isDesktop => {
    TargetPlatform.windows,
    TargetPlatform.macOS,
    TargetPlatform.linux,
  }.contains(Theme.of(this).platform);

  /// Check if platform is mobile (Android, iOS)
  bool get isMobile => {
    TargetPlatform.android,
    TargetPlatform.iOS,
  }.contains(Theme.of(this).platform);
}

/// Extension methods for common color access
extension ColorContextExtension on BuildContext {
  /// Get surface color based on current theme
  Color get surfaceColor => Theme.of(this).scaffoldBackgroundColor;

  /// Get card color based on current theme
  Color get cardColor => Theme.of(this).cardTheme.color ?? Colors.transparent;

  /// Get primary color
  Color get primaryColor => Theme.of(this).primaryColor;

  /// Get text primary color
  Color get textPrimaryColor => Theme.of(this).textTheme.bodyLarge?.color ?? Colors.black;

  /// Get text secondary color
  Color get textSecondaryColor => Theme.of(this).textTheme.bodySmall?.color ?? Colors.grey;

  /// Get divider color
  Color get dividerColor => Theme.of(this).dividerColor;
}

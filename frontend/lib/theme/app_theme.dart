import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Constants untuk spacing/padding konsisten
class AppSpacing {
  static const double none = 0.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;

  /// Get adaptive spacing based on platform
  static double get adaptiveMd => (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) ? 10.0 : 12.0;
  static double get adaptiveLg => (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) ? 12.0 : 16.0;
}

/// Constants untuk border radius konsisten
class AppBorderRadius {
  static const double none = 0.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
}

/// Constants untuk font sizes konsisten
class AppFontSize {
  static const double xs = 10.0;
  static const double sm = 12.0;
  static const double md = 14.0;
  static const double lg = 16.0;
  static const double xl = 18.0;
  static const double xxl = 20.0;
  static const double xxxl = 24.0;

  /// Get adaptive font scale
  static double get fontScale => (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) ? 0.92 : 1.0;
}

class AppTheme {
  // palet gelap
  static const Color primary = Color(0xFF3B82F6); // biru terang
  static const Color primaryDark = Color(0xFF1D4ED8); // biru pekat
  static const Color accent = Color(0xFF60A5FA); // biru redup
  static const Color surface = Color(0xFF0F0F1A); // near-black
  static const Color card = Color(0xFF1A1A2E); // dark card
  static const Color cardHover = Color(0xFF22223A); // card hover
  static const Color cream = Color(0xFFF5F0E8); // cream text accent
  static const Color creamMuted = Color(0xFFD4C5A9); // muted cream
  static const Color textPrimary = Color(0xFFF1F1F1); // near-white
  static const Color textSecondary = Color(0xFF9CA3AF); // grey
  static const Color success = Color(0xFF10B981); // green
  static const Color danger = Color(0xFFEF4444); // red
  static const Color warning = Color(0xFFF59E0B); // amber
  static const Color divider = Color(0xFF2A2A3E);

  // palet terang
  static const Color lightSurface = Color(0xFFF8FAFC);
  static const Color lightCard = Colors.white;
  static const Color lightCardHover = Color(0xFFF1F5F9);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightDivider = Color(0xFF718096); // Abu-abu gelap agar garis kotak sangat jelas di mode terang

  /// Helper untuk cek mobile
  static bool get isMobile => defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;

  /// Helper method untuk mendapatkan warna berdasarkan brightness context
  static Color getSurfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? surface : lightSurface;
  }

  static Color getCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? card : lightCard;
  }

  static Color getTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? textPrimary : lightTextPrimary;
  }

  static Color getSecondaryTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? textSecondary : lightTextSecondary;
  }

  static Color getDividerColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? divider : lightDivider;
  }

  static Color getCreamColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? cream : lightTextPrimary;
  }

  static ThemeData get darkTheme {
    final bool mobile = isMobile;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      scaffoldBackgroundColor: surface,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: card,
        error: danger,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: mobile ? 18 : 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.all(mobile ? 8 : 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: divider, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: mobile ? 10 : 14,
        ),
        hintStyle: TextStyle(color: textSecondary, fontSize: mobile ? 13 : 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(
            horizontal: 24,
            vertical: mobile ? 10 : 14
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: TextStyle(
            fontSize: mobile ? 13 : 15,
            fontWeight: FontWeight.w600
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary),
          padding: EdgeInsets.symmetric(
            horizontal: 24,
            vertical: mobile ? 10 : 14
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: TextStyle(fontSize: mobile ? 13 : 14),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      dividerTheme: const DividerThemeData(color: divider, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: card,
        contentTextStyle: TextStyle(color: textPrimary, fontSize: mobile ? 13 : 14),
        actionTextColor: accent,
        showCloseIcon: true,
        closeIconColor: textPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbVisibility: WidgetStateProperty.all(true),
        trackVisibility: WidgetStateProperty.all(true),
        thickness: WidgetStateProperty.resolveWith((context) => 8),
        radius: const Radius.circular(8),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.dragged)) return accent;
          return textSecondary.withValues(alpha: 0.7);
        }),
        trackColor: WidgetStateProperty.all(divider.withValues(alpha: 0.2)),
        trackBorderColor: WidgetStateProperty.all(Colors.transparent),
        interactive: true,
      ),
    );
  }

  static ThemeData get lightTheme {
    final bool mobile = isMobile;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      scaffoldBackgroundColor: lightSurface,
      primaryColor: primary,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: accent,
        surface: lightCard,
        error: danger,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: lightTextPrimary,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.light().textTheme,
      ).apply(
        bodyColor: lightTextPrimary,
        displayColor: lightTextPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightSurface,
        foregroundColor: lightTextPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: mobile ? 18 : 20,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: lightCard,
        elevation: 0,
        margin: EdgeInsets.all(mobile ? 8 : 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: lightDivider, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: mobile ? 10 : 14
        ),
        hintStyle: TextStyle(color: lightTextSecondary, fontSize: mobile ? 13 : 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(
            horizontal: 24,
            vertical: mobile ? 10 : 14
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: TextStyle(
            fontSize: mobile ? 13 : 15,
            fontWeight: FontWeight.w600
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary),
          padding: EdgeInsets.symmetric(
            horizontal: 24,
            vertical: mobile ? 10 : 14
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: TextStyle(fontSize: mobile ? 13 : 14),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      dividerTheme: const DividerThemeData(color: lightDivider, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: lightCard,
        contentTextStyle: TextStyle(color: lightTextPrimary, fontSize: mobile ? 13 : 14),
        actionTextColor: primary,
        showCloseIcon: true,
        closeIconColor: lightTextPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbVisibility: WidgetStateProperty.all(true),
        trackVisibility: WidgetStateProperty.all(true),
        thickness: WidgetStateProperty.resolveWith((context) => 8),
        radius: const Radius.circular(8),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.dragged)) return primary;
          return lightTextSecondary.withValues(alpha: 0.6);
        }),
        trackColor: WidgetStateProperty.all(lightDivider.withValues(alpha: 0.15)),
        trackBorderColor: WidgetStateProperty.all(Colors.transparent),
        interactive: true,
      ),
    );
  }
}

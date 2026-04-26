import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/settlement_provider.dart';
import 'providers/advance_provider.dart';
import 'providers/revenue_provider.dart';
import 'providers/tax_provider.dart';
import 'providers/dividend_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/notification_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'theme/app_theme.dart';
import 'utils/app_snackbar.dart';
import 'widgets/app_scrollbar.dart';

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
    PointerDeviceKind.unknown,
  };

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // DISABLE scrollbar on mobile - tidak perlu scrollbar di Android/iOS
    // Scrollbar hanya untuk desktop/web
    if (kIsWeb) {
      // Keep scrollbar for web with proper controller
      return AppScrollbar(
        controller: details.controller,
        thumbVisibility: true,
        trackVisibility: true,
        interactive: true,
        child: child,
      );
    }
    return child;
  }
}

void main() {
  // Set error widget builder for better error handling
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: AppTheme.surface,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppTheme.danger,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Terjadi kesalahan pada aplikasi',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Silakan restart aplikasi atau hubungi support jika masalah berlanjut.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    // User can manually restart by closing and reopening app
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Restart Aplikasi'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  };

  runApp(const ExpenseApp());
}

class ExpenseApp extends StatelessWidget {
  const ExpenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
          create: (context) => NotificationProvider(context.read<AuthProvider>().api),
          update: (context, auth, prev) => prev ?? NotificationProvider(auth.api),
        ),
        ChangeNotifierProxyProvider<AuthProvider, SettlementProvider>(
          create: (context) => SettlementProvider(),
          update: (context, auth, prev) => prev!..updateToken(auth.token),
        ),
        ChangeNotifierProxyProvider<AuthProvider, AdvanceProvider>(
          create: (context) => AdvanceProvider(),
          update: (context, auth, prev) => prev!..updateToken(auth.token),
        ),
        ChangeNotifierProxyProvider<AuthProvider, RevenueProvider>(
          create: (context) =>
              RevenueProvider(context.read<AuthProvider>().api),
          update: (context, auth, prev) => prev ?? RevenueProvider(auth.api),
        ),
        ChangeNotifierProxyProvider<AuthProvider, TaxProvider>(
          create: (context) => TaxProvider(context.read<AuthProvider>().api),
          update: (context, auth, prev) => prev ?? TaxProvider(auth.api),
        ),
        ChangeNotifierProxyProvider<AuthProvider, DividendProvider>(
          create: (context) =>
              DividendProvider(context.read<AuthProvider>().api),
          update: (context, auth, prev) => prev ?? DividendProvider(auth.api),
        ),
      ],
      child: Consumer2<AuthProvider, ThemeProvider>(
        builder: (context, auth, themeProvider, _) {
          return MaterialApp(
            title: 'ExspanApp',
            debugShowCheckedModeBanner: false,
            scaffoldMessengerKey: rootScaffoldMessengerKey,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            scrollBehavior: MyCustomScrollBehavior(),
            home: auth.isLoggedIn ? DashboardScreen() : LoginScreen(),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Responsive helpers yang lebih aman untuk Android phone, tablet,
/// landscape rotation, split-screen, dan desktop.
///
/// Tujuan utama:
/// - mencegah layout pecah saat rotate
/// - memberi breakpoint yang lebih stabil
/// - memudahkan penentuan spacing/padding adaptif
/// - menjaga phone landscape tetap diperlakukan sebagai mobile
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  static const double compactPhoneBreakpoint = 360;
  static const double mobileBreakpoint = 800; // HP landscape ~792px masih mobile
  static const double tabletBreakpoint = 1000; // Tablet baru muncul di > 1000px
  static const double desktopBreakpoint = 1400;

  static MediaQueryData mq(BuildContext context) => MediaQuery.of(context);

  static Size screenSize(BuildContext context) => mq(context).size;

  static double width(BuildContext context) => screenSize(context).width;

  static double height(BuildContext context) => screenSize(context).height;

  static Orientation orientation(BuildContext context) => mq(context).orientation;

  static bool isPortrait(BuildContext context) =>
      orientation(context) == Orientation.portrait;

  static bool isLandscape(BuildContext context) =>
      orientation(context) == Orientation.landscape;

  static bool isCompactPhone(BuildContext context) =>
      width(context) < compactPhoneBreakpoint;

  static bool isMobile(BuildContext context) =>
      width(context) < mobileBreakpoint;

  static bool isTablet(BuildContext context) =>
      width(context) >= mobileBreakpoint && width(context) < tabletBreakpoint;

  static bool isDesktop(BuildContext context) =>
      width(context) >= tabletBreakpoint;

  /// Phone yang di-rotate landscape tetap dianggap mobile
  /// supaya tidak dipaksa layout tablet/desktop.
  static bool isPhoneLandscape(BuildContext context) =>
      isMobile(context) && isLandscape(context);

  /// Wide layout aman untuk tablet dan desktop,
  /// tapi tidak untuk phone landscape.
  static bool isWide(BuildContext context) =>
      !isPhoneLandscape(context) && width(context) >= mobileBreakpoint;

  static bool isShortHeight(BuildContext context) => height(context) < 700;

  static bool isVeryShortHeight(BuildContext context) => height(context) < 560;

  static double safeWidth(BuildContext context) {
    final data = mq(context);
    return data.size.width - data.padding.left - data.padding.right;
  }

  static double safeHeight(BuildContext context) {
    final data = mq(context);
    return data.size.height -
        data.padding.top -
        data.padding.bottom -
        data.viewInsets.bottom;
  }

  static double horizontalPadding(BuildContext context) {
    final w = safeWidth(context);

    if (w >= 1400) return 36;
    if (w >= 1100) return 28;
    if (w >= 700) return 24;
    if (w >= 390) return 18;
    if (w >= 360) return 16;
    return 12;
  }

  static double verticalPadding(BuildContext context) {
    if (isDesktop(context)) return 24;
    if (isTablet(context)) return 20;
    if (isVeryShortHeight(context)) return 10;
    if (isShortHeight(context)) return 12;
    return 16;
  }

  static double gapXS(BuildContext context) {
    if (isCompactPhone(context)) return 4;
    return 6;
  }

  static double gapS(BuildContext context) {
    if (isCompactPhone(context)) return 8;
    if (isVeryShortHeight(context)) return 8;
    return 10;
  }

  static double gapM(BuildContext context) {
    if (isCompactPhone(context)) return 12;
    if (isVeryShortHeight(context)) return 12;
    return 16;
  }

  static double gapL(BuildContext context) {
    if (isCompactPhone(context)) return 16;
    if (isVeryShortHeight(context)) return 16;
    return 20;
  }

  static double sidePanelWidth(BuildContext context) {
    if (isDesktop(context)) return 240;
    if (isTablet(context)) return 88;
    return 0;
  }

  static int adaptiveColumns(
    BuildContext context, {
    int mobile = 1,
    int phoneLandscape = 2,
    int tablet = 2,
    int desktop = 3,
  }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    if (isPhoneLandscape(context)) return phoneLandscape;
    return mobile;
  }

  static double adaptiveChildAspectRatio(
    BuildContext context, {
    double mobile = 1.0,
    double phoneLandscape = 1.35,
    double tablet = 1.25,
    double desktop = 1.3,
  }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    if (isPhoneLandscape(context)) return phoneLandscape;
    return mobile;
  }

  static double headingSize(
    BuildContext context, {
    double mobile = 20,
    double tablet = 22,
    double desktop = 24,
  }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    return mobile;
  }

  static double bodySize(
    BuildContext context, {
    double mobile = 13,
    double tablet = 14,
    double desktop = 14,
  }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    return mobile;
  }

  static EdgeInsets pagePadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: horizontalPadding(context),
      vertical: verticalPadding(context),
    );
  }

  static bool shouldUseCompactControls(BuildContext context) {
    return isCompactPhone(context) || isVeryShortHeight(context);
  }

  static bool shouldStackHeaderActions(BuildContext context) {
    // Stack header actions untuk layar sangat sempit (HP portrait kecil atau landscape)
    return safeWidth(context) < 700;
  }

  /// Deteksi layar sangat sempit untuk penyesuaian elemen UI
  static bool isVeryNarrow(BuildContext context) => width(context) < 450;

  /// Deteksi layar ekstra sempit untuk penyesuaian ekstrem
  static bool isExtraNarrow(BuildContext context) => width(context) < 380;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final phoneLandscape = isPhoneLandscape(context);

        if (w >= tabletBreakpoint && !phoneLandscape) {
          return desktop;
        }

        if (w >= mobileBreakpoint && !phoneLandscape) {
          return tablet ?? desktop;
        }

        return mobile;
      },
    );
  }
}

/// Wrapper halaman agar konten tidak terlalu melebar dan aman di HP Android.
class ResponsivePage extends StatelessWidget {
  final Widget child;
  final bool centerContent;
  final double? maxWidth;
  final EdgeInsets? padding;
  final bool useSafeArea;

  const ResponsivePage({
    super.key,
    required this.child,
    this.centerContent = true,
    this.maxWidth,
    this.padding,
    this.useSafeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding ?? ResponsiveLayout.pagePadding(context),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ??
              (ResponsiveLayout.isDesktop(context) ? 1280 : double.infinity),
        ),
        child: child,
      ),
    );

    final body = centerContent
        ? Align(
            alignment: Alignment.topCenter,
            child: content,
          )
        : content;

    return useSafeArea ? SafeArea(child: body) : body;
  }
}

/// Scroll wrapper yang aman untuk keyboard, rotate, dan layar pendek.
class ResponsiveScrollView extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final ScrollController? controller;
  final bool dismissKeyboardOnDrag;

  const ResponsiveScrollView({
    super.key,
    required this.child,
    this.padding,
    this.controller,
    this.dismissKeyboardOnDrag = true,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SingleChildScrollView(
      controller: controller,
      keyboardDismissBehavior: dismissKeyboardOnDrag
          ? ScrollViewKeyboardDismissBehavior.onDrag
          : ScrollViewKeyboardDismissBehavior.manual,
      padding: padding ??
          EdgeInsets.only(
            left: ResponsiveLayout.horizontalPadding(context),
            right: ResponsiveLayout.horizontalPadding(context),
            top: ResponsiveLayout.verticalPadding(context),
            bottom: ResponsiveLayout.verticalPadding(context) + bottomInset,
          ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: ResponsiveLayout.safeHeight(context) - 24,
        ),
        child: child,
      ),
    );
  }
}

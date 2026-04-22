import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_brand_logo.dart';
import '../../widgets/notification_bell_icon.dart';
import '../../utils/responsive_layout.dart';
import '../../utils/context_extensions.dart';

class DashboardSidebar extends StatelessWidget {
  final int currentIndex;
  final bool isManager;
  final String fullName;
  final String role;
  final String? profileImageUrl;
  final ValueChanged<int> onNavTap;
  final VoidCallback onLogout;
  final bool isMini;
  final bool isExpanded;
  final VoidCallback? onToggleExpand;
  final int pendingSettlements;
  final int pendingAdvances;
  final ValueChanged<String>? onNotificationTap;

  const DashboardSidebar({
    super.key,
    required this.currentIndex,
    required this.isManager,
    required this.fullName,
    required this.role,
    this.profileImageUrl,
    required this.onNavTap,
    required this.onLogout,
    this.isMini = false,
    this.isExpanded = true,
    this.onToggleExpand,
    this.pendingSettlements = 0,
    this.pendingAdvances = 0,
    this.onNotificationTap,
  });

  bool get _showFull => !isMini && isExpanded;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final panelColor = isDark ? AppTheme.card : AppTheme.lightCard;
    final dividerColor = isDark ? AppTheme.divider : AppTheme.lightDivider;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      width: _showFull ? 240 : 80,
      decoration: BoxDecoration(
        color: panelColor,
        border: Border(right: BorderSide(color: dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),

          // ===== toggle button =====
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: _showFull
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                _SquareIconBtn(
                  icon: _showFull
                      ? Icons.menu_open_rounded
                      : Icons.menu_rounded,
                  tooltip: _showFull
                      ? 'Sembunyikan sidebar'
                      : 'Tampilkan sidebar',
                  onTap: onToggleExpand,
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ===== brand / logo =====
          _showFull
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AppBrandLogo(size: 30, padding: 5),
                        const SizedBox(width: 12),
                        if (_showFull)
                          const Expanded(
                            child: Text(
                              'ExspanApp',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                )
              : Center(
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: AppBrandLogo(size: 34, padding: 5),
                    ),
                  ),
                ),

          const SizedBox(height: 16),
          Divider(height: 1, color: dividerColor),
          const SizedBox(height: 10),

          // ===== nav items (scrollable) =====
          Expanded(
            child: SingleChildScrollView(
              child: ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  _SidebarNavItem(
                    icon: Icons.dashboard_rounded,
                    label: 'Settlements',
                    subtitle: 'Daftar pengajuan',
                    selected: currentIndex == 0,
                    onTap: () => onNavTap(0),
                    expanded: _showFull,
                    badge: pendingSettlements,
                  ),
                  _SidebarNavItem(
                    icon: Icons.money_rounded,
                    label: 'Kasbon',
                    subtitle: 'Pengajuan uang muka',
                    selected: currentIndex == 1,
                    onTap: () => onNavTap(1),
                    expanded: _showFull,
                    badge: pendingAdvances,
                  ),
                  if (isManager) ...[
                    _SidebarNavItem(
                      icon: Icons.bar_chart_rounded,
                      label: 'Laporan',
                      subtitle: 'Ringkasan & export',
                      selected: currentIndex == 2,
                      onTap: () => onNavTap(2),
                      expanded: _showFull,
                    ),
                    _SidebarNavItem(
                      icon: Icons.category_rounded,
                      label: 'Kategori',
                      subtitle: 'Kelola kategori biaya',
                      selected: currentIndex == 3,
                      onTap: () => onNavTap(3),
                      expanded: _showFull,
                    ),
                  ],
                  // Settings untuk semua role
                  _SidebarNavItem(
                    icon: Icons.settings_rounded,
                    label: 'Pengaturan',
                    subtitle: 'Konfigurasi aplikasi',
                    selected: currentIndex == (isManager ? 4 : 2),
                    onTap: () => onNavTap(isManager ? 4 : 2),
                    expanded: _showFull,
                  ),
                ],
              ),
            ),
          ),

          // ===== user panel =====
          Divider(height: 1, color: dividerColor),
          _showFull
              ? _ExpandedUserPanel(
                  fullName: fullName,
                  role: role,
                  profileImageUrl: profileImageUrl,
                  isManager: isManager,
                  onLogout: onLogout,
                  onNotificationTap: onNotificationTap,
                )
              : _MiniUserPanel(
                  fullName: fullName,
                  isManager: isManager,
                  role: role,
                  profileImageUrl: profileImageUrl,
                  onLogout: onLogout,
                  onNotificationTap: onNotificationTap,
                ),
        ],
      ),
    );
  }
}

// ============================================================
// NAV ITEM
// ============================================================
class _SidebarNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final bool expanded;
  final int badge;

  const _SidebarNavItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    required this.expanded,
    this.badge = 0,
  });

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final hoverColor = isDark ? AppTheme.cardHover : AppTheme.lightCardHover;
    final textSecondary = isDark
        ? AppTheme.textSecondary
        : AppTheme.lightTextSecondary;
    final textPrimary = isDark
        ? AppTheme.textPrimary
        : AppTheme.lightTextPrimary;
    final surfaceColor = isDark ? AppTheme.surface : AppTheme.lightSurface;

    // Responsive sizing untuk HP
    final isCompact = ResponsiveLayout.isCompactPhone(context);
    final iconBoxSize = widget.expanded
        ? (isCompact ? 36.0 : 40.0)
        : (isCompact ? 42.0 : 48.0);
    final iconSize = isCompact ? 18.0 : (widget.expanded ? 20.0 : 22.0);
    final labelFontSize = isCompact ? 12.5 : 13.5;
    final subtitleFontSize = isCompact ? 10.0 : 11.0;
    final horizontalPadding = isCompact ? 8.0 : 12.0;
    final verticalPadding = widget.expanded
        ? (isCompact ? 9.0 : 11.0)
        : (isCompact ? 8.0 : 10.0);

    final bgColor = widget.selected
        ? AppTheme.primary.withValues(alpha: 0.14)
        : _hovering
        ? hoverColor
        : Colors.transparent;

    // Use shorter duration for hover exit to feel instant
    final duration = _hovering
        ? const Duration(milliseconds: 150)
        : const Duration(milliseconds: 0);

    final iconColor = widget.selected ? AppTheme.primary : textSecondary;
    final textColor = widget.selected ? textPrimary : textSecondary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2), // The 'hold' effect gap
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(isCompact ? 10 : 14),
            onTap: widget.onTap,
            hoverColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: AnimatedContainer(
              duration: duration,
              curve: Curves.easeOut,
              padding: EdgeInsets.symmetric(
                horizontal: widget.expanded ? horizontalPadding : 0,
                vertical: verticalPadding,
              ),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(isCompact ? 10 : 14),
                border: Border.all(
                  color: widget.selected
                      ? AppTheme.primary.withValues(alpha: 0.25)
                      : Colors.transparent,
                ),
              ),
              child: widget.expanded
                  ? Row(
                      children: [
                        // icon box
                        Container(
                          width: iconBoxSize,
                          height: iconBoxSize,
                          decoration: BoxDecoration(
                            color: widget.selected
                                ? AppTheme.primary.withValues(alpha: 0.14)
                                : surfaceColor,
                            borderRadius: BorderRadius.circular(isCompact ? 10 : 12),
                          ),
                          child: Icon(widget.icon, color: iconColor, size: iconSize),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: labelFontSize,
                                  fontWeight: widget.selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: subtitleFontSize,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.badge > 0) ...[
                          const SizedBox(width: 6),
                          _BadgePill(count: widget.badge, isCompact: isCompact),
                        ],
                      ],
                    )
                  : Center(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: iconBoxSize,
                            height: iconBoxSize,
                            decoration: BoxDecoration(
                              color: widget.selected
                                  ? AppTheme.primary.withValues(alpha: 0.14)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(isCompact ? 12 : 14),
                            ),
                            child: Icon(widget.icon, color: iconColor, size: iconSize),
                          ),
                          if (widget.badge > 0)
                            Positioned(top: -2, right: -2, child: _BadgeDot()),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// USER PANEL — EXPANDED
// ============================================================
class _ExpandedUserPanel extends StatelessWidget {
  final String fullName;
  final String role;
  final String? profileImageUrl;
  final bool isManager;
  final VoidCallback onLogout;
  final ValueChanged<String>? onNotificationTap;

  const _ExpandedUserPanel({
    required this.fullName,
    required this.role,
    this.profileImageUrl,
    required this.isManager,
    required this.onLogout,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final surfaceColor = isDark ? AppTheme.surface : AppTheme.lightSurface;
    final dividerColor = isDark ? AppTheme.divider : AppTheme.lightDivider;
    final textPrimary = isDark
        ? AppTheme.textPrimary
        : AppTheme.lightTextPrimary;
    final textSecondary = isDark
        ? AppTheme.textSecondary
        : AppTheme.lightTextSecondary;

    return Column(
      children: [
        // Notification Bell
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: NotificationBellIcon(onNotificationTap: onNotificationTap),
        ),
        Divider(height: 1, thickness: 1, color: dividerColor),
        // User Profile
        Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: dividerColor),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.18),
                backgroundImage: profileImageUrl != null
                    ? NetworkImage(profileImageUrl!)
                    : null,
                child: profileImageUrl == null
                    ? Text(
                        fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      role.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.accent,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.logout_rounded,
                  size: 18,
                  color: textSecondary,
                ),
                onPressed: onLogout,
                tooltip: 'Logout',
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// USER PANEL — MINI
// ============================================================
class _MiniUserPanel extends StatelessWidget {
  final String fullName;
  final String role;
  final String? profileImageUrl;
  final bool isManager;
  final VoidCallback onLogout;
  final ValueChanged<String>? onNotificationTap;

  const _MiniUserPanel({
    required this.fullName,
    required this.role,
    this.profileImageUrl,
    required this.isManager,
    required this.onLogout,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
      child: Column(
        children: [
          NotificationBellIcon(onNotificationTap: onNotificationTap),
          const SizedBox(height: 8),
          Tooltip(
            message: fullName,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.primary.withValues(alpha: 0.18),
              backgroundImage: profileImageUrl != null
                  ? NetworkImage(profileImageUrl!)
                  : null,
              child: profileImageUrl == null
                  ? Text(
                      fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Tooltip(
            message: 'Logout',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onLogout,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: AppTheme.danger,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// BADGE
// ============================================================
class _BadgePill extends StatelessWidget {
  final int count;
  final bool isCompact;

  const _BadgePill({required this.count, this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    final paddingHorizontal = isCompact ? 5.0 : 7.0;
    final paddingVertical = isCompact ? 2.0 : 3.0;
    final fontSize = isCompact ? 9.0 : 10.0;
    final borderRadius = isCompact ? 8.0 : 10.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: paddingHorizontal,
        vertical: paddingVertical,
      ),
      decoration: BoxDecoration(
        color: Colors.redAccent,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BadgeDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final panelColor = isDark ? AppTheme.card : AppTheme.lightCard;
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: Colors.redAccent,
        shape: BoxShape.circle,
        border: Border.all(color: panelColor, width: 1.5),
      ),
    );
  }
}

// ============================================================
// SQUARE ICON BUTTON (toggle)
// ============================================================
class _SquareIconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _SquareIconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final surfaceColor = isDark ? AppTheme.surface : AppTheme.lightSurface;
    final dividerColor = isDark ? AppTheme.divider : AppTheme.lightDivider;
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;

    // Responsive button size untuk HP
    final isCompact = ResponsiveLayout.isCompactPhone(context);
    final btnSize = isCompact ? 36.0 : 42.0;
    final iconSize = isCompact ? 18.0 : 20.0;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: btnSize,
            height: btnSize,
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: dividerColor),
            ),
            child: Icon(icon, color: textColor, size: iconSize),
          ),
        ),
      ),
    );
  }
}

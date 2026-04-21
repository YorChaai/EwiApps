import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/context_extensions.dart';

class PageSelector extends StatelessWidget {
  final int currentIndex;
  final bool isManager;
  final ValueChanged<int> onChanged;
  final bool compact;

  const PageSelector({
    super.key,
    required this.currentIndex,
    required this.isManager,
    required this.onChanged,
    this.compact = false,
  });

  String _getPageName(int index) {
    if (index == 0) return 'Settlements';
    if (index == 1) return 'Kasbon';
    if (isManager) {
      if (index == 2) return 'Laporan';
      if (index == 3) return 'Kategori';
      if (index == 4) return 'Pengaturan';
    } else {
      if (index == 2) return 'Pengaturan';
    }
    return 'ExspanApp';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final cardColor = isDark ? AppTheme.card : AppTheme.lightCard;
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final subTextColor =
        isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return PopupMenuButton<int>(
      tooltip: 'Pilih halaman',
      offset: compact ? const Offset(0, 38) : const Offset(0, 40),
      color: cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: onChanged,
      child: compact
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.35),
                ),
              ),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: AppTheme.primary,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    isManager ? 'M' : 'S',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _getPageName(currentIndex),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: subTextColor,
                ),
              ],
            ),
      itemBuilder: (context) => [
        _buildItem(
          value: 0,
          label: 'Settlements',
          icon: Icons.dashboard_rounded,
          isSelected: currentIndex == 0,
          textColor: textColor,
          subTextColor: subTextColor,
        ),
        _buildItem(
          value: 1,
          label: 'Kasbon',
          icon: Icons.money_rounded,
          isSelected: currentIndex == 1,
          textColor: textColor,
          subTextColor: subTextColor,
        ),
        if (isManager)
          _buildItem(
            value: 2,
            label: 'Laporan',
            icon: Icons.bar_chart_rounded,
            isSelected: currentIndex == 2,
            textColor: textColor,
            subTextColor: subTextColor,
          ),
        if (isManager)
          _buildItem(
            value: 3,
            label: 'Kategori',
            icon: Icons.category_rounded,
            isSelected: currentIndex == 3,
            textColor: textColor,
            subTextColor: subTextColor,
          ),
        // Settings untuk semua role - index disesuaikan
        if (isManager)
          _buildItem(
            value: 4,
            label: 'Pengaturan',
            icon: Icons.settings_rounded,
            isSelected: currentIndex == 4,
            textColor: textColor,
            subTextColor: subTextColor,
          )
        else
          _buildItem(
            value: 2,
            label: 'Pengaturan',
            icon: Icons.settings_rounded,
            isSelected: currentIndex == 2,
            textColor: textColor,
            subTextColor: subTextColor,
          ),
      ],
    );
  }

  PopupMenuItem<int> _buildItem({
    required int value,
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color textColor,
    required Color subTextColor,
  }) {
    return PopupMenuItem<int>(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? AppTheme.primary : subTextColor,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppTheme.primary : textColor,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

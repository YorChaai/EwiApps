import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_layout.dart';
import '../../utils/context_extensions.dart';
import '../../widgets/user_detail_dialog.dart';

String formatNumber(dynamic num) {
  if (num == null) return '0';
  final n = num is int ? num.toDouble() : (num as double);
  return n
      .toStringAsFixed(0)
      .replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      );
}

class StatusFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isMobile;
  final VoidCallback onTap;

  const StatusFilterChip({
    super.key,
    required this.label,
    required this.selected,
    this.isMobile = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final borderColor = isDark ? AppTheme.divider : AppTheme.lightDivider;
    final textColor = isDark
        ? AppTheme.textSecondary
        : AppTheme.lightTextSecondary;

    // Responsive sizing
    final isCompact = isMobile || ResponsiveLayout.isCompactPhone(context);
    final horizontalPadding = isCompact ? 10.0 : 14.0;
    final verticalPadding = isCompact ? 6.0 : 8.0;
    final fontSize = isCompact ? 11.5 : 13.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? AppTheme.primary : borderColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? AppTheme.primary : textColor,
          ),
        ),
      ),
    );
  }
}
class SettlementCard extends StatefulWidget {
  final Map<String, dynamic> settlement;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final bool isManager;
  final bool selectionMode;
  final bool selected;
  final ValueChanged<bool>? onSelectionChanged;
  final bool canSelect;

  const SettlementCard({
    super.key,
    required this.settlement,
    required this.onTap,
    this.onDelete,
    this.isManager = false,
    this.selectionMode = false,
    this.selected = false,
    this.onSelectionChanged,
    this.canSelect = false,
  });

  @override
  State<SettlementCard> createState() => _SettlementCardState();
}

class _SettlementCardState extends State<SettlementCard> {
  bool _hovering = false;
  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
  Color _cardColor(BuildContext context) =>
      _isDark(context) ? AppTheme.card : AppTheme.lightCard;
  Color _hoverColor(BuildContext context) =>
      _isDark(context) ? AppTheme.cardHover : AppTheme.lightCardHover;
  Color _dividerColor(BuildContext context) =>
      _isDark(context) ? AppTheme.divider : AppTheme.lightDivider;
  Color _titleColor(BuildContext context) =>
      _isDark(context) ? AppTheme.cream : AppTheme.lightTextPrimary;
  Color _primaryText(BuildContext context) =>
      _isDark(context) ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
  Color _bodyText(BuildContext context) =>
      _isDark(context) ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

  String _getDisplayTitle(Map<String, dynamic> s) {
    final type = (s['settlement_type'] ?? 'single').toString().toLowerCase();
    final title = s['title'] ?? '';

    if (type == 'single') {
      final firstDesc = s['first_expense_description'] as String?;
      if (firstDesc != null && firstDesc.isNotEmpty) return firstDesc;

      final expenses = s['expenses'] as List? ?? [];
      if (expenses.isNotEmpty) {
        final firstExp = Map<String, dynamic>.from(expenses.first);
        final desc = firstExp['description'] as String?;
        if (desc != null && desc.isNotEmpty) return desc;
      }
    }
    return title.isEmpty ? 'Settlement' : title;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'draft': return AppTheme.textSecondary;
      case 'submitted': return AppTheme.warning;
      case 'completed':
      case 'approved': return AppTheme.success;
      case 'rejected': return AppTheme.danger;
      default: return _bodyText(context);
    }
  }

  bool _isSettlementApproved(String status) {
    final normalized = status.toLowerCase();
    return normalized == 'approved' || normalized == 'completed';
  }

  Color _advanceWalletColor(String status) {
    return _isSettlementApproved(status) ? AppTheme.success : AppTheme.danger;
  }

  String _getRoleName(String? role) {
    switch (role) {
      case 'manager': return 'Manager';
      case 'staff': return 'Staff';
      case 'mitra_eks': return 'Mitra';
      case 'unknown': return 'User dihapus';
      default: return role ?? '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.settlement;
    final status = (s['status'] ?? 'draft').toString();
    final rejectedCount = s['rejected_count'] as int? ?? 0;

    Color statusColor = _statusColor(status);
    String displayStatus = status;

    if (rejectedCount > 0 &&
        status != 'rejected' &&
        status != 'approved' &&
        status != 'completed') {
      statusColor = AppTheme.warning;
      displayStatus = 'revision';
    }

    final walletColor = _advanceWalletColor(status);
    final isMobile = ResponsiveLayout.isMobile(context);
    final supportsHover = !isMobile;

    return MouseRegion(
      onEnter: supportsHover ? (_) => setState(() => _hovering = true) : null,
      onExit: supportsHover ? (_) => setState(() => _hovering = false) : null,
      child: GestureDetector(
        onTap: widget.selectionMode
            ? (widget.canSelect
                  ? () => widget.onSelectionChanged?.call(!widget.selected)
                  : null)
            : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          decoration: BoxDecoration(
            color: supportsHover && _hovering
                ? _hoverColor(context)
                : _cardColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: supportsHover && _hovering
                  ? AppTheme.primary.withValues(alpha: 0.3)
                  : _dividerColor(context),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isVeryNarrow = constraints.maxWidth < 300;

              return Row(
                children: [
                  Container(
                    width: 4,
                    height: isMobile ? 32 : 40,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(width: isMobile ? 10 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                _getDisplayTitle(s),
                                style: TextStyle(
                                  fontSize: isMobile ? 14 : 15,
                                  fontWeight: FontWeight.w600,
                                  color: _titleColor(context),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!isVeryNarrow) ...[
                              const SizedBox(width: 8),
                              if (s['advance_id'] != null && s['advance_id'] != 0)
                                Container(
                                  margin: const EdgeInsets.only(right: 4),
                                  padding: EdgeInsets.all(isMobile ? 3 : 4),
                                  decoration: BoxDecoration(
                                    color: walletColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Icon(
                                    Icons.account_balance_wallet_rounded,
                                    size: isMobile ? 14 : 16,
                                    color: walletColor,
                                  ),
                                ),
                              Text(
                                'Rp ${formatNumber(s['total_amount'] ?? 0)}',
                                style: TextStyle(
                                  fontSize: isMobile ? 14 : 15,
                                  fontWeight: FontWeight.w700,
                                  color: _primaryText(context),
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: isMobile ? 4 : 6),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${_getRoleName(s['creator_role'])} • ${s['expense_count'] ?? 0} item',
                                style: TextStyle(
                                  fontSize: isMobile ? 11 : 12,
                                  color: _bodyText(context),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            StatusBadge(
                              status: displayStatus,
                              color: statusColor,
                              isMobile: isMobile,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                final creatorId = s['creator_id'];
                                if (creatorId != null) {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => UserDetailDialog(userId: creatorId),
                                  );
                                }
                              },
                              child: Text(
                                s['creator_name'] ?? '-',
                                style: TextStyle(
                                  fontSize: isMobile ? 11 : 12,
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppTheme.primary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (widget.selectionMode)
                    IgnorePointer(
                      ignoring: !widget.canSelect,
                      child: Opacity(
                        opacity: widget.canSelect ? 1 : 0.45,
                        child: Checkbox(
                          value: widget.selected,
                          onChanged: (value) => widget.onSelectionChanged?.call(value ?? false),
                          activeColor: AppTheme.primary,
                          side: BorderSide(color: _dividerColor(context)),
                        ),
                      ),
                    )
                  else ...[
                    if (widget.onDelete != null &&
                        ((widget.isManager && !['approved', 'completed'].contains(status)) ||
                            (!widget.isManager && status == 'draft')))
                      IconButton(
                        onPressed: widget.onDelete,
                        icon: Icon(Icons.delete_outline, size: isMobile ? 18 : 20, color: AppTheme.danger),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Hapus Settlement',
                      ),
                    Icon(Icons.chevron_right_rounded, size: isMobile ? 18 : 20, color: _bodyText(context)),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class AdvanceCard extends StatefulWidget {
  final Map<String, dynamic> advance;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final bool isManager;
  final bool selectionMode;
  final bool selected;
  final ValueChanged<bool>? onSelectionChanged;
  final bool canSelect;

  const AdvanceCard({
    super.key,
    required this.advance,
    required this.onTap,
    this.onDelete,
    this.isManager = false,
    this.selectionMode = false,
    this.selected = false,
    this.onSelectionChanged,
    this.canSelect = false,
  });

  @override
  State<AdvanceCard> createState() => _AdvanceCardState();
}

class _AdvanceCardState extends State<AdvanceCard> {
  bool _hovering = false;
  Color _cardColor(BuildContext context) =>
      context.isDark ? AppTheme.card : AppTheme.lightCard;
  Color _hoverColor(BuildContext context) =>
      context.isDark ? AppTheme.cardHover : AppTheme.lightCardHover;
  Color _dividerColor(BuildContext context) =>
      context.isDark ? AppTheme.divider : AppTheme.lightDivider;
  Color _titleColor(BuildContext context) =>
      context.isDark ? AppTheme.cream : AppTheme.lightTextPrimary;
  Color _primaryText(BuildContext context) =>
      context.isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
  Color _bodyText(BuildContext context) =>
      context.isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

  Color _advanceStatusColor(Map<String, dynamic> advance) {
    final status = (advance['status'] ?? 'draft').toString().toLowerCase();
    if (status == 'in_settlement') {
      final settlementStatus = (advance['settlement_status'] ?? '').toString().toLowerCase();
      final isSettlementApproved = settlementStatus == 'approved' || settlementStatus == 'completed';
      return isSettlementApproved ? AppTheme.success : AppTheme.danger;
    }
    return _statusColor(status);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'draft': return AppTheme.textSecondary;
      case 'submitted': return AppTheme.warning;
      case 'approved': return AppTheme.success;
      case 'revision_draft': return AppTheme.accent;
      case 'revision_submitted': return AppTheme.warning;
      case 'revision_rejected': return AppTheme.danger;
      case 'in_settlement':
      case 'settled':
      case 'completed': return AppTheme.primary;
      case 'rejected': return AppTheme.danger;
      default: return _bodyText(context);
    }
  }

  String _getRoleName(String? role) {
    switch (role) {
      case 'manager': return 'Manager';
      case 'staff': return 'Staff';
      case 'mitra_eks': return 'Mitra';
      case 'unknown': return 'User dihapus';
      default: return role ?? '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.advance;
    final status = (a['status'] ?? 'draft').toString().toLowerCase();
    final rejectedCount = a['rejected_count'] as int? ?? 0;

    Color statusColor = _advanceStatusColor(a);
    String displayStatus = status;

    if (rejectedCount > 0 &&
        status != 'rejected' &&
        status != 'revision_rejected' &&
        status != 'approved' &&
        status != 'in_settlement') {
      statusColor = AppTheme.warning;
      displayStatus = 'revision';
    }

    final isMobile = ResponsiveLayout.isMobile(context);
    final supportsHover = !isMobile;
    final type = (a['advance_type'] ?? 'single').toString().toLowerCase();
    final displayTitle = type == 'single'
        ? (a['first_item_description']?.toString() ?? (a['title'] ?? 'Kasbon Mandiri').toString())
        : (a['title'] ?? '').toString();

    return MouseRegion(
      onEnter: supportsHover ? (_) => setState(() => _hovering = true) : null,
      onExit: supportsHover ? (_) => setState(() => _hovering = false) : null,
      child: GestureDetector(
        onTap: widget.selectionMode
            ? (widget.canSelect
                ? () => widget.onSelectionChanged?.call(!widget.selected)
                : null)
            : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          decoration: BoxDecoration(
            color: supportsHover && _hovering
                ? _hoverColor(context)
                : _cardColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: supportsHover && _hovering
                  ? AppTheme.primary.withValues(alpha: 0.3)
                  : _dividerColor(context),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isVeryNarrow = constraints.maxWidth < 300;

              return Row(
                children: [
                  Container(
                    width: 4,
                    height: isMobile ? 32 : 40,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(width: isMobile ? 10 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                displayTitle,
                                style: TextStyle(
                                  fontSize: isMobile ? 14 : 15,
                                  fontWeight: FontWeight.w600,
                                  color: _titleColor(context),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!isVeryNarrow) ...[
                              const SizedBox(width: 8),
                              Text(
                                'Rp ${formatNumber(a['total_amount'] ?? 0)}',
                                style: TextStyle(
                                  fontSize: isMobile ? 14 : 15,
                                  fontWeight: FontWeight.w700,
                                  color: _primaryText(context),
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: isMobile ? 4 : 6),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${_getRoleName(a['requester_role'])} • ${a['item_count'] ?? 0} item',
                                style: TextStyle(
                                  fontSize: isMobile ? 11 : 12,
                                  color: _bodyText(context),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            StatusBadge(
                              status: displayStatus,
                              color: statusColor,
                              isMobile: isMobile,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                final creatorId = a['requester_id'];
                                if (creatorId != null) {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => UserDetailDialog(userId: creatorId),
                                  );
                                }
                              },
                              child: Text(
                                a['requester_name'] ?? '-',
                                style: TextStyle(
                                  fontSize: isMobile ? 11 : 12,
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppTheme.primary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (widget.selectionMode)
                    IgnorePointer(
                      ignoring: !widget.canSelect,
                      child: Opacity(
                        opacity: widget.canSelect ? 1 : 0.45,
                        child: Checkbox(
                          value: widget.selected,
                          onChanged: (value) => widget.onSelectionChanged?.call(value ?? false),
                          activeColor: AppTheme.primary,
                          side: BorderSide(color: _dividerColor(context)),
                        ),
                      ),
                    )
                  else ...[
                    if (widget.onDelete != null &&
                        ((widget.isManager && !['approved', 'in_settlement', 'settled', 'completed'].contains(status)) ||
                            (!widget.isManager && status == 'draft')))
                      IconButton(
                        onPressed: widget.onDelete,
                        icon: Icon(Icons.delete_outline, size: isMobile ? 18 : 20, color: AppTheme.danger),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Hapus Kasbon',
                      ),
                    Icon(Icons.chevron_right_rounded, size: isMobile ? 18 : 20, color: _bodyText(context)),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String status;
  final Color color;
  final bool isMobile;

  const StatusBadge({super.key, required this.status, required this.color, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    final displayStatus = status == 'completed' ? 'approved' : status;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 6 : 8, vertical: isMobile ? 1 : 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        displayStatus.toUpperCase(),
        style: TextStyle(
          fontSize: isMobile ? 9 : 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class AppRadioGroup<T> extends StatelessWidget {
  final T groupValue;
  final ValueChanged<T?> onChanged;
  final Widget child;
  const AppRadioGroup({super.key, required this.groupValue, required this.onChanged, required this.child});

  @override
  Widget build(BuildContext context) {
    return _AppRadioGroupScope(
      groupValue: groupValue,
      onChanged: (val) => onChanged(val as T?),
      child: child,
    );
  }
}

class _AppRadioGroupScope extends InheritedWidget {
  final dynamic groupValue;
  final ValueChanged<dynamic> onChanged;
  const _AppRadioGroupScope({required this.groupValue, required this.onChanged, required super.child});

  static _AppRadioGroupScope? of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<_AppRadioGroupScope>();

  @override
  bool updateShouldNotify(_AppRadioGroupScope oldWidget) => groupValue != oldWidget.groupValue;
}

class AppRadioItem<T> extends StatelessWidget {
  final T value;
  final Widget label;
  const AppRadioItem({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final scope = _AppRadioGroupScope.of(context);
    final selected = scope?.groupValue == value;
    return InkWell(
      onTap: () => scope?.onChanged(value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<T>(
            value: value,
            // ignore: deprecated_member_use
            groupValue: scope?.groupValue as T?,
            // ignore: deprecated_member_use
            onChanged: (v) => scope?.onChanged(v),
            activeColor: AppTheme.primary,
          ),
          DefaultTextStyle(
            style: TextStyle(
              fontSize: 14,
              color: selected ? AppTheme.primary : AppTheme.textSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
            child: label,
          ),
        ],
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settlement_provider.dart';
import '../management/category_management_screen.dart';
import '../advance/advance_detail_screen.dart';
import '../dashboard_screen.dart';
import '../../theme/app_theme.dart';
import '../../widgets/category_preview_dialog.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/file_helper.dart';
import '../../utils/app_snackbar.dart';
import '../../widgets/app_scrollbar.dart';
import '../widgets/sidebar.dart';
import '../widgets/settlement_detail_widgets.dart';
import '../../utils/responsive_layout.dart';

class SettlementDetailScreen extends StatefulWidget {
  final int settlementId;
  const SettlementDetailScreen({super.key, required this.settlementId});

  @override
  State<SettlementDetailScreen> createState() => _SettlementDetailScreenState();
}

class _SettlementDetailScreenState extends State<SettlementDetailScreen> {
  final _currencyFormat = NumberFormat('#,##0', 'id_ID');
  final _foreignCurrencyFormat = NumberFormat('#,##0.##', 'en_US');
  final ScrollController _expenseTableVerticalCtrl = ScrollController();
  final ScrollController _expenseTableHorizontalCtrl = ScrollController();
  final ScrollController _mainScrollController = ScrollController();
  final ScrollController _subCategoryScrollController = ScrollController();
  final Set<int> _selectedExpenses = {}; // tracking multi-delete
  bool _isSaving = false; // Lock mechanism untuk prevent double-tap save

  // Sidebar state (untuk desktop saja)
  bool _sidebarExpanded = true;
  int _pendingSettlements = 0;
  int _pendingAdvances = 0;

  // Helper untuk cek platform
  bool _isAndroid(BuildContext context) => Theme.of(context).platform == TargetPlatform.android;
  bool _isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;
  Color _surfaceColor(BuildContext context) => _isDark(context) ? AppTheme.surface : AppTheme.lightSurface;
  Color _cardColor(BuildContext context) => _isDark(context) ? AppTheme.card : AppTheme.lightCard;
  Color _creamColor(BuildContext context) => _isDark(context) ? AppTheme.cream : AppTheme.lightTextPrimary;
  Color _primaryText(BuildContext context) => _isDark(context) ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
  Color _secondaryText(BuildContext context) => _isDark(context) ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
  Color _dividerColor(BuildContext context) => _isDark(context) ? AppTheme.divider : AppTheme.lightDivider;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<SettlementProvider>().loadSettlement(widget.settlementId);
        context.read<SettlementProvider>().loadCategories();
        _fetchBadgeCounts();
      }
    });
  }

  Future<void> _fetchBadgeCounts() async {
    try {
      final api = context.read<AuthProvider>().api;
      final data = await api.getDashboardSummary();
      if (mounted) {
        setState(() {
          _pendingSettlements = data['pending_settlements'] ?? 0;
          _pendingAdvances = data['pending_advances'] ?? 0;
        });
      }
    } catch (_) {}
  }

  Future<void> _handleNotificationTap(String? rawPath) async {
    if (!mounted || rawPath == null || rawPath.trim().isEmpty) return;
    final path = rawPath.trim().toLowerCase();

    // Extract ID from path
    final parts = path.split('/');
    int? id;
    for (int i = parts.length - 1; i >= 0; i--) {
      final value = int.tryParse(parts[i]);
      if (value != null) {
        id = value;
        break;
      }
    }

    // Navigate based on path
    if (path.contains('/settlements') && id != null) {
      // Navigate to settlement detail
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => SettlementDetailScreen(settlementId: id!)),
      );
      return;
    }

    if (path.contains('/advances') && id != null) {
      // Navigate to advance detail
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AdvanceDetailScreen(advanceId: id!)),
      );
      return;
    }

    if (path.contains('/categories')) {
      // Navigate to dashboard categories tab
      if (context.read<AuthProvider>().isManager) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/',
          (route) => false,
          arguments: {'initialTabIndex': 3},
        );
      }
      return;
    }

    if (path.contains('/reports')) {
      // Navigate to dashboard reports tab
      if (context.read<AuthProvider>().isManager) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/',
          (route) => false,
          arguments: {'initialTabIndex': 2},
        );
      }
      return;
    }
  }

  @override
  void dispose() {
    _expenseTableVerticalCtrl.dispose();
    _expenseTableHorizontalCtrl.dispose();
    _mainScrollController.dispose();
    _subCategoryScrollController.dispose();
    super.dispose();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'draft':
        return AppTheme.textSecondary;
      case 'submitted':
        return AppTheme.warning;
      case 'approved':
        return AppTheme.success;
      case 'completed':
        return AppTheme.success;
      case 'rejected':
        return AppTheme.danger;
      case 'pending':
        return AppTheme.warning;
      default:
        return AppTheme.textSecondary;
    }
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatExpenseAmount(Map<String, dynamic> expense) {
    final currency = (expense['currency'] ?? 'IDR').toString().toUpperCase();
    final amount = _toDouble(expense['amount']);
    final kurs = _toDouble(expense['currency_exchange']);
    final idrAmount = _toDouble(expense['idr_amount']) > 0
        ? _toDouble(expense['idr_amount'])
        : (amount * (kurs > 0 ? kurs : 1.0));

    if (currency == 'IDR') {
      return 'Rp ${_currencyFormat.format(amount)}';
    }

    return '$currency ${_foreignCurrencyFormat.format(amount)}\n(Rp ${_currencyFormat.format(idrAmount)})';
  }

  String _displaySettlementStatus(String status) {
    return status == 'completed' ? 'approved' : status;
  }

  List<Widget> _buildSettlementDetailActions(
    BuildContext context,
    Map<String, dynamic> s,
    AuthProvider auth,
    String settlementStatus,
  ) {
    final actions = <Widget>[];

    if ((s['advance_id'] ?? 0) > 0) {
      actions.add(
        SettlementActionButton(
          onPressed: () => _viewOriginalAdvance(s['advance_id']),
          icon: Icons.visibility_rounded,
          label: 'Lihat Kasbon',
          isOutlined: true,
        ),
      );
    }

    if (auth.user?['id'] == s['user_id'] &&
        (s['status'] == 'draft' || s['status'] == 'rejected') &&
        s['settlement_type'] == 'batch') {
      actions.add(
        SettlementActionButton(
          onPressed: () => _showEditSettlementDialog(context, s),
          icon: Icons.edit_rounded,
          label: 'Edit',
          isOutlined: true,
        ),
      );
    }

    if (auth.user?['id'] == s['user_id'] && s['status'] == 'draft') {
      actions.add(
        Builder(
          builder: (context) {
            final items = _asMapList(s['expenses']);
            return SettlementActionButton(
              onPressed: _canSubmitSettlementItems(items)
                  ? () => _submitSettlement()
                  : null,
              icon: Icons.send_rounded,
              label: 'Submit',
            );
          },
        ),
      );
    }

    if (auth.isManager && s['status'] == 'submitted') {
      actions.add(
        Builder(
          builder: (context) {
            final items = _asMapList(s['expenses']);
            return SettlementActionButton(
              onPressed: _canApproveSettlementItems(items)
                  ? () => _approveSettlement()
                  : null,
              icon: Icons.verified_rounded,
              label: 'Approve',
              backgroundColor: AppTheme.success,
            );
          },
        ),
      );
    }

    if (auth.user?['id'] == s['user_id'] &&
        (s['status'] == 'submitted' || s['status'] == 'rejected')) {
      actions.add(
        SettlementActionButton(
          onPressed: () => _moveToDraft(),
          icon: Icons.undo_rounded,
          label: 'Move to Draft',
          isOutlined: true,
        ),
      );
    }

    if (settlementStatus == 'approved' || settlementStatus == 'completed') {
      actions.add(
        SettlementActionButton(
          onPressed: () => _downloadReceipt(),
          icon: Icons.print_rounded,
          label: 'Cetak',
          isOutlined: true,
        ),
      );
      actions.add(
        SettlementActionButton(
          onPressed: () => _exportSettlementExcel(),
          icon: Icons.table_chart_rounded,
          label: 'Excel',
          isOutlined: true,
        ),
      );
    }

    return actions;
  }

  Widget _buildMobileSettlementActionBar(
    BuildContext context,
    Map<String, dynamic> s,
    AuthProvider auth,
    String settlementStatus,
  ) {
    final actions = _buildSettlementDetailActions(
      context,
      s,
      auth,
      settlementStatus,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
        color: _surfaceColor(context),
        border: Border(
          bottom: BorderSide(color: AppTheme.divider.withValues(alpha: 0.6)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (_selectedExpenses.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  onPressed: _bulkDeleteExpenses,
                  icon: const Icon(Icons.delete_sweep, color: AppTheme.danger),
                  tooltip: 'Hapus ${_selectedExpenses.length} item pilihan',
                ),
              ),
            ...actions
                .map(
                  (action) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: action,
                  ),
                ),
          ],
        ),
      ),
    );
  }

  String _displaySettlementTitle(Map<String, dynamic>? s) {
    if (s == null) return 'Detail Settlement';
    final type = (s['settlement_type'] ?? 'batch').toString().toLowerCase();
    final title = s['title'] ?? '';

    if (type == 'single') {
      final expenses = s['expenses'] as List? ?? [];
      if (expenses.isNotEmpty) {
        final firstExp = Map<String, dynamic>.from(expenses.first);
        return firstExp['description'] ?? title;
      }
    }
    return title.isEmpty ? 'Settlement' : title;
  }

  List<Map<String, dynamic>> _asMapList(dynamic list) {
    if (list == null || list is! List) return [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  List<Map<String, dynamic>> _uniqueById(List<Map<String, dynamic>> list) {
    final seen = <dynamic>{};
    return list.where((item) => seen.add(item['id'])).toList();
  }

  bool _hasUncheckedChecklist(Map<String, dynamic> expense) {
    final checklist = _parseChecklist(expense['notes']);
    return checklist.isNotEmpty &&
        checklist.any((item) => item['checked'] != true);
  }

  bool _canSubmitSettlementItems(List<Map<String, dynamic>> items) {
    if (items.isEmpty) return false;
    return !items.any(_hasUncheckedChecklist);
  }

  bool _canApproveSettlementItems(List<Map<String, dynamic>> items) {
    if (items.isEmpty) return false;
    return items.every(
      (item) =>
          (item['status'] ?? 'pending').toString().toLowerCase() == 'approved',
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final prov = context.watch<SettlementProvider>();
    final s = prov.currentSettlement;
    final settlementStatus = (s?['status'] ?? '').toString().toLowerCase();
    final isAndroid = _isAndroid(context);
    final expenses = s != null
        ? List<Map<String, dynamic>>.from(s['expenses'] ?? [])
        : <Map<String, dynamic>>[];
    final isSingleSettlement =
        (s?['settlement_type'] ?? 'single').toString().toLowerCase() == 'single';
    final canAddExpenses =
        s != null &&
        auth.user?['id'] == s['user_id'] &&
        (s['status'] == 'draft' || s['status'] == 'rejected') &&
        !(isSingleSettlement && expenses.isNotEmpty);

    final screenWidth = MediaQuery.of(context).size.width;
    final useCompact = screenWidth < 600 || isAndroid;
    final showSidebar = !useCompact;

    Future<void> handlePop(bool didPop) async {
      if (didPop) return;

      // Cleanup empty draft - jika belum ada expense dan masih unsaved
      if (prov.unsavedDraft && s != null) {
        final expenses = s['expenses'] as List? ?? [];
        if (expenses.isEmpty) {
          // Tampilkan dialog konfirmasi
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: _cardColor(ctx),
              title: Text(
                'Hapus Settlement Kosong?',
                style: TextStyle(color: _creamColor(ctx)),
              ),
              content: Text(
                'Settlement ini belum memiliki expense. Hapus settlement kosong ini?',
                style: TextStyle(color: _secondaryText(ctx)),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.danger,
                  ),
                  child: const Text('Hapus'),
                ),
              ],
            ),
          );

          if (confirm == true && mounted) {
            // User confirm - delete empty draft
            await prov.cleanupEmptyDraft(s['id']);
          }
        }
      }

      if (!context.mounted) return;
      Navigator.of(context).pop();
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        await handlePop(didPop);
      },
      child: Scaffold(
        body: Row(
        children: [
          // Sidebar - HANYA untuk desktop/Windows
          if (showSidebar) ...[
            DashboardSidebar(
              currentIndex: 0,
              isManager: auth.isManager,
              fullName: auth.fullName,
              role: auth.roleDisplayName,
              onNavTap: (index) {
                // Navigate sesuai index
                if (index == 0) {
                  // Klik Settlement → Ke Settlement List (tab 0 di Dashboard)
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => DashboardScreen(initialTabIndex: 0),
                    ),
                    (route) => false,
                  );
                } else if (index == 1) {
                  // Klik Kasbon → Ke Kasbon List (tab 1 di Dashboard)
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => DashboardScreen(initialTabIndex: 1),
                    ),
                    (route) => false,
                  );
                } else if (index == 2 && auth.isManager) {
                  // Klik Laporan → Ke Laporan (tab 2 di Dashboard)
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => DashboardScreen(initialTabIndex: 2),
                    ),
                    (route) => false,
                  );
                } else if (index == 3 && auth.isManager) {
                  // Klik Kategori → Ke Kategori (tab 3 di Dashboard)
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => DashboardScreen(initialTabIndex: 3),
                    ),
                    (route) => false,
                  );
                } else if (index == 4 && auth.isManager) {
                  // Klik Settings → Ke Settings (tab 4 di Dashboard)
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => DashboardScreen(initialTabIndex: 4),
                    ),
                    (route) => false,
                  );
                }
              },
              onNotificationTap: (path) async {
                // Handle notification tap - navigate ke path yang dituju
                await _handleNotificationTap(path);
              },
              onLogout: () => auth.logout(),
              isMini: false,
              isExpanded: _sidebarExpanded,
              onToggleExpand: () {
                setState(() {
                  _sidebarExpanded = !_sidebarExpanded;
                });
              },
              pendingSettlements: _pendingSettlements,
              pendingAdvances: _pendingAdvances,
            ),
            Container(width: 1, color: AppTheme.divider),
          ],
          // Content detail settlement
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                      title: Text(
                        _displaySettlementTitle(s),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _creamColor(context),
                        ),
                      ),
                      actions: [
                        if (_selectedExpenses.isNotEmpty)
                          IconButton(
                            onPressed: _bulkDeleteExpenses,
                            icon: const Icon(
                              Icons.delete_sweep,
                              color: AppTheme.danger,
                            ),
                            tooltip:
                                'Hapus ${_selectedExpenses.length} item pilihan',
                          ),
                        if (s != null) ...[
                          Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _statusColor(s['status']).withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _displaySettlementStatus(
                                (s['status'] as String),
                              ).toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                                color: _statusColor(s['status']),
                              ),
                            ),
                          ),
                          // Only show actions in AppBar if NOT mobile to prevent overflow
                          if (!ResponsiveLayout.isMobile(context))
                            ..._buildSettlementDetailActions(
                              context,
                              s,
                              auth,
                              settlementStatus,
                            ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
      body: prov.loading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : s == null
          ? const Center(child: Text('Data tidak ditemukan'))
          : ResponsiveLayout.isMobile(context)
          ? AppScrollbar(
              controller: _mainScrollController,
              thumbVisibility: true,
              interactive: true,
              child: SingleChildScrollView(
                controller: _mainScrollController,
                child: Column(
                  children: [
                    _buildMobileSettlementActionBar(
                      context,
                      s,
                      auth,
                      settlementStatus,
                    ),
                    _buildContent(context, s, auth, prov),
                  ],
                ),
              ),
            )
          : AppScrollbar(
              controller: _mainScrollController,
              thumbVisibility: true,
              interactive: true,
              child: SingleChildScrollView(
                controller: _mainScrollController,
                child: _buildContent(context, s, auth, prov),
              ),
            ),
      floatingActionButton: canAddExpenses
          ? Padding(
              padding: const EdgeInsets.only(bottom: 16, right: 8),
              child: ElevatedButton.icon(
                onPressed: () => _showAddExpenseDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Tambah Expense'),
              ),
            )
          : null,
        ), // End inner Scaffold
      ), // End Expanded
    ], // End Row
    ), // End Row
    ), // End outer Scaffold
    ); // End PopScope
  }

  Widget _buildContent(
    BuildContext context,
    Map<String, dynamic> s,
    AuthProvider auth,
    SettlementProvider prov,
  ) {
    final expenses = List<Map<String, dynamic>>.from(s['expenses'] ?? []);
    final availableFund = _toDouble(s['available_fund']);
    final varianceAmount = _toDouble(s['variance_amount']);
    final advanceSummary = s['advance_summary'] as Map<String, dynamic>?;
    final policyWarnings = List<String>.from(s['policy_warnings'] ?? []);
    final isFromAdvance = (s['advance_id'] ?? 0) > 0;
    final isSingleSettlement =
        (s['settlement_type'] ?? 'single').toString().toLowerCase() == 'single';
    final canAddExpenses = auth.user?['id'] == s['user_id'] &&
        (s['status'] == 'draft' || s['status'] == 'rejected') &&
        !(isSingleSettlement && expenses.isNotEmpty);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label khusus untuk settlement dari kasbon
          if (isFromAdvance)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.15),
                border: Border.all(color: AppTheme.warning.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.warning, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Settlement dari Kasbon',
                          style: TextStyle(
                            color: AppTheme.warning,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Settlement ini dibuat dari kasbon yang sudah disetujui. Verifikasi expense dengan membandingkan kasbon asli.',
                          style: TextStyle(
                            color: AppTheme.warning.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Tombol "Lihat Kasbon" dihapus dari sini (sudah ada di header)
                ],
              ),
            ),
          // kartu ringkasan
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 750;
              final cards = [
                SummaryCard(
                  icon: Icons.receipt_long_rounded,
                  label: 'Total',
                  value: 'Rp ${_currencyFormat.format(s['total_amount'] ?? 0)}',
                  color: AppTheme.primary,
                ),
                SummaryCard(
                  icon: Icons.check_circle_rounded,
                  label: 'Approved',
                  value:
                      'Rp ${_currencyFormat.format(s['approved_amount'] ?? 0)}',
                  color: AppTheme.success,
                ),
                SummaryCard(
                  icon: Icons.list_alt_rounded,
                  label: 'Expense',
                  value: '${expenses.length} item',
                  color: AppTheme.accent,
                ),
                if ((s['advance_id'] ?? 0) > 0)
                  SummaryCard(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Dana Kasbon',
                    value: 'Rp ${_currencyFormat.format(availableFund)}',
                    color: AppTheme.warning,
                  ),
                if ((s['advance_id'] ?? 0) > 0)
                  SummaryCard(
                    icon: Icons.compare_arrows_rounded,
                    label: varianceAmount > 0
                        ? 'Sisa Uang (Refund ke Perusahaan)'
                        : (varianceAmount < 0
                              ? 'Kurang Uang (Reimburse dari Perusahaan)'
                              : 'Selisih (Pas)'),
                    value: 'Rp ${_currencyFormat.format(varianceAmount.abs())}',
                    color: varianceAmount < 0
                        ? AppTheme.danger
                        : (varianceAmount > 0
                              ? AppTheme.warning
                              : AppTheme.success),
                  ),
              ];

              if (isNarrow) {
                return Column(
                  children: [
                    ...cards.expand((c) => [c, const SizedBox(height: 8)]).toList()..removeLast(),
                  ],
                );
              }

              // layout desktop dan tablet
              return Row(
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 16),
                  Expanded(child: cards[1]),
                  const SizedBox(width: 16),
                  Expanded(child: cards[2]),
                  if (cards.length > 3) ...[
                    const SizedBox(width: 16),
                    Expanded(child: cards[3]),
                    const SizedBox(width: 16),
                    Expanded(child: cards[4]),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.person_outline,
                color: AppTheme.textSecondary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Dibuat oleh: ${s['requester_name'] ?? '-'}',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.calendar_today_outlined,
                color: AppTheme.textSecondary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                s['created_at'] != null
                    ? s['created_at'].toString().substring(0, 10)
                    : '-',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
          if (advanceSummary != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Wrap(
                spacing: 20,
                runSpacing: 10,
                children: [
                  Text(
                    'Kasbon awal: Rp ${_currencyFormat.format(advanceSummary['base_amount'] ?? 0)}',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  Text(
                    'Tambahan: Rp ${_currencyFormat.format(advanceSummary['revision_amount'] ?? 0)}',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  Text(
                    'Revisi approved: ${advanceSummary['approved_revision_no'] ?? 0}',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ],
          if (policyWarnings.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...policyWarnings.map(
              (warning) => Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(warning, style: TextStyle(color: _creamColor(context))),
              ),
            ),
          ],

          const SizedBox(height: 28),
          Text(
            'Rincian Item Settlement',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _creamColor(context),
            ),
          ),
          const SizedBox(height: 16),

          // tabel expense
          expenses.isEmpty
              ? _buildEmptyState(canAddExpenses)
              : Container(                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AppScrollbar(
                      controller: _expenseTableVerticalCtrl,
                      thumbVisibility: true,
                      trackVisibility: true,
                      interactive: true,
                      child: SingleChildScrollView(
                        controller: _expenseTableVerticalCtrl,
                        child: AppScrollbar(
                          controller: _expenseTableHorizontalCtrl,
                          thumbVisibility: true,
                          trackVisibility: true,
                          interactive: true,
                          scrollDirection: Axis.horizontal,
                          notificationPredicate: (notification) =>
                              notification.metrics.axis == Axis.horizontal,
                          child: SingleChildScrollView(
                            controller: _expenseTableHorizontalCtrl,
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                                dataRowMaxHeight: double.infinity,
                                headingRowColor: WidgetStateProperty.all(
                                  _surfaceColor(context),
                                ),
                                dataRowColor: WidgetStateProperty.resolveWith((
                                  states,
                                ) {
                                  if (states.contains(WidgetState.hovered)) {
                                    return _isDark(context) ? AppTheme.cardHover : AppTheme.lightCardHover;
                                  }
                                  return _cardColor(context);
                                }),
                                showCheckboxColumn: true,
                                columns: [
                                  DataColumn(
                                    label: Text(
                                      'No',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: _creamColor(context),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Tanggal',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: _creamColor(context),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Subkategori',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: _creamColor(context),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Sumber',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: _creamColor(context),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Deskripsi',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: _creamColor(context),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Amount',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: _creamColor(context),
                                      ),
                                    ),
                                    numeric: true,
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Evidence',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: _creamColor(context),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Status',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: _creamColor(context),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Aksi',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: _creamColor(context),
                                      ),
                                    ),
                                  ),
                                ],
                                rows: expenses.asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  final exp = entry.value;
                                  final expId = exp['id'] as int;

                                  return DataRow(
                                    selected: _selectedExpenses.contains(expId),
                                    onSelectChanged: (selected) {
                                      setState(() {
                                        if (selected == true) {
                                          _selectedExpenses.add(expId);
                                        } else {
                                          _selectedExpenses.remove(expId);
                                        }
                                      });
                                    },
                                    cells: [
                                      DataCell(Text('${idx + 1}')),
                                      DataCell(Text(exp['date'] ?? '-')),
                                      DataCell(
                                        Builder(builder: (context) {
                                          final catName = exp['category_name'] ?? '-';
                                          String subCat = catName;
                                          if (catName.contains(' > ')) {
                                            subCat = catName.split(' > ').last;
                                          }
                                          return Text(subCat);
                                        }),
                                      ),
                                      DataCell(Text(exp['source'] ?? '-')),
                                      DataCell(
                                        ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            maxWidth: 200,
                                          ),
                                          child: Text(
                                            exp['description'] ?? '',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      DataCell(Text(_formatExpenseAmount(exp))),
                                      DataCell(
                                        exp['evidence_path'] != null
                                            ? IconButton(
                                                icon: Icon(
                                                  Icons.image_rounded,
                                                  color: AppTheme.accent,
                                                  size: 20,
                                                ),
                                                tooltip: 'Lihat Bukti',
                                                onPressed: () => _showEvidence(
                                                  exp['evidence_path'],
                                                  exp['evidence_filename'],
                                                ),
                                              )
                                            : const Text(
                                                '-',
                                                style: TextStyle(
                                                  color: AppTheme.textSecondary,
                                                ),
                                              ),
                                      ),
                                      DataCell(
                                        Builder(builder: (context) {
                                          final status = (exp['status'] as String).toLowerCase();
                                          final notes = exp['notes'];
                                          final statusUpper = status.toUpperCase();
                                          Color statusColor = _statusColor(status);

                                          // Jika status rejected/pending dan ada checklist di notes
                                          if ((status == 'rejected' || status == 'pending') && notes != null) {
                                            try {
                                              List<dynamic> checklist = [];
                                              final parsedNotes = notes is String && notes.startsWith('[')
                                                  ? jsonDecode(notes)
                                                  : notes;

                                              if (parsedNotes is List) {
                                                checklist = List<dynamic>.from(parsedNotes);
                                              }

                                              if (checklist.isNotEmpty) {
                                                final total = checklist.length;
                                                final checked = checklist.where((it) => it['checked'] == true).length;

                                                Widget badge = Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: statusColor.withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(
                                                      color: statusColor.withValues(alpha: 0.3),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    '$statusUpper (Comment $checked/$total)',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w700,
                                                      color: statusColor,
                                                    ),
                                                  ),
                                                );

                                                return InkWell(
                                                  onTap: () => _showChecklistDialog(expId, checklist, (s['status'] ?? '').toString()),
                                                  borderRadius: BorderRadius.circular(6),
                                                  child: badge,
                                                );
                                              }
                                            } catch (e) {
                                              // Fallback
                                            }
                                          }

                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: statusColor.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              statusUpper,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: statusColor,
                                              ),
                                            ),
                                          );
                                        }),
                                      ),
                                      DataCell(_buildActionCell(exp, auth, s)),
                                    ],
                                  );
                                }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
          const SizedBox(height: 100), // Padding extra agar tidak tertabrak FAB
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool canAddItems) {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.divider, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum ada expense ditambahkan',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          if (canAddItems) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showAddExpenseDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Item Sekarang'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionCell(
    Map<String, dynamic> exp,
    AuthProvider auth,
    Map<String, dynamic> s,
  ) {
    final settlementStatus = s['status'];
    final itemStatus = (exp['status'] ?? 'pending').toString().toLowerCase();

    if (auth.isManager && settlementStatus == 'submitted') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (itemStatus == 'pending')
            IconButton(
              icon: Icon(Icons.check_rounded, color: AppTheme.success, size: 20),
              tooltip: 'Approve',
              onPressed: () => _approveExpense(exp['id'], 'approve'),
            ),
          if (itemStatus == 'pending' || itemStatus == 'approved')
            IconButton(
              icon: Icon(Icons.close_rounded, color: AppTheme.danger, size: 20),
              tooltip: 'Reject',
              onPressed: () => _approveExpense(exp['id'], 'reject'),
            ),
        ],
      );
    }
    if (auth.user?['id'] == s['user_id'] &&
        (settlementStatus == 'draft' ||
            settlementStatus == 'rejected' ||
            (settlementStatus == 'submitted' && itemStatus == 'rejected'))) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.edit_rounded, color: AppTheme.accent, size: 20),
            tooltip: 'Edit',
            onPressed: () => _showEditExpenseDialog(context, exp),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: AppTheme.danger, size: 20),
            tooltip: 'Hapus',
            onPressed: () => _deleteExpense(exp['id']),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
  void _showAddExpenseDialog(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final reportYear = context.read<SettlementProvider>().reportYear;
    final now = DateTime.now();
    final defaultDate = reportYear == 0 || reportYear == now.year ? now : DateTime(reportYear, 12, 31);
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final dateCtrl = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(defaultDate),
    );
    final exchangeRateCtrl = TextEditingController(text: '1');
    int? selectedParentId; // For Main Category
    Set<int> selectedSubCategoryIds = {}; // For Sub Categories (Multi-select)
    String? selectedFilePath;
    String? selectedFileName;
    String? selectedSource;
    String selectedCurrency = 'IDR';


    // pakai kategori nested asli
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final prov = ctx.watch<SettlementProvider>();
          // Tampilkan semua kategori agar bisa dipilih staf (pending & approved)
          final allCats = _uniqueById(_asMapList(prov.categories));
          final parentIds =
              allCats.map((c) => c['id']).whereType<int>().toSet();
          final effectiveParentId =
              parentIds.contains(selectedParentId) ? selectedParentId : null;
          final parent = effectiveParentId != null
              ? allCats.firstWhere(
                  (c) => c['id'] == effectiveParentId,
                  orElse: () => {},
                )
              : {};
          final children = _uniqueById(
            _asMapList(parent['children'] as List?));
          final childIds =
              children.map((c) => c['id']).whereType<int>().toSet();
          // Filter out subcategory IDs that no longer belong to selected parent
          selectedSubCategoryIds = selectedSubCategoryIds.intersection(childIds);

          return AlertDialog(
          backgroundColor: _cardColor(ctx),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Tambah Expense',
            style: TextStyle(color: _creamColor(ctx)),
          ),
          content: SizedBox(
            width: screenWidth > 600 ? 500 : screenWidth * 0.9,
            child: AppScrollbar(
              thumbVisibility: true,
              interactive: true,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  const SizedBox(height: 10), // Memberi ruang agar label tidak menempel ke judul
                  // dropdown kategori utama
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Kategori Utama',
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    isExpanded: true,
                    dropdownColor: AppTheme.card,
                    style: TextStyle(color: AppTheme.textPrimary),
                    initialValue: effectiveParentId,
                    items: allCats
                        .map(
                          (c) {
                            final isPending = c['status'] == 'pending';
                            return DropdownMenuItem<int>(
                              value: c['id'] as int,
                              child: Text(
                                isPending ? '${c['name']} (Pending)' : c['name'],
                                style: TextStyle(
                                  color: isPending ? AppTheme.warning : null,
                                ),
                              ),
                            );
                          },
                        )
                        .toList(),
                    onChanged: (v) => setDialogState(() {
                      selectedParentId = v;
                      selectedSubCategoryIds = {}; // reset sub kategori
                    }),
                  ),
                  const SizedBox(height: 12),

                  // Checklist Sub Kategori
                  // Checklist Sub Kategori
                  if (effectiveParentId != null) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        children.isNotEmpty ? 'Pilih Sub Kategori:' : 'Hanya Kategori Utama',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (children.isNotEmpty)
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.divider),
                        ),
                        child: AppScrollbar(
                          controller: _subCategoryScrollController,
                          thumbVisibility: true,
                          interactive: true,
                          child: SingleChildScrollView(
                            controller: _subCategoryScrollController,
                            child: Column(
                              children: children.map((c) {
                              final subId = c['id'] as int;
                              final isPending = c['status'] == 'pending';
                              final isSelected = selectedSubCategoryIds.contains(subId);

                              return CheckboxListTile(
                                value: isSelected,
                                activeColor: AppTheme.primary,
                                checkColor: Colors.white,
                                dense: true,
                                title: Text(
                                  isPending ? '${c['name']} (Pending)' : c['name'],
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppTheme.primary
                                        : (isPending ? AppTheme.warning : _primaryText(ctx)),
                                    fontSize: 13,
                                  ),
                                ),
                                onChanged: (val) {
                                  setDialogState(() {
                                    if (val == true) {
                                      selectedSubCategoryIds.add(subId);
                                    } else {
                                      selectedSubCategoryIds.remove(subId);
                                    }
                                  });
                                },
                                controlAffinity: ListTileControlAffinity.leading,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                        )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Kategori ini tidak memiliki sub-kategori.',
                          style: TextStyle(color: _secondaryText(ctx), fontSize: 12),
                        ),
                      ),
                  ],

                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: TextButton.icon(
                          onPressed: () => _showAddCategoryDialog(
                            ctx,
                            setDialogState,
                            (newCat) {
                              // coba pilih otomatis kalau bisa
                              final parentID = newCat['parent_id'];
                              final catID = newCat['id'] as int;
                              setDialogState(() {
                               if (parentID != null) {
                                  // ini sub kategori
                                  selectedParentId = parentID;
                                  selectedSubCategoryIds.add(catID);
                                } else {
                                  // ini kategori utama
                                  selectedParentId = catID;
                                  selectedSubCategoryIds = {}; // No sub yet
                                }
                              });
                            },
                            parentId: selectedParentId,
                          ),
                          icon: const Icon(Icons.add_circle_outline, size: 16),
                          label: Text(
                            selectedParentId != null
                                ? 'Tambah Sub-Kategori Baru'
                                : 'Tambah Kategori Baru',
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.category_rounded, color: AppTheme.primary, size: 20),
                        tooltip: 'Pratinjau Struktur Kategori',
                        onPressed: () => showCategoryPreviewDialog(context, context.read<SettlementProvider>().categories),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Deskripsi'),
                    style: TextStyle(color: _primaryText(ctx)),
                    onChanged: (val) {
                      final lower = val.toLowerCase();
                      for (final p in allCats) {
                        final pName = p['name'].toString().toLowerCase();
                        if (lower.contains(pName)) {
                          setDialogState(() {
                            // If parent changes, we should ideally clear subcategories
                            // BUT if we are auto-detecting multiple ones, it's tricky.
                            // The intersection logic in build() will handle safety.
                            selectedParentId = p['id'];
                          });
                        }
                        final children = _asMapList(p['children'] as List?);
                        for (final c in children) {
                          final cName = c['name'].toString().toLowerCase();
                          if (lower.contains(cName)) {
                            setDialogState(() {
                              selectedParentId = p['id'];
                              selectedSubCategoryIds.add(c['id'] as int);
                            });
                          }
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  // mata uang
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Mata Uang',
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                          ),
                          dropdownColor: _cardColor(ctx),
                          style: TextStyle(color: _primaryText(ctx)),
                          initialValue: selectedCurrency,
                          items: const [
                            DropdownMenuItem(value: 'IDR', child: Text('IDR')),
                            DropdownMenuItem(value: 'USD', child: Text('USD')),
                            DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                            DropdownMenuItem(value: 'GBP', child: Text('GBP')),
                            DropdownMenuItem(value: 'JPY', child: Text('JPY')),
                            DropdownMenuItem(value: 'CNY', child: Text('CNY')),
                            DropdownMenuItem(value: 'AUD', child: Text('AUD')),
                            DropdownMenuItem(value: 'HKD', child: Text('HKD')),
                            DropdownMenuItem(value: 'SGD', child: Text('SGD')),
                            DropdownMenuItem(value: 'TWD', child: Text('TWD')),
                            DropdownMenuItem(value: 'THB', child: Text('THB')),
                            DropdownMenuItem(value: 'MYR', child: Text('MYR')),
                          ],
                          onChanged: (v) => setDialogState(() {
                            selectedCurrency = v ?? 'IDR';
                            if (selectedCurrency == 'IDR') {
                              exchangeRateCtrl.text = '1';
                            }
                          }),
                        ),
                      ),
                      if (selectedCurrency != 'IDR') ...[
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: exchangeRateCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Kurs (ke IDR)',
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                            ),
                            style: TextStyle(color: _primaryText(ctx)),
                            keyboardType: TextInputType.number,
                            inputFormatters: [CurrencyInputFormatter()],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    decoration: InputDecoration(
                      labelText: 'Amount ($selectedCurrency)',
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      hintText: '10.000',
                      hintStyle: TextStyle(
                        color: _secondaryText(ctx).withValues(alpha: 0.5),
                      ),
                    ),
                    style: TextStyle(color: _primaryText(ctx)),
                    keyboardType: TextInputType.number,
                    inputFormatters: [CurrencyInputFormatter()],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dateCtrl,
                    decoration: InputDecoration(
                      labelText: 'Tanggal',
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today, size: 18),
                        onPressed: () async {
                          final initialDate =
                              DateTime.tryParse(dateCtrl.text) ?? defaultDate;
                          final d = await showDatePicker(
                            context: ctx,
                            initialDate: initialDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (d != null) {
                            dateCtrl.text = DateFormat('yyyy-MM-dd').format(d);
                          }
                        },
                      ),
                    ),
                    style: TextStyle(color: _primaryText(ctx)),
                    readOnly: true,
                  ),
                  const SizedBox(height: 12),
                  // dropdown sumber
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Sumber Pembayaran',
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                    ),
                    dropdownColor: _cardColor(ctx),
                    style: TextStyle(color: _primaryText(ctx)),
                    initialValue: selectedSource,
                    items: const [
                      DropdownMenuItem(value: 'BCA', child: Text('BCA')),
                      DropdownMenuItem(value: 'BRI', child: Text('BRI')),
                      DropdownMenuItem(
                        value: 'Mandiri',
                        child: Text('Mandiri'),
                      ),
                      DropdownMenuItem(value: 'BNI', child: Text('BNI')),
                      DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'Advance', child: Text('Advance')),
                      DropdownMenuItem(
                        value: 'Lainnya',
                        child: Text('Lainnya'),
                      ),
                    ],
                    onChanged: (v) => setDialogState(() => selectedSource = v),
                  ),
                  const SizedBox(height: 16),
                    // pilih file
                  OutlinedButton.icon(
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: [
                          'jpg',
                          'jpeg',
                          'png',
                          'pdf',
                          'webp',
                        ],
                      );
                      if (result != null) {
                        setDialogState(() {
                          selectedFilePath = result.files.single.path;
                          selectedFileName = result.files.single.name;
                        });
                      }
                    },
                    icon: const Icon(Icons.upload_file_rounded),
                    label: Text(selectedFileName ?? 'Upload Bukti (opsional)'),
                  ),
                  if (selectedFileName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '✓ $selectedFileName',
                        style: TextStyle(color: AppTheme.success, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: _isSaving ? null : () async {
                // validasi berurutan dari atas ke bawah
                // 1. validasi kategori utama
                if (selectedParentId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Pilih Kategori Utama'),
                      backgroundColor: AppTheme.danger,
                    ),
                  );
                  return;
                }

                final parent = allCats.firstWhere(
                  (c) => c['id'] == selectedParentId,
                  orElse: () => {},
                );
                final children = (parent['children'] as List?) ?? [];

                // 2. validasi sub kategori (jika parent punya child)
                if (children.isNotEmpty && selectedSubCategoryIds.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Pilih Sub Kategori'),
                      backgroundColor: AppTheme.danger,
                    ),
                  );
                  return;
                }

                // 3. validasi deskripsi
                if (descCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Deskripsi harus diisi'),
                      backgroundColor: AppTheme.danger,
                    ),
                  );
                  return;
                }

                // 4. validasi amount
                if (amountCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Amount harus diisi'),
                      backgroundColor: AppTheme.danger,
                    ),
                  );
                  return;
                }

                final amount = double.tryParse(
                  amountCtrl.text.replaceAll('.', '').replaceAll(',', ''),
                );
                if (amount == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Amount harus angka valid'),
                      backgroundColor: AppTheme.danger,
                    ),
                  );
                  return;
                }

                // 5. validasi nominal minimal 100
                if (amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Isi nominal dengan nilai yang benar.'),
                      backgroundColor: AppTheme.danger,
                    ),
                  );
                  return;
                }
                final rateForValidation = double.tryParse(exchangeRateCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 1.0;
                final totalIdrValidation = amount * rateForValidation;

                if (totalIdrValidation <= 100) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nominal ekuivalen Rupiah harus lebih dari Rp 100'),
                      backgroundColor: AppTheme.danger,
                    ),
                  );
                  return;
                }

                // 6. validasi sumber pembayaran
                if (selectedSource == null || selectedSource!.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Pilih Sumber Pembayaran'),
                      backgroundColor: AppTheme.danger,
                    ),
                  );
                  return;
                }

                // Lock mechanism - prevent double-tap
                setState(() => _isSaving = true);

                  try {
                    // pakai id sub pertama sebagai ID utama (tetap dikirim untuk kompatibilitas legacy)
                    final firstSubId = selectedSubCategoryIds.isNotEmpty ? selectedSubCategoryIds.first : null;
                    final finalCatId = firstSubId ?? selectedParentId!;
                    final subcatIds = selectedSubCategoryIds.toList();
                    final prov = context.read<SettlementProvider>();

                    // Cek apakah ini expense pertama
                    final currentSettlement = prov.currentSettlement;
                    final expenses = currentSettlement?['expenses'] as List? ?? [];
                    final isFirstExpense = expenses.isEmpty;

                    bool success;
                    if (isFirstExpense) {
                      // EXPENSE PERTAMA - Auto-save Settlement + Expense
                      success = await prov.saveFirstExpenseAndCommitSettlement(
                        settlementId: widget.settlementId,
                        categoryId: finalCatId,
                        categoryIds: subcatIds,
                        description: descCtrl.text.trim(),
                        amount: amount,
                        date: dateCtrl.text,
                        source: selectedSource,
                        currency: selectedCurrency,
                        currencyExchange: rateForValidation,
                        filePath: selectedFilePath,
                      );
                    } else {
                      // Expense selanjutnya - save expense saja
                      success = await prov.addExpense(
                        settlementId: widget.settlementId,
                        categoryId: finalCatId,
                        categoryIds: subcatIds,
                        description: descCtrl.text.trim(),
                        amount: amount,
                        date: dateCtrl.text,
                        source: selectedSource,
                        currency: selectedCurrency,
                        currencyExchange: rateForValidation,
                        filePath: selectedFilePath,
                      );
                    }

                  if (ctx.mounted) Navigator.pop(ctx);
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Expense ditambahkan ✓'),
                        backgroundColor: AppTheme.success,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                } finally {
                  // Unlock mechanism
                  if (mounted) setState(() => _isSaving = false);
                }
              },
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Simpan'),
            ),
          ],
        );
        },
      ),
    );
  }

  void _showEvidence(String path, String? filename) {
    final screenWidth = MediaQuery.of(context).size.width;
    final prov = context.read<SettlementProvider>();
    final url = prov.getEvidenceUrl(path);
    final isImage =
        path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png') ||
        path.endsWith('.webp');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardColor(ctx),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          filename ?? 'Evidence',
          style: TextStyle(color: _creamColor(ctx)),
        ),
        content: SizedBox(
          width: screenWidth > 700 ? 600 : screenWidth * 0.9,
          height: 400,
          child: isImage
              ? Image.network(
                  url,
                  headers: {
                    'Authorization':
                        'Bearer ${context.read<AuthProvider>().token}',
                  },
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primary,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, _, _) => const Center(
                    child: Text(
                      'Gagal memuat gambar',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                )
              : Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.picture_as_pdf_rounded,
                        size: 64,
                        color: AppTheme.danger,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        filename ?? 'PDF File',
                        style: TextStyle(color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final uri = Uri.parse(url);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          } else {
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text('Tidak dapat membuka URL ini.'),
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: const Text('Buka & Lihat File'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Future<void> _approveExpense(int expenseId, String action) async {
    String notes = '';
      if (action == 'reject') {
      final controllers = [TextEditingController()];
      final confirmReject = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: _cardColor(ctx),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Tolak Item', style: TextStyle(color: _creamColor(ctx))),
              content: SizedBox(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Berikan alasan penolakan dalam bentuk checklist:',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    // Fix: Gunakan Flexible dengan constraints yang jelas
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: SingleChildScrollView(
                        child: Column(
                          children: controllers.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final ctrl = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_box_outline_blank_rounded, size: 20, color: AppTheme.textSecondary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: ctrl,
                                      autofocus: idx == controllers.length - 1,
                                      decoration: InputDecoration(
                                        hintText: 'Alasan #${idx + 1}',
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                      ),
                                      style: TextStyle(color: _creamColor(ctx), fontSize: 14),
                                      maxLines: null,
                                      minLines: 1,
                                      keyboardType: TextInputType.multiline,
                                    ),
                                  ),
                                  if (controllers.length > 1)
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, color: AppTheme.danger, size: 20),
                                      onPressed: () {
                                        // Fix: Dispose controller dengan aman
                                        final removedCtrl = controllers[idx];
                                        setDialogState(() {
                                          controllers.removeAt(idx);
                                        });
                                        // Dispose setelah remove dari list
                                        Future.delayed(Duration.zero, () {
                                          removedCtrl.dispose();
                                        });
                                      },
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () => setDialogState(() {
                        controllers.add(TextEditingController());
                      }),
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                      label: const Text('Tambah Alasan'),
                      style: TextButton.styleFrom(foregroundColor: AppTheme.accent),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Dispose semua controllers dengan aman
                    for (var c in controllers) {
                      try {
                        c.dispose();
                      } catch (_) {
                        // Ignore jika sudah disposed
                      }
                    }
                    Navigator.pop(ctx, false);
                  },
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (controllers.every((c) => c.text.trim().isEmpty)) return;
                    // Jangan dispose di sini, akan dispose setelah dialog close
                    Navigator.pop(ctx, true);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
                  child: const Text('Tolak Item'),
                ),
              ],
            );
          },
        ),
      );

      if (confirmReject == true) {
        final reasons = controllers
            .map((c) => c.text.trim())
            .where((t) => t.isNotEmpty)
            .map((t) => {'text': t, 'checked': false})
            .toList();

        // Dispose setelah dialog ditutup
        for (var c in controllers) {
          try {
            c.dispose();
          } catch (_) {
            // Ignore jika sudah disposed
          }
        }

        if (reasons.isEmpty) return;
        notes = jsonEncode(reasons);
      } else {
        // Dispose jika user batal
        for (var c in controllers) {
          try {
            c.dispose();
          } catch (_) {
            // Ignore jika sudah disposed
          }
        }
        return;
      }
    }

    if (!mounted) return;
    final prov = context.read<SettlementProvider>();
    final success = await prov.approveExpense(expenseId, action, notes: notes);
    if (mounted) {
      if (!success && (prov.error ?? '').contains('belum disetujui')) {
        // Tampilkan dialog khusus untuk kategori belum diapprove (MERAH)
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1F1D2B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppTheme.danger, width: 2),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.error_outline_rounded, color: AppTheme.danger, size: 28),
                ),
                const SizedBox(width: 12),
                Text('Akses Ditolak',
                    style: TextStyle(color: _creamColor(ctx), fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prov.error ?? 'Kategori item ini belum disetujui oleh manager.',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Text(
                  'Silakan setujui kategori ini terlebih dahulu di halaman Manajemen Kategori agar item ini bisa diproses.',
                  style: TextStyle(color: _secondaryText(ctx), fontSize: 14),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Tutup', style: TextStyle(color: Colors.white60)),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx); // Tutup dialog
                  // Push halaman kategori secara langsung
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Scaffold(
                        appBar: AppBar(
                          title: const Text('Approve Kategori'),
                          backgroundColor: _surfaceColor(context),
                        ),
                        body: const CategoryManagementView(),
                      ),
                    ),
                  ).then((_) {
                    // Refresh data saat kembali
                    if (mounted) {
                      context.read<SettlementProvider>().loadSettlement(widget.settlementId);
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.danger,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.category_rounded, size: 18),
                label: const Text('Ke Management Kategori'),
              ),
            ],
          ),
        );
        return;
      }

      final label = action == 'reject' ? 'rejected' : 'approved';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Expense $label ✓' : (prov.error ?? 'Gagal'),
          ),
          backgroundColor: success ? AppTheme.success : AppTheme.danger,
        ),
      );
    }
  }

  Future<void> _deleteExpense(int expenseId) async {
    if (!mounted) return;
    final prov = context.read<SettlementProvider>();
    await prov.deleteExpense(expenseId, widget.settlementId);
  }

  Future<void> _moveToDraft() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardColor(ctx),
        title: Text('Kembalikan ke Draft?', style: TextStyle(color: _creamColor(ctx))),
        content: Text(
          'Apakah Anda yakin ingin menarik kembali pengeluaran ini ke status Draft untuk melakukan perbaikan?',
          style: TextStyle(color: _secondaryText(ctx)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Kembalikan ke Draft'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final prov = context.read<SettlementProvider>();
    final success = await prov.moveSettlementToDraft(widget.settlementId);
    if (mounted) {
      if (success) {
        AppSnackbar.success('Pengeluaran ditarik ke draft ✓');
        prov.loadSettlement(widget.settlementId);
      } else {
        AppSnackbar.error(prov.error ?? 'Gagal memindahkan ke draft');
      }
    }
  }

  Future<void> _bulkDeleteExpenses() async {
    final count = _selectedExpenses.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardColor(ctx),
        title: Text('Hapus $count Item', style: TextStyle(color: _creamColor(ctx))),
        content: Text('Hapus $count pengeluaran yang dipilih? Tindakan ini tidak bisa dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;
    final prov = context.read<SettlementProvider>();
    final success = await prov.bulkDeleteExpenses(_selectedExpenses.toList(), widget.settlementId);
    if (success) {
      setState(() => _selectedExpenses.clear());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$count item dihapus ✓'), backgroundColor: AppTheme.success),
        );
      }
    }
  }

  Future<void> _submitSettlement() async {
    if (!mounted) return;
    final prov = context.read<SettlementProvider>();
    final success = await prov.submitSettlement(widget.settlementId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settlement berhasil disubmit ✓'),
          backgroundColor: AppTheme.success,
        ),
      );
      // RELOAD data agar UI terupdate (status jadi SUBMITTED)
      prov.loadSettlement(widget.settlementId);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Settlement disubmit ✓' : (prov.error ?? 'Gagal submit'),
          ),
          backgroundColor: success ? AppTheme.success : AppTheme.danger,
        ),
      );
    }
  }

  Future<void> _viewOriginalAdvance(int advanceId) async {
    if (!mounted) return;

    // Import advance detail screen
    final advanceDetailScreen = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdvanceDetailScreen(advanceId: advanceId),
      ),
    );

    // Refresh settlement data jika kembali dari kasbon
    if (mounted && advanceDetailScreen == true) {
      context.read<SettlementProvider>().loadSettlement(widget.settlementId);
    }
  }

  Future<void> _approveSettlement() async {
    if (!mounted) return;
    final prov = context.read<SettlementProvider>();
    final s = prov.currentSettlement;
    if (s == null) return;

    // Client-side validation: Semua item harus APPROVED
    final expenses = _asMapList(s['expenses']);
    final allApproved = expenses.every((e) => e['status'] == 'approved');

    if (!allApproved) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Gagal: Semua item harus disetujui (Approved) terlebih dahulu sebelum menyetujui Settlement.',
            ),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
      return;
    }

    final sm = ScaffoldMessenger.of(context);
    final success = await prov.approveSettlement(widget.settlementId);

    if (success) {
      sm.showSnackBar(
        const SnackBar(
          content: Text('Settlement disetujui âœ“'),
          backgroundColor: AppTheme.success,
        ),
      );
      // Refresh data
      prov.loadSettlement(widget.settlementId);
    } else {
      if (mounted) {
        sm.showSnackBar(
          SnackBar(
            content: Text(prov.error ?? 'Gagal approve'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  // ignore: unused_element
  Future<void> _rejectSettlement() async {
    final ctrl = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardColor(ctx),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Tolak Settlement', style: TextStyle(color: _creamColor(ctx))),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Berikan alasan mengapa settlement ini ditolak.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                autofocus: true,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Alasan penolakan',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  filled: true,
                  fillColor: AppTheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.divider),
                  ),
                ),
                style: TextStyle(color: _creamColor(ctx), fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              final val = ctrl.text.trim();
              if (val.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Alasan wajib diisi!'), backgroundColor: AppTheme.danger),
                );
                return;
              }
              Navigator.pop(ctx, val);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Tolak Sekarang', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == null || !mounted) return;

    final prov = context.read<SettlementProvider>();
    final success = await prov.rejectAllExpenses(widget.settlementId, result);

    if (!mounted) return;

    if (success) {
      AppSnackbar.success('Settlement berhasil ditolak dan dikembalikan ke draft âœ“');
      prov.loadSettlement(widget.settlementId);
    } else {
      AppSnackbar.error(prov.error ?? 'Gagal menolak settlement');
    }
  }


  Future<void> _downloadReceipt() async {
    try {
      final prov = context.read<SettlementProvider>();
      final bytes = await prov.getReceipt(widget.settlementId);
      final filename =
          'Receipt_${widget.settlementId}_${FileHelper.formatTimestamp()}.pdf';
      if (!mounted) return;

      await FileHelper.saveAndOpenFile(
        context: context,
        bytes: bytes,
        filename: filename,
        successMessage: 'PDF Receipt berhasil disimpan.',
        subFolder: 'Reports/Settlements/Receipt',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  Future<void> _exportSettlementExcel() async {
    try {
      final prov = context.read<SettlementProvider>();
      final bytes = await prov.exportExcel(settlementId: widget.settlementId);
      final filename =
          'Settlement_${widget.settlementId}_${FileHelper.formatTimestamp()}.xlsx';
      if (!mounted) return;

      await FileHelper.saveFile(
        context: context,
        bytes: bytes,
        filename: filename,
        successMessage: 'Excel Settlement berhasil disimpan.',
        subFolder: 'Reports/Settlements/Excel',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  void _showEditSettlementDialog(BuildContext context, Map<String, dynamic> s) {
    final titleCtrl = TextEditingController(text: s['title'] ?? '');
    final prov = context.read<SettlementProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardColor(ctx),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Edit Settlement',
          style: TextStyle(color: _creamColor(ctx)),
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Judul Pengajuan / Nama Trip',
                ),
                style: TextStyle(color: AppTheme.textPrimary),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Judul wajib diisi'),
                    backgroundColor: AppTheme.danger,
                  ),
                );
                return;
              }
              final success = await prov.updateSettlement(
                widget.settlementId,
                title: titleCtrl.text.trim(),
              );
              if (ctx.mounted) Navigator.pop(ctx);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Settlement diupdate ✓'),
                    backgroundColor: AppTheme.success,
                  ),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showEditExpenseDialog(BuildContext context, Map<String, dynamic> exp) {
    final descCtrl = TextEditingController(text: exp['description'] ?? '');
    final amountCtrl = TextEditingController(
      text: (exp['amount'] ?? 0).toStringAsFixed(0),
    );
    final dateCtrl = TextEditingController(text: exp['date'] ?? '');
    final exchangeRateCtrl = TextEditingController(
      text: exp['currency_exchange'] != null
          ? NumberFormat('#,##0', 'id_ID').format(exp['currency_exchange'])
          : '1',
    );
    String? selectedFilePath;
    String? selectedFileName;
    String? selectedSource = exp['source'];
    String selectedCurrency = exp['currency'] ?? 'IDR';

    final prov = context.read<SettlementProvider>();
    // hanya kategori approved yang muncul di dropdown
    // Tampilkan semua kategori agar bisa dipilih staf (pending & approved)
    final allCats = prov.categories;

    // set pilihan awal
    int? selectedParentId;
    Set<int> selectedSubCategoryIds = {};
    final targetId = exp['category_id'] as int?;
    final existingSubIds = exp['subcategory_ids'] as List?;
    if (existingSubIds != null) {
      selectedSubCategoryIds = Set<int>.from(existingSubIds.cast<int>());
    }

    if (targetId != null) {
      // cek kategori utama atau child
      for (final p in allCats) {
        if (p['id'] == targetId) {
          selectedParentId = p['id'];
          break;
        }
        final children = (p['children'] as List?) ?? [];
        for (final c in children) {
          if (c['id'] == targetId || selectedSubCategoryIds.contains(c['id'])) {
            selectedParentId = p['id'];
            if (selectedSubCategoryIds.isEmpty) {
              selectedSubCategoryIds.add(c['id']);
            }
            break;
          }
        }
        if (selectedParentId != null) break;
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final prov = ctx.watch<SettlementProvider>();
          final allCats = prov.categories;

          return AlertDialog(
            backgroundColor: _cardColor(ctx),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Edit Expense',
              style: TextStyle(color: _creamColor(ctx)),
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10), // Ruang ekstra agar label terbaca
                    // dropdown kategori utama
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Kategori Utama',
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    isExpanded: true,
                    dropdownColor: _cardColor(ctx),
                    style: TextStyle(color: _primaryText(ctx)),
                    initialValue: selectedParentId,
                    items: allCats
                        .map(
                        (c) {
                          final isPending = c['status'] == 'pending';
                          return DropdownMenuItem<int>(
                            value: c['id'] as int,
                            child: Text(
                              isPending ? '${c['name']} (Pending)' : c['name'],
                              style: TextStyle(
                                color: isPending ? AppTheme.warning : null,
                              ),
                            ),
                          );
                        },
                        )
                        .toList(),
                    onChanged: (v) => setDialogState(() {
                      selectedParentId = v;
                      selectedSubCategoryIds = {}; // reset sub kategori
                    }),
                  ),
                  const SizedBox(height: 12),

                  // Checklist Sub Kategori
                  if (selectedParentId != null) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Builder(
                        builder: (context) {
                          final parent = allCats.firstWhere(
                            (c) => c['id'] == selectedParentId,
                            orElse: () => {},
                          );
                          final children = (parent['children'] as List?) ?? [];
                          return Text(
                            children.isNotEmpty ? 'Pilih Sub Kategori:' : 'Hanya Kategori Utama',
                            style: TextStyle(
                              color: _secondaryText(ctx),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }
                      ),
                    ),
                    const SizedBox(height: 8),
                    Builder(
                      builder: (context) {
                        final parent = allCats.firstWhere(
                          (c) => c['id'] == selectedParentId,
                          orElse: () => {},
                        );
                        final children = (parent['children'] as List?) ?? [];

                        if (children.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'Kategori ini tidak memiliki sub-kategori.',
                              style: TextStyle(color: _secondaryText(ctx), fontSize: 12),
                            ),
                          );
                        }

                        return Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _dividerColor(ctx)),
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              children: children.map((c) {
                                final subId = c['id'] as int;
                                final isPending = c['status'] == 'pending';
                                final isSelected = selectedSubCategoryIds.contains(subId);

                                return CheckboxListTile(
                                  value: isSelected,
                                  activeColor: AppTheme.primary,
                                  checkColor: Colors.white,
                                  dense: true,
                                  title: Text(
                                    isPending ? '${c['name']} (Pending)' : c['name'],
                                    style: TextStyle(
                                      color: isSelected
                                          ? AppTheme.primary
                                          : (isPending ? AppTheme.warning : _primaryText(ctx)),
                                      fontSize: 13,
                                    ),
                                  ),
                                  onChanged: (val) {
                                    setDialogState(() {
                                      if (val == true) {
                                        selectedSubCategoryIds.add(subId);
                                      } else {
                                        selectedSubCategoryIds.remove(subId);
                                      }
                                    });
                                  },
                                  controlAffinity: ListTileControlAffinity.leading,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      }
                    ),
                  ],

                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: TextButton.icon(
                          onPressed: () => _showAddCategoryDialog(
                            ctx,
                            setDialogState,
                            (newCat) {
                              // coba pilih otomatis kalau bisa
                              final parentID = newCat['parent_id'];
                              final catID = newCat['id'] as int;
                              setDialogState(() {
                                if (parentID != null) {
                                  // ini sub kategori
                                  selectedParentId = parentID;
                                  selectedSubCategoryIds.add(catID);
                                } else {
                                  // ini kategori utama
                                  selectedParentId = catID;
                                  selectedSubCategoryIds = {}; // No sub yet
                                }
                              });
                            },
                            parentId: selectedParentId,
                          ),
                          icon: const Icon(Icons.add_circle_outline, size: 16),
                          label: Text(
                            selectedParentId != null
                                ? 'Tambah Sub-Kategori Baru'
                                : 'Tambah Kategori Baru',
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.category_rounded,
                            color: AppTheme.primary, size: 20),
                        tooltip: 'Pratinjau Struktur Kategori',
                        onPressed: () => showCategoryPreviewDialog(context,
                            context.read<SettlementProvider>().categories),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Deskripsi'),
                    style: TextStyle(color: _primaryText(ctx)),
                    onChanged: (val) {
                      final lower = val.toLowerCase();
                      for (final p in allCats) {
                        final pName = p['name'].toString().toLowerCase();
                        if (lower.contains(pName)) {
                          setDialogState(() {
                            selectedParentId = p['id'];
                          });
                        }
                        final children = (p['children'] as List?) ?? [];
                        for (final c in children) {
                          final cName = c['name'].toString().toLowerCase();
                          if (lower.contains(cName)) {
                            setDialogState(() {
                              selectedParentId = p['id'];
                              selectedSubCategoryIds.add(c['id'] as int);
                            });
                          }
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  // mata uang
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Mata Uang',
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                          ),
                          dropdownColor: _cardColor(ctx),
                          style: TextStyle(color: _primaryText(ctx)),
                          initialValue: selectedCurrency,
                          items: const [
                            DropdownMenuItem(value: 'IDR', child: Text('IDR')),
                            DropdownMenuItem(value: 'USD', child: Text('USD')),
                            DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                            DropdownMenuItem(value: 'GBP', child: Text('GBP')),
                            DropdownMenuItem(value: 'JPY', child: Text('JPY')),
                            DropdownMenuItem(value: 'CNY', child: Text('CNY')),
                            DropdownMenuItem(value: 'AUD', child: Text('AUD')),
                            DropdownMenuItem(value: 'HKD', child: Text('HKD')),
                            DropdownMenuItem(value: 'SGD', child: Text('SGD')),
                            DropdownMenuItem(value: 'TWD', child: Text('TWD')),
                            DropdownMenuItem(value: 'THB', child: Text('THB')),
                            DropdownMenuItem(value: 'MYR', child: Text('MYR')),
                          ],
                          onChanged: (v) => setDialogState(() {
                            selectedCurrency = v ?? 'IDR';
                            if (selectedCurrency == 'IDR') {
                              exchangeRateCtrl.text = '1';
                            }
                          }),
                        ),
                      ),
                      if (selectedCurrency != 'IDR') ...[
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: exchangeRateCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Kurs (ke IDR)',
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                            ),
                            style: TextStyle(color: _primaryText(ctx)),
                            keyboardType: TextInputType.number,
                            inputFormatters: [CurrencyInputFormatter()],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    decoration: InputDecoration(
                      labelText: 'Amount ($selectedCurrency)',
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      hintText: '10.000',
                      hintStyle: TextStyle(
                        color: _secondaryText(ctx).withValues(alpha: 0.5),
                      ),
                    ),
                    style: TextStyle(color: _primaryText(ctx)),
                    keyboardType: TextInputType.number,
                    inputFormatters: [CurrencyInputFormatter()],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dateCtrl,
                    decoration: InputDecoration(
                      labelText: 'Tanggal',
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today, size: 18),
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: ctx,
                            initialDate:
                                DateTime.tryParse(dateCtrl.text) ??
                                DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (d != null) {
                            dateCtrl.text = DateFormat('yyyy-MM-dd').format(d);
                          }
                        },
                      ),
                    ),
                    style: TextStyle(color: _primaryText(ctx)),
                    readOnly: true,
                  ),
                  const SizedBox(height: 12),
                  // dropdown sumber
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Sumber Pembayaran',
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                    ),
                    dropdownColor: _cardColor(ctx),
                    style: TextStyle(color: _primaryText(ctx)),
                    initialValue: selectedSource,
                    items: const [
                      DropdownMenuItem(value: 'BCA', child: Text('BCA')),
                      DropdownMenuItem(value: 'BRI', child: Text('BRI')),
                      DropdownMenuItem(
                        value: 'Mandiri',
                        child: Text('Mandiri'),
                      ),
                      DropdownMenuItem(value: 'BNI', child: Text('BNI')),
                      DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'Advance', child: Text('Advance')),
                      DropdownMenuItem(
                        value: 'Lainnya',
                        child: Text('Lainnya'),
                      ),
                    ],
                    onChanged: (v) => setDialogState(() => selectedSource = v),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: [
                          'jpg',
                          'jpeg',
                          'png',
                          'pdf',
                          'webp',
                        ],
                      );
                      if (result != null) {
                        setDialogState(() {
                          selectedFilePath = result.files.single.path;
                          selectedFileName = result.files.single.name;
                        });
                      }
                    },
                    icon: const Icon(Icons.upload_file_rounded),
                    label: Text(
                      selectedFileName ??
                          exp['evidence_filename'] ??
                          'Ganti Bukti (opsional)',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                // validasi berurutan dari atas ke bawah
                // 1. validasi kategori utama
                if (selectedParentId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Pilih Kategori Utama'),
                      backgroundColor: AppTheme.danger,
                    ),
                  );
                  return;
                }

                final parent = allCats.firstWhere(
                  (c) => c['id'] == selectedParentId,
                  orElse: () => {},
                );
                final children = (parent['children'] as List?) ?? [];

                // 2. validasi sub kategori (jika parent punya child)
                if (children.isNotEmpty && selectedSubCategoryIds.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Pilih Sub Kategori'),
                      backgroundColor: AppTheme.danger,
                    ),
                  );
                  return;
                }

                // 3. validasi deskripsi
                if (descCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Deskripsi harus diisi'),
                      backgroundColor: AppTheme.danger,
                    ),
                  );
                  return;
                }

                // 4. validasi amount
                if (amountCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Amount harus diisi'),
                      backgroundColor: AppTheme.danger,
                    ),
                  );
                  return;
                }

                final amount = double.tryParse(
                  amountCtrl.text.replaceAll('.', '').replaceAll(',', ''),
                );
                if (amount == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Amount harus angka valid'),
                      backgroundColor: AppTheme.danger,
                    ),
                  );
                  return;
                }

                // 5. validasi nominal minimal 100
                final rateForValidation = double.tryParse(exchangeRateCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 1.0;
                final totalIdrValidation = amount * rateForValidation;

                if (totalIdrValidation <= 100) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Nominal ekuivalen Rupiah harus lebih dari Rp 100'),
                      backgroundColor: AppTheme.danger,
                    ),
                  );
                  return;
                }

                // 6. validasi sumber pembayaran
                if (selectedSource == null || selectedSource!.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Pilih Sumber Pembayaran'),
                      backgroundColor: AppTheme.danger,
                    ),
                  );
                  return;
                }

                try {
                  final firstSubId = selectedSubCategoryIds.isNotEmpty ? selectedSubCategoryIds.first : null;
                  final finalCatId = firstSubId ?? selectedParentId!;
                  final subcatIds = selectedSubCategoryIds.toList();
                  final success = await prov.updateExpense(
                    expenseId: exp['id'],
                    settlementId: widget.settlementId,
                    categoryId: finalCatId,
                    categoryIds: subcatIds,
                    description: descCtrl.text.trim(),
                    amount: amount,
                    date: dateCtrl.text,
                    source: selectedSource,
                    currency: selectedCurrency,
                    currencyExchange: rateForValidation,
                    filePath: selectedFilePath,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Expense diupdate ✓'),
                        backgroundColor: AppTheme.success,
                      ),
                    );
                  }
                } catch (e) {
                  // error handled by provider
                }
              },
              child: const Text('Simpan'),
            ),
            ],
          );
        },
      ),
    );
  }

  void _showAddCategoryDialog(
    BuildContext ctx,
    StateSetter setDialogState,
    Function(Map<String, dynamic>) onCreated, {
    int? parentId,
  }) {
    final nameCtrl = TextEditingController();
    final prov = context.read<SettlementProvider>();

    showDialog(
      context: ctx,
      builder: (innerCtx) => AlertDialog(
        backgroundColor: _cardColor(innerCtx),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          parentId != null ? 'Tambah Sub Kategori' : 'Tambah Kategori Utama',
          style: TextStyle(color: _creamColor(innerCtx)),
        ),
        content: SizedBox(
          width: 350,
          child: TextField(
            controller: nameCtrl,
            decoration: InputDecoration(
              labelText: parentId != null
                  ? 'Nama Sub Kategori'
                  : 'Nama Kategori',
            ),
            style: TextStyle(color: AppTheme.textPrimary),
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(innerCtx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final success = await prov.createCategory(
                nameCtrl.text.trim(),
                parentId: parentId,
              );
              if (innerCtx.mounted) Navigator.pop(innerCtx);
              if (success && mounted) {
                // cari kategori baru untuk callback
                final all = prov.categories;
                Map<String, dynamic> found = {};

                // cari kategori yang baru dibuat
                for (final p in all) {
                  if (parentId == null && p['name'] == nameCtrl.text.trim()) {
                    found = p;
                    break;
                  }
                  if (parentId != null && p['id'] == parentId) {
                    final children = (p['children'] as List?) ?? [];
                    for (final c in children) {
                      if (c['name'] == nameCtrl.text.trim()) {
                        found = c;
                        break;
                      }
                    }
                  }
                }

                onCreated(found);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Kategori ditambahkan (menunggu approval manager) ✓',
                    ),
                    backgroundColor: AppTheme.success,
                  ),
                );
              }
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  void _showChecklistDialog(
    int expenseId,
    List<dynamic> checklist,
    String settlementStatus,
  ) {
    final normalizedStatus = settlementStatus.toLowerCase();
    // Bisa edit jika status draft atau rejected (setelah revisi)
    final canEdit = normalizedStatus == 'draft' || normalizedStatus == 'rejected';
    final canAddComment = canEdit;

    List<Map<String, dynamic>> localChecklist = _parseChecklist(checklist);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: _cardColor(ctx),
            title: Text(
              'Rejection Checklist${!canEdit ? ' (Lihat saja)' : ''}',
              style: TextStyle(color: _creamColor(ctx)),
            ),
            content: SizedBox(
              width: 400,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 420),
                child: AppScrollbar(
                  thumbVisibility: true,
                  interactive: true,
                  child: SingleChildScrollView(
                    child: SelectionArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...localChecklist.asMap().entries.map((entry) {
                          final item = entry.value;
                          return _buildChecklistTile(item, canEdit, setModalState);
                        }),
                        if (canAddComment)
                          _buildAddCommentButton(localChecklist, setModalState),
                        if (!canEdit &&
                            (normalizedStatus == 'submitted' ||
                                normalizedStatus == 'revision_submitted'))
                          Container(
                            margin: const EdgeInsets.only(top: 16),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.warning.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppTheme.warning.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: AppTheme.warning,
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Settlement disubmit, Move to Draft untuk edit',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.warning,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Tutup', style: TextStyle(color: AppTheme.textSecondary)),
              ),
              if (canEdit)
                _buildSaveChecklistButton(ctx, expenseId, localChecklist, settlementStatus),
            ],
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _parseChecklist(dynamic checklist) {
    List<Map<String, dynamic>> local = [];
    try {
      dynamic parsed = checklist is String ? jsonDecode(checklist) : checklist;
      if (parsed is List) {
        for (final e in parsed) {
          String text = '';
          bool checked = false;

          if (e is Map) {
            text = (e['text'] ?? '').toString();
            checked = e['checked'] == true;
          } else if (e is String) {
            text = e;
          }

          // FILTER: Jangan tampilkan pesan default manager
          final lowerText = text.toLowerCase();
          if (lowerText.contains('disetujui') ||
              lowerText.contains('disetujui oleh manager')) {
            continue;
          }

          if (text.isNotEmpty) {
            local.add({'text': text, 'checked': checked});
          }
        }
      }
    } catch (_) {}
    return local;
  }
  Widget _buildChecklistTile(Map<String, dynamic> item, bool canEdit, StateSetter setModalState) {
    final alreadyChecked = item['checked'] == true;
    return CheckboxListTile(
      value: alreadyChecked,
      onChanged: canEdit ? (val) => setModalState(() => item['checked'] = val ?? false) : null,
      title: alreadyChecked
          ? SelectionContainer.disabled(
              child: Text(
                item['text'] ?? '',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            )
          : Text(
              item['text'] ?? '',
              style: TextStyle(color: _creamColor(context)),
            ),
      activeColor: AppTheme.success,
      checkColor: Colors.white,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildAddCommentButton(List<Map<String, dynamic>> list, StateSetter setModalState) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: OutlinedButton.icon(
        onPressed: () => setModalState(() => list.add({'text': 'Komentar baru', 'checked': false})),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Tambah komentar'),
      ),
    );
  }

  Widget _buildSaveChecklistButton(BuildContext dialogCtx, int expenseId, List<Map<String, dynamic>> list, String settlementStatus) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      onPressed: () async {
        bool allFinished = list.every((it) => it['checked'] == true);
        final newStatus = allFinished ? 'pending' : 'rejected';
        final prov = context.read<SettlementProvider>();

        final success = await prov.updateExpensePartial(expenseId, widget.settlementId, {
          'notes': jsonEncode(list),
          'status': newStatus,
        });

        if (success) {
          prov.loadSettlement(widget.settlementId);
          if (dialogCtx.mounted) Navigator.pop(dialogCtx);
          AppSnackbar.success('Checklist berhasil disimpan ✓');
        } else {
          if (dialogCtx.mounted) Navigator.pop(dialogCtx);
          AppSnackbar.error('Gagal menyimpan checklist');
        }
      },
      child: const Text('Simpan'),
    );
  }
}

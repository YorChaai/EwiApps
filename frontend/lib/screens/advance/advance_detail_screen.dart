import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/advance_provider.dart';
import '../../providers/settlement_provider.dart';
import '../settlement/settlement_detail_screen.dart';
import '../dashboard_screen.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/file_helper.dart';
import '../../services/api_service.dart';
import '../../widgets/notification_bell_icon.dart';
import '../widgets/page_selector.dart';
import '../widgets/sidebar.dart';

class AdvanceDetailScreen extends StatefulWidget {
  final int advanceId;
  const AdvanceDetailScreen({super.key, required this.advanceId});

  @override
  State<AdvanceDetailScreen> createState() => _AdvanceDetailScreenState();
}

class _AdvanceDetailScreenState extends State<AdvanceDetailScreen> {
  final _currencyFormat = NumberFormat('#,##0', 'id_ID');

  final _itemTableHorizontalCtrl = ScrollController();
  final _itemTableVerticalCtrl = ScrollController();
  final Set<int> _selectedItemIds = {}; // for bulk delete (staf)
  final Set<int> _checkedItemIds = {}; // Checklist manager (approval)
  bool _isManager = false;
  bool _isSaving = false; // Lock mechanism untuk prevent double-tap save

  // Sidebar state (untuk desktop saja)
  bool _sidebarExpanded = true;
  int _pendingSettlements = 0;
  int _pendingAdvances = 0;

  // Helper untuk cek platform dan warna
  bool _isAndroid(BuildContext context) =>
      Theme.of(context).platform == TargetPlatform.android;
  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
  Color _surfaceColor(BuildContext context) =>
      _isDark(context) ? AppTheme.surface : AppTheme.lightSurface;
  Color _cardColor(BuildContext context) =>
      _isDark(context) ? AppTheme.card : AppTheme.lightCard;
  Color _bodyColor(BuildContext context) =>
      _isDark(context) ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
  Color _titleColor(BuildContext context) =>
      _isDark(context) ? AppTheme.cream : AppTheme.lightTextPrimary;
  Color _creamColor(BuildContext context) =>
      _isDark(context) ? AppTheme.cream : AppTheme.lightTextPrimary;

  void _handleMobilePageSelection(int index) {
    if (index == 1) {
      Navigator.pop(context);
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => DashboardScreen(initialTabIndex: index),
      ),
      (route) => false,
    );
  }

  @override
  void dispose() {
    // Remove listeners first to prevent memory leaks
    _itemTableHorizontalCtrl.removeListener(() {});
    _itemTableVerticalCtrl.removeListener(() {});
    _itemTableHorizontalCtrl.dispose();
    _itemTableVerticalCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        final auth = context.read<AuthProvider>();
        setState(() {
          _isManager = auth.isManager;
        });
        context.read<AdvanceProvider>().loadAdvance(widget.advanceId);
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

  Future<void> _handleNotificationTap(String rawPath) async {
    if (!mounted) return;
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
        MaterialPageRoute(
          builder: (_) => SettlementDetailScreen(settlementId: id!),
        ),
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

  Color _statusColor(String status) {
    switch (status) {
      case 'draft':
        return AppTheme.textSecondary;
      case 'submitted':
        return AppTheme.warning;
      case 'approved':
        return AppTheme.success;
      case 'revision_draft':
        return AppTheme.accent;
      case 'revision_submitted':
        return AppTheme.warning;
      case 'revision_rejected':
        return AppTheme.danger;
      case 'in_settlement':
      case 'rejected':
      case 'completed':
      case 'settled':
        return status == 'rejected' ? AppTheme.danger : AppTheme.primary;
      default:
        return AppTheme.textSecondary;
    }
  }

  Color _advanceStatusColor(Map<String, dynamic> advance) {
    final status = (advance['status'] ?? 'draft').toString().toLowerCase();
    if (status == 'in_settlement') {
      final settlementStatus = (advance['settlement_status'] ?? '')
          .toString()
          .toLowerCase();
      final isSettlementApproved =
          settlementStatus == 'approved' || settlementStatus == 'completed';
      return isSettlementApproved ? AppTheme.success : AppTheme.danger;
    }
    return _statusColor(status);
  }

  List<Widget> _buildAdvanceDetailActions(
    BuildContext context,
    Map<String, dynamic> adv,
    AuthProvider auth,
    List<Map<String, dynamic>> workflowItems,
    bool canEditHeader,
    bool canSubmit,
    bool canCreateSettlement,
    bool canStartRevision,
    bool canShowDownloadButtons,
  ) {
    final actions = <Widget>[];

    if (canEditHeader) {
      actions.add(
        OutlinedButton.icon(
          onPressed: () => _showEditAdvanceDialog(context, adv),
          icon: const Icon(Icons.edit_rounded, size: 16),
          label: const Text('Edit'),
        ),
      );
    }

    if (canSubmit) {
      actions.add(
        Builder(
          builder: (context) {
            return ElevatedButton.icon(
              onPressed: _canSubmitAdvanceItems(workflowItems)
                  ? () => _submitAdvance()
                  : null,
              icon: const Icon(Icons.send_rounded, size: 16),
              label: Text(
                adv['status'] == 'revision_draft' ||
                        adv['status'] == 'revision_rejected'
                    ? 'Submit Revisi'
                    : 'Submit',
              ),
            );
          },
        ),
      );
    }

    if (auth.user?['id'] == adv['user_id'] &&
        (adv['status'] == 'submitted' ||
            adv['status'] == 'rejected' ||
            adv['status'] == 'revision_submitted' ||
            adv['status'] == 'revision_rejected')) {
      actions.add(
        OutlinedButton.icon(
          onPressed: _moveToDraft,
          icon: const Icon(Icons.undo_rounded, size: 16),
          label: const Text('Move to Draft'),
          style: OutlinedButton.styleFrom(foregroundColor: AppTheme.warning),
        ),
      );
    }

    if (_isManager &&
        (adv['status'] == 'submitted' ||
            adv['status'] == 'revision_submitted')) {
      actions.add(
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
          onPressed: _canApproveAdvanceItems(workflowItems)
              ? () => _approveAdvance()
              : null,
          icon: const Icon(Icons.check_circle_outline, size: 16),
          label: Text(
            adv['status'] == 'revision_submitted'
                ? 'Approve Revisi ${adv['active_revision_no'] ?? ''}'
                : 'Approve',
          ),
        ),
      );
    }

    if (canCreateSettlement) {
      actions.add(
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accent,
            foregroundColor: Colors.white,
          ),
          onPressed: () => _createSettlement(),
          icon: const Icon(Icons.copy_all_rounded, size: 16),
          label: const Text('Salin ke Settlement'),
        ),
      );
    }

    if (adv['settlement_id'] != null && adv['settlement_id'] != 0) {
      actions.add(
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: AppTheme.primary),
          onPressed: () => _viewSettlement(adv['settlement_id']),
          icon: const Icon(Icons.visibility_rounded, size: 16),
          label: const Text('Lihat Settlement'),
        ),
      );
    }

    if (canStartRevision) {
      actions.add(
        ElevatedButton.icon(
          onPressed: () => _startRevision(),
          icon: const Icon(Icons.add_circle_outline, size: 16),
          label: Text(
            'Tambah Revisi ${(adv['approved_revision_no'] ?? 0) + 1}',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accent,
            foregroundColor: Colors.white,
          ),
        ),
      );
    }

    if (canShowDownloadButtons) {
      actions.add(
        OutlinedButton.icon(
          onPressed: () => _downloadReceipt(),
          icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
          label: const Text('PDF'),
        ),
      );
      actions.add(
        OutlinedButton.icon(
          onPressed: () => _exportAdvanceExcel(),
          icon: const Icon(Icons.table_chart_rounded, size: 16),
          label: const Text('Excel'),
        ),
      );
    }

    return actions;
  }

  Widget _buildMobileAdvanceActionBar(
    BuildContext context,
    Map<String, dynamic> adv,
    AuthProvider auth,
    List<Map<String, dynamic>> workflowItems,
    bool canEditHeader,
    bool canSubmit,
    bool canCreateSettlement,
    bool canStartRevision,
    bool canShowDownloadButtons,
  ) {
    final actions = _buildAdvanceDetailActions(
      context,
      adv,
      auth,
      workflowItems,
      canEditHeader,
      canSubmit,
      canCreateSettlement,
      canStartRevision,
      canShowDownloadButtons,
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
            if (_selectedItemIds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  onPressed: _bulkDeleteItems,
                  icon: const Icon(
                    Icons.delete_sweep_rounded,
                    color: AppTheme.danger,
                  ),
                  tooltip: 'Hapus ${_selectedItemIds.length} item pilihan',
                ),
              ),
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _advanceStatusColor(adv).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                (adv['status'] as String).toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: _advanceStatusColor(adv),
                ),
              ),
            ),
            ...actions.map(
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

  Future<void> _startRevision() async {
    final prov = context.read<AdvanceProvider>();
    final success = await prov.startRevision(widget.advanceId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Revisi dibuka. Tambahkan item tambahan lalu submit.'
              : (prov.error ?? 'Gagal memulai revisi'),
        ),
        backgroundColor: success ? AppTheme.success : AppTheme.danger,
      ),
    );
    if (success) {
      prov.loadAdvance(widget.advanceId);
    }
  }

  Future<void> _createSettlement() async {
    final prov = context.read<AdvanceProvider>();
    final settlement = await prov.createSettlementFromAdvance(widget.advanceId);
    if (!mounted) return;
    if (settlement == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(prov.error ?? 'Gagal membuat settlement'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Draft settlement berhasil dibuat')),
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettlementDetailScreen(settlementId: settlement['id']),
      ),
    ).then((_) {
      if (mounted) {
        context.read<AdvanceProvider>().loadAdvance(widget.advanceId);
      }
    });
  }

  Future<void> _viewSettlement(int settlementId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettlementDetailScreen(settlementId: settlementId),
      ),
    );
    // Refresh advance data when coming back from settlement
    if (mounted) {
      context.read<AdvanceProvider>().loadAdvance(widget.advanceId);
    }
  }

  bool _canEditCurrentRevision(
    Map<String, dynamic> advance,
    Map<String, dynamic> item,
  ) {
    final status = (advance['status'] ?? '').toString();
    final itemRevisionNo = item['revision_no'] ?? 0;
    if (status == 'draft' || status == 'rejected') {
      return itemRevisionNo == 0;
    }
    if (status == 'revision_draft' || status == 'revision_rejected') {
      return itemRevisionNo == (advance['active_revision_no'] ?? -1);
    }
    return false;
  }

  Widget _buildWarningBox(String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
      ),
      child: Text(text, style: TextStyle(color: AppTheme.cream)),
    );
  }

  String _displayAdvanceTitle(Map<String, dynamic> advance) {
    final type = (advance['advance_type'] ?? 'single').toString().toLowerCase();
    final title = (advance['title'] ?? '').toString();

    if (type == 'single') {
      final items = List<Map<String, dynamic>>.from(
        advance['items'] as List? ?? [],
      );
      if (items.isNotEmpty) {
        // Sort by ID descending to get the latest item
        items.sort((a, b) => (b['id'] ?? 0).compareTo(a['id'] ?? 0));
        final latestItem = items.first;
        final desc = latestItem['description']?.toString() ?? '';
        return desc.isNotEmpty
            ? desc
            : (title.isNotEmpty ? title : 'Kasbon Mandiri');
      }
      return title.isNotEmpty ? title : 'Kasbon Mandiri';
    }
    return title.isEmpty ? 'Detail Kasbon' : title;
  }

  bool _hasUncheckedChecklist(Map<String, dynamic> item) {
    final checklist = _parseChecklist(item['notes']);
    return checklist.isNotEmpty &&
        checklist.any((entry) => entry['checked'] != true);
  }

  bool _canSubmitAdvanceItems(List<Map<String, dynamic>> items) {
    if (items.isEmpty) return false;
    return !items.any(_hasUncheckedChecklist);
  }

  bool _canApproveAdvanceItems(List<Map<String, dynamic>> items) {
    if (items.isEmpty) return false;
    return items.every(
      (item) =>
          (item['status'] ?? 'pending').toString().toLowerCase() == 'approved',
    );
  }

  List<Map<String, dynamic>> _workflowItems(
    Map<String, dynamic> advance,
    List<Map<String, dynamic>> items,
  ) {
    final status = (advance['status'] ?? '').toString().toLowerCase();
    final activeRevisionNo =
        int.tryParse('${advance['active_revision_no'] ?? ''}') ?? -1;

    if (status == 'revision_draft' ||
        status == 'revision_rejected' ||
        status == 'revision_submitted') {
      return items
          .where(
            (item) =>
                (int.tryParse('${item['revision_no'] ?? 0}') ?? 0) ==
                activeRevisionNo,
          )
          .toList();
    }

    return items
        .where(
          (item) => (int.tryParse('${item['revision_no'] ?? 0}') ?? 0) == 0,
        )
        .toList();
  }

  Future<void> _submitAdvance() async {
    final prov = context.read<AdvanceProvider>();
    final success = await prov.submitAdvance(widget.advanceId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kasbon berhasil disubmit untuk approval'),
        ),
      );
      prov.loadAdvance(widget.advanceId);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            prov.error ?? 'Submit gagal. Cek checklist komentar revisi.',
          ),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  Future<void> _approveAdvance() async {
    final prov = context.read<AdvanceProvider>();
    final success = await prov.approveAdvance(widget.advanceId);
    if (success && mounted) {
      prov.loadAdvance(widget.advanceId);
    }
  }

  Future<void> _downloadReceipt() async {
    try {
      final prov = context.read<AdvanceProvider>();
      final bytes = await prov.getAdvanceReceipt(widget.advanceId);
      final timestamp = FileHelper.formatTimestamp(DateTime.now());
      final filename = 'Kasbon_${widget.advanceId}_$timestamp.pdf';

      if (mounted) {
        await FileHelper.saveAndOpenFile(
          context: context,
          bytes: bytes,
          filename: filename,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal export PDF: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  Future<void> _exportAdvanceExcel() async {
    try {
      final prov = context.read<AdvanceProvider>();
      final bytes = await prov.exportExcel(advanceId: widget.advanceId);
      final timestamp = FileHelper.formatTimestamp(DateTime.now());
      final filename = 'Kasbon_${widget.advanceId}_$timestamp.xlsx';

      if (mounted) {
        await FileHelper.saveAndOpenFolder(
          context: context,
          bytes: bytes,
          filename: filename,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal export Excel: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  void _showEditAdvanceDialog(
    BuildContext context,
    Map<String, dynamic> advance,
  ) {
    final titleCtrl = TextEditingController(text: advance['title']);
    final descCtrl = TextEditingController(text: advance['description']);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardColor(ctx),
        title: Text(
          'Edit Kasbon',
          style: TextStyle(color: _creamColor(ctx)),
        ),
        content: advance['advance_type'] == 'batch'
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Judul Pengajuan / Nama Trip',
                    ),
                    style: TextStyle(color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Deskripsi'),
                    style: TextStyle(color: AppTheme.textPrimary),
                    maxLines: 2,
                  ),
                ],
              )
            : const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Judul Kasbon Single akan otomatis diperbarui mengikuti isi item.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) return;
              await context.read<AdvanceProvider>().updateAdvance(
                advance['id'],
                titleCtrl.text.trim(),
                descCtrl.text.trim(),
              );
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                context.read<AdvanceProvider>().loadAdvance(advance['id']);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog(BuildContext context, [Map<String, dynamic>? item]) {
    final isEditing = item != null;
    final reportYear = context.read<AdvanceProvider>().reportYear;
    final now = DateTime.now();
    final defaultDate = reportYear == 0 || reportYear == now.year ? now : DateTime(reportYear, 12, 31);
    final descCtrl = TextEditingController(text: item?['description']);
    final amountCtrl = TextEditingController(
      text: item?['estimated_amount'] != null
          ? NumberFormat('#,##0', 'id_ID').format(item!['estimated_amount'])
          : '',
    );

    int? selectedParentId;
    int? selectedSubCategoryId;
    String? selectedFilePath;
    String? selectedFileName;
    String? selectedSource = item?['source'];
    String selectedCurrency = item?['currency'] ?? 'IDR';
    final exchangeRateCtrl = TextEditingController(
      text: item?['currency_exchange'] != null
          ? NumberFormat('#,##0', 'id_ID').format(item!['currency_exchange'])
          : '1',
    );
    final dateCtrl = TextEditingController(
      text: item?['date'] ?? DateFormat('yyyy-MM-dd').format(defaultDate),
    );

    // Load initial values if editing
    final catProv = context.read<SettlementProvider>();
    final allCats = _uniqueById(_asMapList(catProv.categories));

    if (isEditing && item['category_id'] != null) {
      final catId = item['category_id'] as int;
      for (final p in allCats) {
        if (p['id'] == catId) {
          selectedParentId = p['id'];
          break;
        }
        final children = _asMapList(p['children'] as List?);
        for (final c in children) {
          if (c['id'] == catId) {
            selectedParentId = p['id'];
            selectedSubCategoryId = c['id'];
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
          final categories = _uniqueById(_asMapList(prov.categories));

          // re-sync selected parent & child with fresh data from provider
          final parentIds = categories
              .map((c) => c['id'])
              .whereType<int>()
              .toSet();
          final effectiveParentId = parentIds.contains(selectedParentId)
              ? selectedParentId
              : null;

          final parent = effectiveParentId != null
              ? categories.firstWhere(
                  (c) => c['id'] == effectiveParentId,
                  orElse: () => {},
                )
              : {};
          final children = _uniqueById(_asMapList(parent['children'] as List?));

          final childIds = children
              .map((c) => c['id'])
              .whereType<int>()
              .toSet();
          final effectiveSubCategoryId =
              childIds.contains(selectedSubCategoryId)
              ? selectedSubCategoryId
              : null;

          return AlertDialog(
            backgroundColor: _cardColor(ctx),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              isEditing ? 'Edit Item Kasbon' : 'Tambah Item Kasbon',
              style: TextStyle(color: _creamColor(ctx)),
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // dropdown kategori utama
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: 'Kategori'),
                      dropdownColor: AppTheme.card,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      initialValue: effectiveParentId,
                      items: categories.map((c) {
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
                      }).toList(),
                      onChanged: (v) => setDialogState(() {
                        selectedParentId = v;
                        selectedSubCategoryId = null; // reset sub
                      }),
                    ),
                    const SizedBox(height: 12),

                    // dropdown sub kategori
                    Builder(
                      builder: (context) {
                        final isEnabled = effectiveParentId != null;
                        return DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Sub-Kategori',
                          ),
                          dropdownColor: AppTheme.card,
                          style: const TextStyle(color: AppTheme.textPrimary),
                          initialValue: effectiveSubCategoryId,
                          hint: isEnabled && children.isEmpty
                              ? const Text(
                                  'Buat Sub Kategori (+)',
                                  style: TextStyle(color: AppTheme.warning),
                                )
                              : null,
                          disabledHint: const Text('Pilih Kategori Utama dulu'),
                          items: isEnabled && children.isNotEmpty
                              ? children.map((c) {
                                  final isPending = c['status'] == 'pending';
                                  return DropdownMenuItem<int>(
                                    value: c['id'] as int,
                                    child: Text(
                                      isPending
                                          ? '${c['name']} (Pending)'
                                          : c['name'],
                                      style: TextStyle(
                                        color: isPending
                                            ? AppTheme.warning
                                            : null,
                                      ),
                                    ),
                                  );
                                }).toList()
                              : [],
                          onChanged: isEnabled && children.isNotEmpty
                              ? (v) => setDialogState(
                                  () => selectedSubCategoryId = v,
                                )
                              : null,
                        );
                      },
                    ),

                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => _showAddCategoryDialog(
                          ctx,
                          setDialogState,
                          (newCat) {
                            final parentID = newCat['parent_id'];
                            final catID = newCat['id'] as int;
                            setDialogState(() {
                              if (parentID != null) {
                                selectedParentId = parentID;
                                selectedSubCategoryId = catID;
                              } else {
                                selectedParentId = catID;
                                selectedSubCategoryId = null;
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
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(labelText: 'Deskripsi'),
                      style: const TextStyle(color: AppTheme.textPrimary),
                      onChanged: (val) {
                        final lower = val.toLowerCase();
                        for (final p in categories) {
                          if (lower.contains(
                            p['name'].toString().toLowerCase(),
                          )) {
                            setDialogState(() {
                              selectedParentId = p['id'];
                              selectedSubCategoryId = null;
                            });
                          }
                          final childrenList = _asMapList(
                            p['children'] as List?,
                          );
                          for (final c in childrenList) {
                            if (lower.contains(
                              c['name'].toString().toLowerCase(),
                            )) {
                              setDialogState(() {
                                selectedParentId = p['id'];
                                selectedSubCategoryId = c['id'];
                              });
                              return;
                            }
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: dateCtrl,
                      decoration: InputDecoration(
                        labelText: 'Tanggal',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today, size: 18),
                        onPressed: () async {
                          final initialDate =
                              DateTime.tryParse(dateCtrl.text) ?? defaultDate;
                          final d = await showDatePicker(
                            context: ctx,
                            initialDate: initialDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                            if (d != null) {
                              dateCtrl.text = DateFormat(
                                'yyyy-MM-dd',
                              ).format(d);
                            }
                          },
                        ),
                      ),
                      style: const TextStyle(color: AppTheme.textPrimary),
                      readOnly: true,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Mata Uang',
                            ),
                            dropdownColor: AppTheme.card,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            initialValue: selectedCurrency,
                            items: const [
                              DropdownMenuItem(
                                value: 'IDR',
                                child: Text('IDR'),
                              ),
                              DropdownMenuItem(
                                value: 'USD',
                                child: Text('USD'),
                              ),
                              DropdownMenuItem(
                                value: 'EUR',
                                child: Text('EUR'),
                              ),
                              DropdownMenuItem(
                                value: 'GBP',
                                child: Text('GBP'),
                              ),
                              DropdownMenuItem(
                                value: 'JPY',
                                child: Text('JPY'),
                              ),
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
                              ),
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                              ),
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
                        hintStyle: const TextStyle(color: AppTheme.textSecondary),
                      ),
                      style: const TextStyle(color: AppTheme.textPrimary),
                      keyboardType: TextInputType.number,
                      inputFormatters: [CurrencyInputFormatter()],
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
                            (item?['evidence_filename'] ??
                                'Upload Berkas (opsional)'),
                      ),
                    ),
                    if (selectedFileName != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '✓ $selectedFileName',
                          style: const TextStyle(
                            color: AppTheme.success,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              if (isEditing)
                TextButton(
                  onPressed: () => _deleteItem(item['id']),
                  child: const Text(
                    'Hapus Item',
                    style: TextStyle(color: AppTheme.danger),
                  ),
                ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: _isSaving
                    ? null
                    : () async {
                        // Validasi form
                        if (selectedParentId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Pilih Kategori Utama'),
                              backgroundColor: AppTheme.danger,
                            ),
                          );
                          return;
                        }

                        final parent = categories.firstWhere(
                          (c) => c['id'] == selectedParentId,
                          orElse: () => {},
                        );
                        final children = _asMapList(
                          parent['children'] as List?,
                        );
                        if (children.isNotEmpty &&
                            selectedSubCategoryId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Pilih Sub Kategori'),
                              backgroundColor: AppTheme.danger,
                            ),
                          );
                          return;
                        }

                        if (descCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Deskripsi harus diisi'),
                              backgroundColor: AppTheme.danger,
                            ),
                          );
                          return;
                        }

                        final amount =
                            double.tryParse(
                              amountCtrl.text
                                  .replaceAll('.', '')
                                  .replaceAll(',', ''),
                            ) ??
                            0;
                        if (amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Isi nominal dengan nilai yang benar.',
                              ),
                              backgroundColor: AppTheme.danger,
                            ),
                          );
                          return;
                        }
                        final rateForValidation = double.tryParse(exchangeRateCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 1.0;
                        final totalIdrValidation = amount * rateForValidation;

                        if (totalIdrValidation <= 100) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Nominal ekuivalen Rupiah harus lebih dari Rp 100'),
                              backgroundColor: AppTheme.danger,
                            ),
                          );
                          return;
                        }

                        // Lock mechanism - prevent double-tap
                        setState(() => _isSaving = true);

                        try {
                          final prov = context.read<AdvanceProvider>();
                          final finalCatId =
                              selectedSubCategoryId ?? selectedParentId!;
                          final rate = rateForValidation;

                          bool success;

                          if (isEditing) {
                            // Edit mode - update item existing
                            success = await prov.updateAdvanceItem(
                              item['id'],
                              finalCatId,
                              descCtrl.text.trim(),
                              amount,
                              filePath: selectedFilePath,
                              date: dateCtrl.text,
                              source: selectedSource,
                              currency: selectedCurrency,
                              currencyExchange: rate,
                            );
                          } else {
                            // Add mode - cek apakah ini item pertama
                            final currentAdvance = prov.currentAdvance;
                            final items =
                                currentAdvance?['items'] as List? ?? [];
                            final isFirstItem = items.isEmpty;

                            if (isFirstItem) {
                              // ITEM PERTAMA - Auto-save Kasbon + Item
                              success = await prov
                                  .saveFirstItemAndCommitAdvance(
                                    advanceId: widget.advanceId,
                                    categoryId: finalCatId,
                                    desc: descCtrl.text.trim(),
                                    amount: amount,
                                    filePath: selectedFilePath,
                                    date: dateCtrl.text,
                                    source: selectedSource,
                                    currency: selectedCurrency,
                                    currencyExchange: rate,
                                  );
                            } else {
                              // Item selanjutnya - save item saja
                              success = await prov.addAdvanceItem(
                                widget.advanceId,
                                finalCatId,
                                descCtrl.text.trim(),
                                amount,
                                filePath: selectedFilePath,
                                date: dateCtrl.text,
                                source: selectedSource,
                                currency: selectedCurrency,
                                currencyExchange: rate,
                              );
                            }
                          }

                          if (ctx.mounted) Navigator.pop(ctx);
                          if (success && mounted) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isEditing
                                      ? 'Item diupdate ✓'
                                      : 'Item ditambahkan ✓',
                                ),
                                backgroundColor: AppTheme.success,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                            prov.loadAdvance(widget.advanceId);
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
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final prov = context.watch<AdvanceProvider>();
    final adv = prov.currentAdvance;
    final advanceStatus = (adv?['status'] ?? '').toString().toLowerCase();
    final isAndroid = _isAndroid(context);

    // PAKSA: Sidebar TIDAK muncul di Android
    final showSidebar = !isAndroid;
    final canShowDownloadButtons = [
      'approved',
      'in_settlement',
      'completed',
    ].contains(advanceStatus);
    final canEditHeader =
        adv != null &&
        auth.user?['id'] == adv['user_id'] &&
        (adv['status'] == 'draft' || adv['status'] == 'rejected');
    final canSubmit =
        adv != null &&
        auth.user?['id'] == adv['user_id'] &&
        [
          'draft',
          'rejected',
          'revision_draft',
          'revision_rejected',
        ].contains(adv['status']);
    final canEditItems =
        adv != null &&
        auth.user?['id'] == adv['user_id'] &&
        [
          'draft',
          'rejected',
          'revision_draft',
          'revision_rejected',
        ].contains(adv['status']);
    final isSingleAdvance =
        (adv?['advance_type'] ?? 'single').toString().toLowerCase() == 'single';
    final canCreateSettlement =
        adv != null &&
        auth.user?['id'] == adv['user_id'] &&
        ['approved', 'in_settlement'].contains(adv['status']) &&
        adv['settlement_id'] == null;
    final canStartRevision =
        adv != null &&
        auth.user?['id'] == adv['user_id'] &&
        ['approved', 'in_settlement'].contains(adv['status']) &&
        adv['active_revision_no'] == null &&
        ![
          'submitted',
          'approved',
          'completed',
        ].contains(adv['settlement_status']);

    final items = adv != null
        ? List<Map<String, dynamic>>.from(adv['items'] ?? [])
        : <Map<String, dynamic>>[];
    final canAddItems = canEditItems && !(isSingleAdvance && items.isNotEmpty);
    final workflowItems = adv != null
        ? _workflowItems(adv, items)
        : <Map<String, dynamic>>[];

    Future<void> handlePop(bool didPop) async {
      if (didPop) return;

      // Cleanup empty draft - jika belum ada item dan masih unsaved
      if (prov.unsavedDraft && adv != null) {
        final items = adv['items'] as List? ?? [];
        if (items.isEmpty) {
          // Tampilkan dialog konfirmasi
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: _cardColor(ctx),
              title: const Text(
                'Hapus Kasbon Kosong?',
                style: TextStyle(color: AppTheme.cream),
              ),
              content: const Text(
                'Kasbon ini belum memiliki item. Hapus kasbon kosong ini?',
                style: TextStyle(color: AppTheme.textSecondary),
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
            await prov.cleanupEmptyDraft(adv['id']);
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
                currentIndex: 1,
                isManager: auth.isManager,
                fullName: auth.fullName,
                role: auth.roleDisplayName,
                onNavTap: (index) {
                  // Navigate sesuai index
                  if (index == 1) {
                    // Klik Kasbon → Ke Kasbon List (tab 1 di Dashboard)
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) =>
                            DashboardScreen(initialTabIndex: 1),
                      ),
                      (route) => false,
                    );
                  } else if (index == 0) {
                    // Klik Settlement → Ke Settlement List (tab 0 di Dashboard)
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) =>
                            DashboardScreen(initialTabIndex: 0),
                      ),
                      (route) => false,
                    );
                  } else if (index == 2 && auth.isManager) {
                    // Klik Laporan → Ke Laporan (tab 2 di Dashboard)
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) =>
                            DashboardScreen(initialTabIndex: 2),
                      ),
                      (route) => false,
                    );
                  } else if (index == 3 && auth.isManager) {
                    // Klik Kategori → Ke Kategori (tab 3 di Dashboard)
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) =>
                            DashboardScreen(initialTabIndex: 3),
                      ),
                      (route) => false,
                    );
                  } else if (index == 4 && auth.isManager) {
                    // Klik Settings → Ke Settings (tab 4 di Dashboard)
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) =>
                            DashboardScreen(initialTabIndex: 4),
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
            // Content detail advance
            Expanded(
              child: Scaffold(
                appBar: isAndroid
                    ? AppBar(
                        toolbarHeight: 64,
                        elevation: 0,
                        backgroundColor: _surfaceColor(context),
                        centerTitle: false,
                        title: Row(
                          children: [
                            // User badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                auth.fullName.isNotEmpty
                                    ? auth.fullName[0].toUpperCase()
                                    : 'M',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // User name - Expanded untuk avoid overflow
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    auth.fullName.split(' ').first,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: _titleColor(context),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    adv != null
                                        ? _displayAdvanceTitle(adv)
                                        : 'Detail Kasbon',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: _bodyColor(context),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            PageSelector(
                              currentIndex: 1,
                              isManager: auth.isManager,
                              compact: true,
                              onChanged: _handleMobilePageSelection,
                            ),
                          ],
                        ),
                        actions: [
                          // Notification Bell
                          NotificationBellIcon(
                            onNotificationTap: _handleNotificationTap,
                          ),
                          const SizedBox(width: 4),
                          // Logout Button
                          IconButton(
                            icon: const Icon(Icons.logout_rounded, size: 20),
                            onPressed: () => auth.logout(),
                            color: _bodyColor(context),
                            tooltip: 'Logout',
                          ),
                          const SizedBox(width: 8),
                        ],
                      )
                    : AppBar(
                        title: Text(
                          adv != null
                              ? _displayAdvanceTitle(adv)
                              : 'Detail Kasbon',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                        actions: [
                          if (adv != null) ...[
                            if (_selectedItemIds.isNotEmpty)
                              IconButton(
                                onPressed: _bulkDeleteItems,
                                icon: const Icon(
                                  Icons.delete_sweep_rounded,
                                  color: AppTheme.danger,
                                ),
                                tooltip:
                                    'Hapus ${_selectedItemIds.length} item pilihan',
                              ),
                            Container(
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _advanceStatusColor(
                                  adv,
                                ).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                (adv['status'] as String).toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: _advanceStatusColor(adv),
                                ),
                              ),
                            ),
                            ..._buildAdvanceDetailActions(
                              context,
                              adv,
                              auth,
                              workflowItems,
                              canEditHeader,
                              canSubmit,
                              canCreateSettlement,
                              canStartRevision,
                              canShowDownloadButtons,
                            ),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                body: prov.loading || adv == null
                    ? Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                        ),
                      )
                    : isAndroid
                    ? Column(
                        children: [
                          _buildMobileAdvanceActionBar(
                            context,
                            adv,
                            auth,
                            workflowItems,
                            canEditHeader,
                            canSubmit,
                            canCreateSettlement,
                            canStartRevision,
                            canShowDownloadButtons,
                          ),
                          Expanded(
                            child: _buildContent(
                              context,
                              adv,
                              auth,
                              prov,
                              items,
                            ),
                          ),
                        ],
                      )
                    : _buildContent(context, adv, auth, prov, items),
                floatingActionButton: canAddItems
                    ? FloatingActionButton.extended(
                        onPressed: () => _showAddItemDialog(context),
                        icon: const Icon(Icons.add),
                        label: Text(
                          adv['status'] == 'revision_draft' ||
                                  adv['status'] == 'revision_rejected'
                              ? 'Tambah Item Revisi'
                              : 'Tambah Item Kasbon',
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
    Map<String, dynamic> adv,
    AuthProvider auth,
    AdvanceProvider prov,
    List<Map<String, dynamic>> items,
  ) {
    final approved = adv['approved_amount'] ?? 0;
    final title = _displayAdvanceTitle(adv);
    final warnings = List<String>.from(adv['policy_warnings'] ?? []);
    final canEditItems =
        auth.user?['id'] == adv['user_id'] &&
        [
          'draft',
          'rejected',
          'revision_draft',
          'revision_rejected',
        ].contains(adv['status']);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.cream,
            ),
          ),
          if ((adv['description'] ?? '').toString().trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              adv['description'],
              style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
            ),
          ],
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 650;
              final currentTotal = items.fold(
                0.0,
                (sum, item) => sum + (item['estimated_amount'] ?? 0),
              );

              final cards = [
                _SummaryCard(
                  icon: Icons.receipt_long_rounded,
                  label: 'Total Pengajuan',
                  value: 'Rp ${_currencyFormat.format(currentTotal)}',
                  color: AppTheme.primary,
                ),
                _SummaryCard(
                  icon: Icons.verified_rounded,
                  label: 'Approved Amount',
                  value: 'Rp ${_currencyFormat.format(approved)}',
                  color: AppTheme.success,
                ),
                _SummaryCard(
                  icon: Icons.list_alt_rounded,
                  label: 'Total Item',
                  value: '${items.length} item',
                  color: AppTheme.accent,
                ),
              ];

              if (isNarrow) {
                return Column(
                  children: [
                    cards[0],
                    const SizedBox(height: 12),
                    cards[1],
                    const SizedBox(height: 12),
                    cards[2],
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 16),
                  Expanded(child: cards[1]),
                  const SizedBox(width: 16),
                  Expanded(child: cards[2]),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.person_outline,
                color: AppTheme.textSecondary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Dibuat oleh: ${adv['requester_name'] ?? '-'}',
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
                adv['created_at'] != null
                    ? adv['created_at'].toString().substring(0, 10)
                    : '-',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
          if (adv['notes'] != null && adv['notes'].toString().isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: AppTheme.warning, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      adv['notes'],
                      style: TextStyle(color: AppTheme.cream),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (warnings.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...warnings.map(_buildWarningBox),
          ],
          const SizedBox(height: 28),
          const Text(
            'Rincian Item Kasbon',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.cream,
            ),
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            _buildEmptyState(canEditItems)
          else
            _buildItemsTable(items, adv, auth),
          const SizedBox(height: 100), // Padding extra agar tidak tertabrak FAB
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool canEditItems) {
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
            'Belum ada item ditambahkan',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          if (canEditItems) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showAddItemDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Item Sekarang'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemsTable(
    List<Map<String, dynamic>> items,
    Map<String, dynamic> adv,
    AuthProvider auth,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Scrollbar(
          controller: _itemTableVerticalCtrl,
          thumbVisibility: true,
          trackVisibility: true,
          child: SingleChildScrollView(
            controller: _itemTableVerticalCtrl,
            child: Scrollbar(
              controller: _itemTableHorizontalCtrl,
              thumbVisibility: true,
              trackVisibility: true,
              notificationPredicate: (notification) =>
                  notification.metrics.axis == Axis.horizontal,
              child: SingleChildScrollView(
                controller: _itemTableHorizontalCtrl,
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(_surfaceColor(context)),
                  dataRowColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.hovered)) {
                      return _isDark(context) ? AppTheme.cardHover : AppTheme.lightCardHover;
                    }
                    return _cardColor(context);
                  }),
                  columns: [
                    DataColumn(
                      label: Text(
                        'No',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.cream,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Subkategori',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.cream,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Tanggal',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.cream,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Deskripsi',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.cream,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Estimasi Biaya',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.cream,
                        ),
                      ),
                      numeric: true,
                    ),
                    DataColumn(
                      label: Text(
                        'Status',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.cream,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Berkas',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.cream,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Aksi',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.cream,
                        ),
                      ),
                    ),
                  ],
                  rows: items.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    final itemId = item['id'] as int;
                    final itemStatus = (item['status'] ?? 'pending')
                        .toString()
                        .toLowerCase();
                    final isItemApproved = itemStatus == 'approved';
                    final canEditRow = _canEditCurrentRevision(adv, item);
                    final isSubmittedState =
                        adv['status'] == 'submitted' ||
                        adv['status'] == 'revision_submitted';
                    final showChecklist =
                        _isManager && isSubmittedState && !isItemApproved;

                    String subCat = '-';
                    final catName = item['category_name'] ?? '';
                    if (catName.contains(' > ')) {
                      final parts = catName.split(' > ');
                      subCat = parts.last;
                    } else {
                      subCat = catName;
                    }

                    return DataRow(
                      selected: showChecklist
                          ? _checkedItemIds.contains(itemId)
                          : _selectedItemIds.contains(itemId),
                      onSelectChanged: (selected) {
                        setState(() {
                          if (showChecklist) {
                            if (selected == true) {
                              _checkedItemIds.add(itemId);
                            } else {
                              _checkedItemIds.remove(itemId);
                            }
                          } else {
                            if (selected == true) {
                              _selectedItemIds.add(itemId);
                            } else {
                              _selectedItemIds.remove(itemId);
                            }
                          }
                        });
                      },
                      cells: [
                        DataCell(Text('${idx + 1}')),
                        DataCell(Text(subCat)),
                        DataCell(Text(item['date'] ?? '-')),
                        DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 200),
                            child: Text(
                              item['description'] ?? '',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            'Rp ${_currencyFormat.format(item['estimated_amount'])}',
                          ),
                        ),
                        DataCell(
                          Builder(
                            builder: (context) {
                              final itemStatus = (item['status'] ?? 'pending')
                                  .toString()
                                  .toUpperCase();
                              Color statusColor = AppTheme.warning;

                              if (itemStatus == 'APPROVED') {
                                statusColor = AppTheme.success;
                              } else if (itemStatus == 'REJECTED') {
                                statusColor = AppTheme.danger;
                              }

                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      itemStatus,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                  if ((itemStatus == 'REJECTED' ||
                                          itemStatus == 'PENDING') &&
                                      item['notes'] != null &&
                                      (item['notes'] as String).isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Builder(
                                        builder: (context) {
                                          try {
                                            final List<dynamic> checklist =
                                                _parseChecklist(item['notes']);
                                            if (checklist.isEmpty) {
                                              return const SizedBox.shrink();
                                            }

                                            final total = checklist.length;
                                            final checked = checklist
                                                .where(
                                                  (it) => it['checked'] == true,
                                                )
                                                .length;
                                            return InkWell(
                                              onTap: () => _showChecklistDialog(
                                                itemId,
                                                checklist,
                                                (adv['status'] ?? '')
                                                    .toString(),
                                              ),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.primary
                                                      .withValues(alpha: 0.1),
                                                  border: Border.all(
                                                    color: AppTheme.primary
                                                        .withValues(alpha: 0.3),
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'Comment $checked/$total',
                                                  style: const TextStyle(
                                                    fontSize: 9,
                                                    color: AppTheme.primary,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            );
                                          } catch (e) {
                                            return const SizedBox.shrink();
                                          }
                                        },
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                        DataCell(
                          item['evidence_path'] != null
                              ? IconButton(
                                  icon: Icon(
                                    Icons.image_rounded,
                                    color: AppTheme.accent,
                                    size: 20,
                                  ),
                                  tooltip: 'Lihat Berkas',
                                  onPressed: () => _displayEvidence(
                                    item['evidence_path'],
                                    item['evidence_filename'],
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
                          (canEditRow)
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit_rounded,
                                        size: 18,
                                        color: AppTheme.primary,
                                      ),
                                      onPressed: () =>
                                          _showAddItemDialog(context, item),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 18,
                                        color: AppTheme.danger,
                                      ),
                                      onPressed: () => _deleteItem(itemId),
                                    ),
                                  ],
                                )
                              : _isManager && isSubmittedState
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (item['status'] != 'approved')
                                      IconButton(
                                        icon: const Icon(
                                          Icons.check_rounded,
                                          size: 18,
                                          color: AppTheme.success,
                                        ),
                                        tooltip: 'Approve Item',
                                        onPressed: () => _approveItem(itemId),
                                      ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        size: 18,
                                        color: AppTheme.danger,
                                      ),
                                      tooltip: 'Reject Item',
                                      onPressed: () => _rejectItem(itemId),
                                    ),
                                  ],
                                )
                              : const Text('-'),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _moveToDraft() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardColor(ctx),
        title: const Text(
          'Kembalikan ke Draft?',
          style: TextStyle(color: AppTheme.cream),
        ),
        content: const Text(
          'Apakah Anda yakin ingin menarik kembali kasbon ini ke status Draft untuk melakukan perbaikan?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Kembalikan ke Draft'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final prov = context.read<AdvanceProvider>();
    final success = await prov.moveAdvanceToDraft(widget.advanceId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Kasbon ditarik ke draft ✓' : (prov.error ?? 'Gagal'),
        ),
        backgroundColor: success ? AppTheme.success : AppTheme.danger,
      ),
    );
  }

  Future<void> _approveItem(int itemId) async {
    final prov = context.read<AdvanceProvider>();
    final success = await prov.approveAdvanceItem(itemId, 'approve');
    if (!mounted) return;
    if (success) {
      prov.loadAdvance(widget.advanceId);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(prov.error ?? 'Gagal approve item'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  Future<void> _rejectItem(int itemId) async {
    final controllers = [TextEditingController()];

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: _cardColor(ctx),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Tolak Item',
              style: TextStyle(color: AppTheme.cream),
            ),
            content: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Berikan alasan penolakan dalam bentuk checklist:',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        children: controllers.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final ctrl = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_box_outline_blank_rounded,
                                  size: 20,
                                  color: AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: ctrl,
                                    autofocus: idx == controllers.length - 1,
                                    decoration: InputDecoration(
                                      hintText: 'Alasan #${idx + 1}',
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 10,
                                            horizontal: 12,
                                          ),
                                    ),
                                    style: const TextStyle(
                                      color: AppTheme.cream,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                if (controllers.length > 1)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      color: AppTheme.danger,
                                      size: 20,
                                    ),
                                    onPressed: () => setDialogState(() {
                                      controllers[idx].dispose();
                                      controllers.removeAt(idx);
                                    }),
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
                    icon: const Icon(
                      Icons.add_circle_outline_rounded,
                      size: 20,
                    ),
                    label: const Text('Tambah Alasan'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.accent,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  for (var c in controllers) {
                    c.dispose();
                  }
                  Navigator.pop(ctx, false);
                },
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (controllers.every((c) => c.text.trim().isEmpty)) return;
                  Navigator.pop(ctx, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.danger,
                ),
                child: const Text('Tolak Item'),
              ),
            ],
          );
        },
      ),
    );

    if (result == true) {
      if (!mounted) return;
      final reasons = controllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .map((t) => {'text': t, 'checked': false})
          .toList();

      for (var c in controllers) {
        c.dispose();
      }

      if (reasons.isEmpty) return;

      final notesJson = jsonEncode(reasons);

      final prov = context.read<AdvanceProvider>();
      final success = await prov.approveAdvanceItem(
        itemId,
        'reject',
        notes: notesJson,
      );
      if (!mounted) return;
      if (success) {
        prov.loadAdvance(widget.advanceId);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(prov.error ?? 'Gagal reject item'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } else {
      for (var c in controllers) {
        c.dispose();
      }
    }
  }

  void _displayEvidence(String path, String filename) {
    final isPdf = path.toLowerCase().endsWith('.pdf');
    final url = '${ApiService.baseUrl}/uploads/$path';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardColor(ctx),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          filename,
          style: TextStyle(color: _creamColor(ctx), fontSize: 16),
        ),
        content: SizedBox(
          width: 600,
          height: 400,
          child: isPdf
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.picture_as_pdf_rounded,
                        size: 64,
                        color: AppTheme.danger,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Berkas (PDF)',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 24),
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
                        icon: const Icon(Icons.open_in_new_rounded),
                        label: const Text('Buka PDF'),
                      ),
                    ],
                  ),
                )
              : InteractiveViewer(
                  child: Image.network(
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
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Text(
                        'Gagal memuat gambar',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
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

  void _bulkDeleteItems() async {
    final count = _selectedItemIds.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardColor(ctx),
        title: Text(
          'Hapus $count Item',
          style: const TextStyle(color: AppTheme.cream),
        ),
        content: Text(
          'Hapus $count item yang dipilih? Tindakan ini tidak bisa dibatalkan.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
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
    final prov = context.read<AdvanceProvider>();
    final success = await prov.bulkDeleteAdvanceItems(
      _selectedItemIds.toList(),
      widget.advanceId,
    );
    if (success) {
      setState(() => _selectedItemIds.clear());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count item dihapus ✓'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    }
  }

  void _deleteItem(int itemId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Item'),
        content: const Text('Apakah Anda yakin ingin menghapus item ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final prov = context.read<AdvanceProvider>();
              final success = await prov.deleteAdvanceItem(itemId);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'Item dihapus'
                        : (prov.error ?? 'Gagal menghapus'),
                  ),
                  backgroundColor: success ? AppTheme.success : AppTheme.danger,
                ),
              );
              if (success) {
                prov.loadAdvance(widget.advanceId);
              }
            },
            child: const Text(
              'Hapus',
              style: TextStyle(color: AppTheme.danger),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _asMapList(dynamic list) {
    if (list == null || list is! List) return [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  List<Map<String, dynamic>> _uniqueById(List<Map<String, dynamic>> list) {
    final seen = <dynamic>{};
    return list.where((item) => seen.add(item['id'])).toList();
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
            style: const TextStyle(color: AppTheme.textPrimary),
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

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Kategori ditambahkan (menunggu approval manager) ✓',
                      ),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                }
              }
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  void _showChecklistDialog(
    int itemId,
    List<dynamic> checklist,
    String advanceStatus,
  ) {
    final isRejected =
        advanceStatus == 'rejected' || advanceStatus == 'revision_rejected';
    final isSubmitted =
        advanceStatus == 'submitted' || advanceStatus == 'revision_submitted';
    final isDraft = advanceStatus == 'draft';
    final isRevisionDraft = advanceStatus == 'revision_draft';

    // SEMUA user (manager/staff) TIDAK bisa edit saat submitted
    // Bisa edit saat draft/rejected/revision_draft
    final canEdit = !isSubmitted && (isDraft || isRejected || isRevisionDraft);
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
                child: SingleChildScrollView(
                  child: SelectionArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...localChecklist.asMap().entries.map((entry) {
                          final item = entry.value;
                          return _buildChecklistTile(
                            item,
                            canEdit,
                            setModalState,
                          );
                        }),
                        if (canAddComment)
                          _buildAddCommentButton(localChecklist, setModalState),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Tutup',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
              if (canEdit)
                _buildSaveChecklistButton(
                  ctx,
                  itemId,
                  localChecklist,
                  advanceStatus,
                ),
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
          if (e is Map) {
            local.add(Map<String, dynamic>.from(e));
          } else if (e is String) {
            local.add({'text': e, 'checked': false});
          }
        }
      }
    } catch (_) {}
    return local;
  }

  Widget _buildChecklistTile(
    Map<String, dynamic> item,
    bool canEdit,
    StateSetter setModalState,
  ) {
    final alreadyChecked = item['checked'] == true;
    return CheckboxListTile(
      value: alreadyChecked,
      onChanged: canEdit
          ? (val) => setModalState(() => item['checked'] = val ?? false)
          : null,
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
              style: const TextStyle(color: AppTheme.cream),
            ),
      activeColor: AppTheme.success,
      checkColor: Colors.white,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildAddCommentButton(
    List<Map<String, dynamic>> list,
    StateSetter setModalState,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: OutlinedButton.icon(
        onPressed: () => setModalState(
          () => list.add({'text': 'Komentar baru', 'checked': false}),
        ),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Tambah komentar'),
      ),
    );
  }

  Widget _buildSaveChecklistButton(
    BuildContext dialogCtx,
    int itemId,
    List<Map<String, dynamic>> list,
    String status,
  ) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      onPressed: () async {
        bool allFinished = list.every((it) => it['checked'] == true);
        final newStatus = allFinished ? 'pending' : 'rejected';

        final prov = context.read<AdvanceProvider>();
        final success = await prov.updateItemPartial(itemId, {
          'notes': jsonEncode(list),
          'status': newStatus,
        });

        if (success) {
          prov.loadAdvance(widget.advanceId);
          if (dialogCtx.mounted) Navigator.pop(dialogCtx);
          _showGlobalSnackBar(
            'Checklist berhasil disimpan ✓',
            AppTheme.success,
          );
        } else {
          if (dialogCtx.mounted) Navigator.pop(dialogCtx);
          _showGlobalSnackBar('Gagal menyimpan checklist', AppTheme.danger);
        }
      },
      child: const Text('Simpan'),
    );
  }

  void _showGlobalSnackBar(String message, Color color) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

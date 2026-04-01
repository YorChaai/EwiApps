import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/advance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/file_helper.dart';
import '../../utils/responsive_layout.dart';
import '../../utils/context_extensions.dart';
import '../../widgets/user_info_dialog.dart';
import 'advance_detail_screen.dart';

class MyAdvancesScreen extends StatefulWidget {
  const MyAdvancesScreen({super.key});

  @override
  State<MyAdvancesScreen> createState() => _MyAdvancesScreenState();
}

class _MyAdvancesScreenState extends State<MyAdvancesScreen> {
  static const Duration _searchDebounceDuration = Duration(milliseconds: 350);
  String? _statusFilter;
  DateTime? _startDate;
  DateTime? _endDate;
  String _searchQuery = '';
  double? _annualAdvanceTotal;
  final ScrollController _listScrollController = ScrollController();
  Timer? _searchDebounce;
  bool _showScrollToTop = false;
  bool _selectionMode = false;
  final Set<int> _selectedAdvanceIds = {};

  // Helper methods menggunakan extension context.isDark
  Color _cardColor(BuildContext context) =>
      context.isDark ? AppTheme.card : AppTheme.lightCard;
  Color _surfaceColor(BuildContext context) =>
      context.isDark ? AppTheme.surface : AppTheme.lightSurface;
  Color _dividerColor(BuildContext context) =>
      context.isDark ? AppTheme.divider : AppTheme.lightDivider;
  Color _titleColor(BuildContext context) =>
      context.isDark ? AppTheme.cream : AppTheme.lightTextPrimary;
  Color _bodyColor(BuildContext context) =>
      context.isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
  Color _primaryText(BuildContext context) =>
      context.isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;

  void _handleListScroll() {
    if (!_listScrollController.hasClients) return;
    final shouldShow = _listScrollController.offset > 320;
    if (shouldShow != _showScrollToTop && mounted) {
      setState(() => _showScrollToTop = shouldShow);
    }
  }

  Future<void> _scrollToTop() async {
    if (!_listScrollController.hasClients) return;
    await _listScrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _scheduleAdvanceReload() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(_searchDebounceDuration, _reloadAdvances);
  }

  bool _canDeleteAdvanceCard(Map<String, dynamic> advance, AuthProvider auth) {
    final status = (advance['status'] ?? '').toString().toLowerCase();
    if (auth.isManager) {
      return true;
    }
    final restrictedStatuses = [
      'approved',
      'in_settlement',
      'completed',
      'settled',
    ];
    return auth.user?['id'] == advance['user_id'] &&
        !restrictedStatuses.contains(status);
  }

  void _toggleSelectionMode([bool? enabled]) {
    setState(() {
      _selectionMode = enabled ?? !_selectionMode;
      if (!_selectionMode) {
        _selectedAdvanceIds.clear();
      }
    });
  }

  void _toggleAdvanceSelection(int id, bool selected) {
    setState(() {
      if (selected) {
        _selectedAdvanceIds.add(id);
      } else {
        _selectedAdvanceIds.remove(id);
      }
    });
  }

  Future<void> _deleteSelectedAdvances() async {
    if (_selectedAdvanceIds.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardColor(context),
        title: Text(
          'Hapus Kasbon Terpilih',
          style: TextStyle(color: _titleColor(context)),
        ),
        content: Text(
          'Hapus ${_selectedAdvanceIds.length} kasbon yang dipilih?',
          style: TextStyle(color: _primaryText(context)),
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
    int successCount = 0;
    int failCount = 0;
    for (final id in _selectedAdvanceIds.toList()) {
      final success = await prov.deleteAdvance(id, reload: false);
      if (success) {
        successCount++;
      } else {
        failCount++;
      }
    }
    _reloadAdvances();
    if (!mounted) return;
    final hadFailures = failCount > 0;
    final message = hadFailures
        ? '$successCount berhasil, $failCount gagal dihapus'
        : 'Kasbon terpilih berhasil dihapus';
    final snackColor = hadFailures ? AppTheme.warning : AppTheme.success;
    if (successCount == 0 && failCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(prov.error ?? 'Gagal menghapus kasbon terpilih'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }
    setState(() {
      _selectedAdvanceIds.clear();
      _selectionMode = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: snackColor,
      ),
    );
  }

  Future<void> _loadAnnualAdvanceSummary() async {
    try {
      final api = context.read<AuthProvider>().api;
      final prov = context.read<AdvanceProvider>();
      // Gunakan tahun yang dipilih di filter, bukan tahun saat ini
      final yearToUse = prov.reportYear == 0 ? DateTime.now().year : prov.reportYear;
      final res = await api.getAdvances(reportYear: yearToUse);
      final advances = List<Map<String, dynamic>>.from(res['advances'] ?? []);
      final total = advances.fold<double>(0, (sum, advance) {
        final amount = advance['total_amount'];
        if (amount is num) {
          return sum + amount.toDouble();
        }
        return sum + (double.tryParse(amount?.toString() ?? '') ?? 0);
      });
      if (!mounted) return;
      setState(() => _annualAdvanceTotal = total);
    } catch (_) {}
  }

  Widget _buildYearSummaryCard(
    BuildContext context,
    List<Map<String, dynamic>> advances,
  ) {
    final total = _annualAdvanceTotal ?? 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.teal.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.teal.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.tealAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pengeluaran Tahun Ini',
                  style: TextStyle(
                    color: _bodyColor(context),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Rp ${_formatNumber(total)}',
                  style: TextStyle(
                    color: _primaryText(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollableAdvanceHeader(
    BuildContext context,
    AuthProvider auth,
    AdvanceProvider prov,
    bool isNarrow,
    bool isVeryNarrow,
    bool canShowExportButtons,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(
            isNarrow ? 16 : 32,
            24,
            isNarrow ? 16 : 32,
            16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            auth.isManager ? 'Semua Kasbon' : 'Kasbon Saya',
                            style: TextStyle(
                              fontSize: isNarrow ? 20 : 24,
                              fontWeight: FontWeight.w700,
                              color: _titleColor(context),
                            ),
                            softWrap: true,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${prov.advances.length} total',
                          style: TextStyle(color: _bodyColor(context)),
                        ),
                      ],
                    ),
                  ),
                  if (!isNarrow) ...[
                    ElevatedButton.icon(
                      onPressed: _selectionMode
                          ? null
                          : () => _showCreateDialog(context),
                      style: ElevatedButton.styleFrom(
                        padding: isVeryNarrow
                            ? const EdgeInsets.all(12)
                            : const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: isVeryNarrow
                          ? const SizedBox.shrink()
                          : Text(isNarrow ? 'Buat' : 'Buat Kasbon'),
                    ),
                    const SizedBox(width: 8),
                    if (_selectionMode) ...[
                      IconButton(
                        onPressed: () => _toggleSelectionMode(false),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppTheme.textSecondary,
                        ),
                        tooltip: 'Batal pilih',
                      ),
                      IconButton(
                        onPressed: _selectedAdvanceIds.isEmpty
                            ? null
                            : _deleteSelectedAdvances,
                        icon: const Icon(
                          Icons.delete_rounded,
                          color: AppTheme.danger,
                        ),
                        tooltip: 'Hapus terpilih',
                      ),
                    ] else if (prov.advances.any(
                      (a) => _canDeleteAdvanceCard(a, auth),
                    ))
                      IconButton(
                        onPressed: _toggleSelectionMode,
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: AppTheme.danger,
                        ),
                        tooltip: 'Pilih untuk hapus',
                      ),
                  ],
                ],
              ),
              if (isNarrow) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _selectionMode
                            ? null
                            : () => _showCreateDialog(context),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Buat Kasbon'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_selectionMode) ...[
                      IconButton(
                        onPressed: () => _toggleSelectionMode(false),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppTheme.textSecondary,
                        ),
                        tooltip: 'Batal pilih',
                      ),
                      IconButton(
                        onPressed: _selectedAdvanceIds.isEmpty
                            ? null
                            : _deleteSelectedAdvances,
                        icon: const Icon(
                          Icons.delete_rounded,
                          color: AppTheme.danger,
                        ),
                        tooltip: 'Hapus terpilih',
                      ),
                    ] else if (prov.advances.any(
                      (a) => _canDeleteAdvanceCard(a, auth),
                    ))
                      IconButton(
                        onPressed: _toggleSelectionMode,
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: AppTheme.danger,
                        ),
                        tooltip: 'Pilih untuk hapus',
                      ),
                  ],
                ),
                if (_selectionMode) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${_selectedAdvanceIds.length} item dipilih',
                    style: TextStyle(color: _bodyColor(context), fontSize: 12),
                  ),
                ],
              ],
              const SizedBox(height: 16),
              _buildYearSummaryCard(context, prov.advances),
              const SizedBox(height: 16),
              TextField(
                style: TextStyle(
                  color: _primaryText(context),
                  fontSize: isVeryNarrow ? 13 : 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Cari kasbon...',
                  hintStyle: TextStyle(
                    color: _bodyColor(context),
                    fontSize: isVeryNarrow ? 13 : 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: _bodyColor(context),
                    size: isVeryNarrow ? 18 : 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            size: isVeryNarrow ? 16 : 18,
                            color: _bodyColor(context),
                          ),
                          onPressed: () {
                            setState(() => _searchQuery = '');
                            _reloadAdvances();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: _cardColor(context),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isVeryNarrow ? 12 : 16,
                    vertical: isVeryNarrow ? 8 : 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: _dividerColor(context)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: _dividerColor(context)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppTheme.primary,
                      width: 1.5,
                    ),
                  ),
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                  _scheduleAdvanceReload();
                },
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: _cardColor(context),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _dividerColor(context)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: prov.reportYear,
                          dropdownColor: _cardColor(context),
                          style: TextStyle(color: _primaryText(context)),
                          items: [
                            const DropdownMenuItem(
                              value: 0,
                              child: Text('Semua Tahun'),
                            ),
                            ...{
                              ...List.generate(21, (index) => 2020 + index),
                              prov.reportYear
                            }.where((y) => y != 0).map((y) => DropdownMenuItem(
                                  value: y,
                                  child: Text('Laporan $y'),
                                )),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            prov.setReportYear(value, reload: true);
                            // ✅ Load annual summary dengan tahun baru
                            _loadAnnualAdvanceSummary();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Semua',
                      selected: _statusFilter == null,
                      onTap: () {
                        setState(() => _statusFilter = null);
                        _reloadAdvances();
                      },
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Draft',
                      selected: _statusFilter == 'draft',
                      onTap: () {
                        setState(() => _statusFilter = 'draft');
                        _reloadAdvances();
                      },
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Submitted',
                      selected: _statusFilter == 'submitted',
                      onTap: () {
                        setState(() => _statusFilter = 'submitted');
                        _reloadAdvances();
                      },
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Approved',
                      selected: _statusFilter == 'approved',
                      onTap: () {
                        setState(() => _statusFilter = 'approved');
                        _reloadAdvances();
                      },
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'In Settlement',
                      selected: _statusFilter == 'in_settlement',
                      onTap: () {
                        setState(() => _statusFilter = 'in_settlement');
                        _reloadAdvances();
                      },
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Revisi',
                      selected: _statusFilter == 'revision_submitted',
                      onTap: () {
                        setState(() => _statusFilter = 'revision_submitted');
                        _reloadAdvances();
                      },
                    ),
                    const SizedBox(width: 8),
                    if (auth.isManager) ...[
                      _FilterChip(
                        label: 'Rejected',
                        selected: _statusFilter == 'rejected',
                        onTap: () {
                          setState(() => _statusFilter = 'rejected');
                          _reloadAdvances();
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Completed',
                        selected: _statusFilter == 'completed',
                        onTap: () {
                          setState(() => _statusFilter = 'completed');
                          _reloadAdvances();
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _pickDateRange(context),
                      icon: Icon(
                        Icons.date_range_rounded,
                        color: _startDate != null
                            ? AppTheme.primary
                            : _bodyColor(context),
                      ),
                    ),
                    if (_startDate != null)
                      IconButton(
                        onPressed: _clearDateRange,
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppTheme.danger,
                        ),
                        tooltip: 'Bersihkan Filter Tanggal',
                      ),
                    if (auth.isManager && canShowExportButtons) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _exportExcel,
                        icon: const Icon(
                          Icons.table_chart_rounded,
                          color: AppTheme.success,
                        ),
                        tooltip: 'Export Excel',
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: _exportPdf,
                        icon: const Icon(
                          Icons.picture_as_pdf_rounded,
                          color: AppTheme.danger,
                        ),
                        tooltip: 'Export PDF',
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2022),
      lastDate: DateTime(2030),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) => child!,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _reloadAdvances();
    }
  }

  void _clearDateRange() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _reloadAdvances();
  }

  void _reloadAdvances() {
    _searchDebounce?.cancel();
    _searchDebounce = null;
    final prov = context.read<AdvanceProvider>();
    prov.loadAdvances(
      status: _statusFilter,
      startDate: _startDate != null
          ? DateFormat('yyyy-MM-dd').format(_startDate!)
          : null,
      endDate: _endDate != null
          ? DateFormat('yyyy-MM-dd').format(_endDate!)
          : null,
      reportYear: prov.reportYear == 0 ? null : prov.reportYear,
      search: _searchQuery.isEmpty ? null : _searchQuery,
    );
    _loadAnnualAdvanceSummary();
  }

  Future<void> _loadDefaultReportYearAndReload() async {
    final prov = context.read<AdvanceProvider>();
    await prov.syncReportYear();
    _reloadAdvances();
    // ✅ Load annual summary setelah year di-sync
    _loadAnnualAdvanceSummary();
  }

  Future<void> _exportExcel() async {
    try {
      final prov = context.read<AdvanceProvider>();
      final bytes = await prov.exportExcel(
        startDate: _startDate != null
            ? DateFormat('yyyy-MM-dd').format(_startDate!)
            : null,
        endDate: _endDate != null
            ? DateFormat('yyyy-MM-dd').format(_endDate!)
            : null,
      );

      final suffix = _startDate != null
          ? '_${DateFormat('yyyyMMdd').format(_startDate!)}_${DateFormat('yyyyMMdd').format(_endDate!)}'
          : '';
      final timestamp = FileHelper.formatTimestamp();
      final filename = 'Laporan_Kasbon${suffix}_$timestamp.xlsx';

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

  Future<void> _exportPdf() async {
    try {
      final prov = context.read<AdvanceProvider>();
      final bytes = await prov.getBulkPdf(
        startDate: _startDate != null
            ? DateFormat('yyyy-MM-dd').format(_startDate!)
            : null,
        endDate: _endDate != null
            ? DateFormat('yyyy-MM-dd').format(_endDate!)
            : null,
      );

      final suffix = _startDate != null
          ? '_${DateFormat('yyyyMMdd').format(_startDate!)}_${DateFormat('yyyyMMdd').format(_endDate!)}'
          : '';
      final timestamp = FileHelper.formatTimestamp();
      final filename = 'Laporan_Kasbon${suffix}_$timestamp.pdf';

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

  @override
  void initState() {
    super.initState();
    _listScrollController.addListener(_handleListScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // ✅ Sequential: sync year first, then load data
      await _loadDefaultReportYearAndReload();
      // _loadAnnualAdvanceSummary() sudah dipanggil di dalam _loadDefaultReportYearAndReload()
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _listScrollController.removeListener(_handleListScroll);
    _listScrollController.dispose();
    super.dispose();
  }

  void _showCreateDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    String selectedType = 'single';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: _cardColor(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Buat Kasbon Baru',
            style: TextStyle(color: _titleColor(context)),
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _surfaceColor(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setDialogState(() => selectedType = 'single'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selectedType == 'single'
                                  ? AppTheme.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.receipt_long_rounded,
                                  size: 16,
                                  color: selectedType == 'single'
                                      ? Colors.white
                                      : _bodyColor(context),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Single',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: selectedType == 'single'
                                        ? Colors.white
                                        : _bodyColor(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setDialogState(() => selectedType = 'batch'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selectedType == 'batch'
                                  ? AppTheme.warning
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.folder_rounded,
                                  size: 16,
                                  color: selectedType == 'batch'
                                      ? Colors.white
                                      : _bodyColor(context),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Batch',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: selectedType == 'batch'
                                        ? Colors.white
                                        : _bodyColor(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  selectedType == 'single'
                      ? 'Permintaan kasbon untuk kebutuhan sendiri'
                      : 'Kasbon untuk satu kegiatan/proyek',
                  style: TextStyle(fontSize: 11, color: _bodyColor(context)),
                ),
                if (selectedType == 'batch') ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Judul Kegiatan',
                    ),
                    style: TextStyle(color: _primaryText(context)),
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  const SizedBox(height: 16),
                ],
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
                final title = selectedType == 'single'
                    ? 'Kasbon Mandiri'
                    : (titleCtrl.text.trim().isEmpty
                          ? 'Kasbon Batch'
                          : titleCtrl.text.trim());

                if (selectedType == 'batch' && titleCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Judul tidak boleh kosong!'),
                      backgroundColor: AppTheme.danger,
                    ),
                  );
                  return;
                }

                final prov = context.read<AdvanceProvider>();
                final advance = await prov.createUnsavedAdvance(
                  title,
                  "",
                  advanceType: selectedType,
                );

                if (ctx.mounted) Navigator.pop(ctx);
                if (advance != null && context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AdvanceDetailScreen(advanceId: advance['id']),
                    ),
                  );
                }
              },
              child: const Text('Buat'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final prov = context.watch<AdvanceProvider>();
    final canShowExportButtons = _statusFilter == 'completed';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 750;
        final isVeryNarrow = constraints.maxWidth < 450;

        return Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: prov.loading || prov.advances.isEmpty
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildScrollableAdvanceHeader(
                                context,
                                auth,
                                prov,
                                isNarrow,
                                isVeryNarrow,
                                canShowExportButtons,
                              ),
                              Expanded(
                                child: prov.loading
                                    ? Center(
                                        child: CircularProgressIndicator(
                                          color: AppTheme.primary,
                                        ),
                                      )
                                    : Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.inbox_rounded,
                                              size: 64,
                                              color: _bodyColor(context)
                                                  .withValues(alpha: 0.3),
                                            ),
                                            SizedBox(height: 16),
                                            Text(
                                              'Belum ada kasbon',
                                              style: TextStyle(
                                                color: _bodyColor(context),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                            ],
                          )
                        : RefreshIndicator(
                            onRefresh: () async => _reloadAdvances(),
                            child: Builder(
                              builder: (context) {
                                final singles = prov.advances
                                    .where(
                                      (a) =>
                                          (a['advance_type'] ?? 'single') == 'single',
                                    )
                                    .toList();
                                final batches = prov.advances
                                    .where(
                                      (a) =>
                                          (a['advance_type'] ?? 'single') == 'batch',
                                    )
                                    .toList();

                                final items = <dynamic>[];
                                if (singles.isNotEmpty) {
                                  items.add('__header_single__');
                                  items.addAll(singles);
                                }
                                if (batches.isNotEmpty) {
                                  items.add('__header_batch__');
                                  items.addAll(batches);
                                }

                                return CustomScrollView(
                                  controller: _listScrollController,
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  keyboardDismissBehavior:
                                      ScrollViewKeyboardDismissBehavior.onDrag,
                                  cacheExtent: 480,
                                  slivers: [
                                    SliverToBoxAdapter(
                                      child: _buildScrollableAdvanceHeader(
                                        context,
                                        auth,
                                        prov,
                                        isNarrow,
                                        isVeryNarrow,
                                        canShowExportButtons,
                                      ),
                                    ),
                                    SliverPadding(
                                      padding: EdgeInsets.only(
                                        left: isNarrow ? 16 : 24,
                                        right: isNarrow ? 16 : 24,
                                        bottom: isNarrow ? 16 : 24,
                                      ),
                                      sliver: SliverList(
                                        delegate: SliverChildBuilderDelegate(
                                          (context, i) {
                                            final item = items[i];
                                    if (item == '__header_single__') {
                                      return Padding(
                                        padding: EdgeInsets.only(bottom: 12, top: 4),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.receipt_long_rounded,
                                              size: 18,
                                              color: AppTheme.primary,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Kasbon Mandiri (${singles.length})',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: _titleColor(context),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                    if (item == '__header_batch__') {
                                      return Padding(
                                        padding: EdgeInsets.only(bottom: 12, top: 20),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.folder_rounded,
                                              size: 18,
                                              color: AppTheme.warning,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Kasbon Batch (${batches.length})',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: _titleColor(context),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }

                                    final advance = item as Map<String, dynamic>;
                                    return RepaintBoundary(
                                      child: _AdvanceCard(
                                        key: ValueKey(
                                          'advance_${advance['id']}_${advance['status']}_${_selectionMode ? 1 : 0}',
                                        ),
                                        advance: advance,
                                        isManager: auth.isManager,
                                        selectionMode: _selectionMode,
                                        selected: _selectedAdvanceIds.contains(
                                          advance['id'],
                                        ),
                                        canSelect: _canDeleteAdvanceCard(
                                          advance,
                                          auth,
                                        ),
                                        onSelectionChanged: (selected) =>
                                            _toggleAdvanceSelection(
                                              advance['id'],
                                              selected,
                                            ),
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => AdvanceDetailScreen(
                                              advanceId: advance['id'],
                                            ),
                                          ),
                                        ).then((_) => _reloadAdvances()),
                                      ),
                                    );
                                          },
                                          childCount: items.length,
                                          addAutomaticKeepAlives: false,
                                          addRepaintBoundaries: true,
                                          addSemanticIndexes: false,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                      ),
                    ],
                  ),
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: AnimatedSlide(
                      duration: const Duration(milliseconds: 180),
                      offset: (_showScrollToTop && !_selectionMode)
                          ? Offset.zero
                          : const Offset(0, 1.5),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        opacity: (_showScrollToTop && !_selectionMode) ? 1 : 0,
                        child: IgnorePointer(
                          ignoring: !(_showScrollToTop && !_selectionMode),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _scrollToTop,
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: _cardColor(context).withValues(
                                    alpha: 0.96,
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: AppTheme.primary.withValues(
                                      alpha: 0.35,
                                    ),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.18,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.keyboard_arrow_up_rounded,
                                  size: 18,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final borderColor = isDark ? AppTheme.divider : AppTheme.lightDivider;
    final textColor = isDark
        ? AppTheme.textSecondary
        : AppTheme.lightTextSecondary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? AppTheme.primary : textColor,
          ),
        ),
      ),
    );
  }
}

class _AdvanceCard extends StatefulWidget {
  final Map<String, dynamic> advance;
  final bool isManager;
  final VoidCallback onTap;
  final bool selectionMode;
  final bool selected;
  final bool canSelect;
  final ValueChanged<bool>? onSelectionChanged;

  const _AdvanceCard({
    super.key,
    required this.advance,
    required this.isManager,
    required this.onTap,
    this.selectionMode = false,
    this.selected = false,
    this.canSelect = false,
    this.onSelectionChanged,
  });

  @override
  State<_AdvanceCard> createState() => _AdvanceCardState();
}

class _AdvanceCardState extends State<_AdvanceCard> {
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
  Color _bodyColor(BuildContext context) =>
      _isDark(context) ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

  bool _isSettlementApproved(Map<String, dynamic> advance) {
    final settlementStatus =
        (advance['settlement_status'] ?? '').toString().toLowerCase();
    return settlementStatus == 'approved' || settlementStatus == 'completed';
  }

  Color _advanceStatusColor(Map<String, dynamic> advance) {
    final status = (advance['status'] ?? 'draft').toString().toLowerCase();
    if (status == 'in_settlement') {
      return _isSettlementApproved(advance)
          ? AppTheme.success
          : AppTheme.danger;
    }
    return _statusColor(status);
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
      case 'settled':
      case 'completed':
        return AppTheme.primary;
      case 'rejected':
        return AppTheme.danger;
      default:
        return _bodyColor(context);
    }
  }

  String _getRoleName(String? role) {
    switch (role) {
      case 'manager':
        return 'Manager';
      case 'staff':
        return 'Staff';
      case 'mitra_eks':
        return 'Mitra';
      case 'unknown':
        return 'User dihapus';
      default:
        return role ?? '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.advance;
    final status = (a['status'] ?? 'draft').toString().toLowerCase();
    final statusColor = _advanceStatusColor(a);
    final supportsHover = !ResponsiveLayout.isMobile(context);
    final type = (a['advance_type'] ?? 'single').toString().toLowerCase();
    final displayTitle = type == 'single'
        ? (a['first_item_description']?.toString() ??
              (a['title'] ?? 'Kasbon Mandiri').toString())
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
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
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
                    height: 40,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
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
                                  fontSize: 15,
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
                                'Rp ${_formatNumber(a['total_amount'] ?? 0)}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: _primaryText(context),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${_getRoleName(a['requester_role'])} · ${a['item_count'] ?? 0} item',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _bodyColor(context),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _StatusBadge(
                              status: status,
                              color: statusColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                final requesterId = a['requester_id'];
                                if (requesterId != null) {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => UserInfoDialog(
                                      userId: requesterId,
                                    ),
                                  );
                                }
                              },
                              child: Text(
                                widget.isManager ? (a['requester_name'] ?? '-') : 'Saya',
                                style: TextStyle(
                                  fontSize: 12,
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
                        if (isVeryNarrow) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Rp ${_formatNumber(a['total_amount'] ?? 0)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _primaryText(context),
                            ),
                          ),
                        ],
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
                          onChanged: (value) =>
                              widget.onSelectionChanged?.call(value ?? false),
                          activeColor: AppTheme.primary,
                          side: BorderSide(color: _dividerColor(context)),
                        ),
                      ),
                    )
                  else
                    Icon(
                      Icons.chevron_right_rounded,
                      color: _bodyColor(context),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color color;

  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

String _formatNumber(dynamic value) {
  if (value == null) return '0';
  final n = (value as num).toDouble();
  return n
      .toStringAsFixed(0)
      .replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      );
}

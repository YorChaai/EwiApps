import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/advance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../../utils/context_extensions.dart';
import '../../utils/file_helper.dart';
import '../../utils/app_snackbar.dart';
import 'advance_detail_screen.dart';
import '../../widgets/app_scrollbar.dart';

class AdvancesScreen extends StatefulWidget {
  const AdvancesScreen({super.key});

  @override
  State<AdvancesScreen> createState() => AdvancesScreenState();
}

class AdvancesScreenState extends State<AdvancesScreen> {
  static const Duration _searchDebounceDuration = Duration(milliseconds: 350);
  String? _statusFilter;
  DateTime? _startDate;
  DateTime? _endDate;
  String _searchQuery = '';
  double? _annualAdvanceTotal;
  final ScrollController _listScrollController = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _searchDebounce;
  bool _showScrollToTop = false;
  bool _selectionMode = false;
  final Set<int> _selectedAdvanceIds = {};
  String _selectedType = 'single';
  String _filterMode = 'report'; // Initial placeholder

  Color _cardColor(BuildContext context) => context.isDark ? AppTheme.card : AppTheme.lightCard;
  Color _titleColor(BuildContext context) => context.isDark ? AppTheme.cream : AppTheme.lightTextPrimary;
  Color _bodyColor(BuildContext context) => context.isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
  Color _dividerColor(BuildContext context) => context.isDark ? AppTheme.divider : AppTheme.lightDivider;
  Color _primaryText(BuildContext context) => context.isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;

  void _handleListScroll() {
    if (!_listScrollController.hasClients) return;
    final shouldShow = _listScrollController.offset > 320;
    if (shouldShow != _showScrollToTop && mounted) setState(() => _showScrollToTop = shouldShow);
  }

  /// Memaksa daftar scroll kembali ke paling atas
  Future<void> scrollToTop() async {
    if (!_listScrollController.hasClients) return;
    await _listScrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  /// Reset semua filter dan pencarian
  void resetFilters() {
    if (!mounted) return;
    setState(() {
      _statusFilter = null;
      _startDate = null;
      _endDate = null;
      _searchQuery = '';
      _searchCtrl.clear();
      _selectedType = 'single';
    });
    final prov = context.read<AdvanceProvider>();
    prov.clearFilters(); // Ini akan memicu loadAdvances secara internal
    _loadAnnualAdvanceSummary();
    scrollToTop();
  }

  void _scheduleAdvanceReload() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(_searchDebounceDuration, _reloadAdvances);
  }

  bool _canDeleteAdvanceCard(Map<String, dynamic> advance, AuthProvider auth) {
    final status = (advance['status'] ?? '').toString().toLowerCase();
    if (auth.isManager) return true;
    return auth.user?['id'] == advance['user_id'] && !['approved', 'in_settlement', 'completed', 'settled'].contains(status);
  }



  void _toggleAdvanceSelection(int id, bool selected) {
    setState(() {
      if (selected) {
        _selectedAdvanceIds.add(id);
      } else {
        _selectedAdvanceIds.remove(id);
      }
      if (_selectedAdvanceIds.isEmpty) _selectionMode = false;
    });
  }

  Future<void> _bulkDeleteAdvances() async {
    if (_selectedAdvanceIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardColor(context),
        title: const Text('Hapus Masal'),
        content: Text('Apakah Anda yakin ingin menghapus ${_selectedAdvanceIds.length} kasbon terpilih?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: TextStyle(color: _bodyColor(context))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final prov = context.read<AdvanceProvider>();
      final ids = _selectedAdvanceIds.toList();
      for (final id in ids) {
        await prov.deleteAdvance(id, reload: false);
      }
      await prov.loadAdvances();
      if (mounted) {
        Navigator.pop(context); // hide loading
        setState(() {
          _selectedAdvanceIds.clear();
          _selectionMode = false;
        });
        AppSnackbar.show('Berhasil menghapus ${ids.length} kasbon');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // hide loading
        AppSnackbar.show('Gagal menghapus beberapa kasbon: $e', isError: true);
      }
    }
  }



  Future<void> _loadAnnualAdvanceSummary() async {
    try {
      final prov = context.read<AdvanceProvider>();
      final year = prov.reportYear == 0 ? DateTime.now().year : prov.reportYear;
      final res = await context.read<AuthProvider>().api.getAdvances(reportYear: year);
      if (!mounted) return;
      final advances = List<Map<String, dynamic>>.from(res['advances'] ?? []);
      final total = advances.fold<double>(0, (sum, a) => sum + (double.tryParse(a['total_amount']?.toString() ?? '0') ?? 0));
      setState(() => _annualAdvanceTotal = total);
    } catch (_) {}
  }

  void _reloadAdvances() {
    _searchDebounce?.cancel(); _searchDebounce = null;
    final prov = context.read<AdvanceProvider>();

    // Kirim tanggal HANYA JIKA mode adalah 'range'
    final effectiveStartDate = _filterMode == 'range' && _startDate != null
        ? DateFormat('yyyy-MM-dd').format(_startDate!)
        : null;
    final effectiveEndDate = _filterMode == 'range' && _endDate != null
        ? DateFormat('yyyy-MM-dd').format(_endDate!)
        : null;

    prov.loadAdvances(
      status: _statusFilter,
      startDate: effectiveStartDate,
      endDate: effectiveEndDate,
      reportYear: prov.reportYear,
      mode: _filterMode,
      search: _searchQuery.isEmpty ? null : _searchQuery,
    );
    _loadAnnualAdvanceSummary();
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final DateTimeRange? picked = await AppDateRangePicker.show(
      context,
      initialRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _filterMode = 'range'; // Aktifkan mode range
      });
      _reloadAdvances();
    }
  }

  Future<void> _exportExcel() async {
    try {
      final bytes = await context.read<AdvanceProvider>().exportExcel(startDate: _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : null, endDate: _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null);
      if (!mounted) return;
      await FileHelper.saveAndOpenFolder(
        context: context,
        bytes: bytes,
        filename: 'Laporan_Kasbon_${FileHelper.formatTimestamp()}.xlsx',
        subFolder: 'Reports/Advances/Excel',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal export Excel: $e'), backgroundColor: AppTheme.danger));
    }
  }

  Future<void> _exportPdf() async {
    try {
      final bytes = await context.read<AdvanceProvider>().getBulkPdf(startDate: _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : null, endDate: _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null);
      if (!mounted) return;
      await FileHelper.saveAndOpenFile(
        context: context,
        bytes: bytes,
        filename: 'Laporan_Kasbon_${FileHelper.formatTimestamp()}.pdf',
        subFolder: 'Reports/Advances/PDF',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal export PDF: $e'), backgroundColor: AppTheme.danger));
    }
  }

  void _showCreateDialog(BuildContext context) {
    final prov = context.read<AdvanceProvider>();
    final titleCtrl = TextEditingController();
    String selectedType = 'single';
    int selectedYear = prov.reportYear;
    bool creating = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: _cardColor(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Buat Kasbon Baru',
              style: TextStyle(color: _titleColor(context))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pemilihan Tahun
              DropdownButtonFormField<int>(
                initialValue: selectedYear,
                dropdownColor: _cardColor(context),
                decoration: InputDecoration(
                  labelText: 'Tahun Laporan',
                  labelStyle: TextStyle(color: _primaryText(context)),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                        color: _primaryText(context).withValues(alpha: 0.3)),
                  ),
                ),
                style: TextStyle(color: _primaryText(context)),
                items: List.generate(7, (index) => 2024 + index)
                    .map((year) => DropdownMenuItem(
                          value: year,
                          child: Text(year.toString()),
                        ))
                    .toList(),
                onChanged: (v) => setDialogState(() => selectedYear = v!),
              ),
              const SizedBox(height: 16),
              // Custom Radio Group
              AppRadioGroup<String>(
                groupValue: selectedType,
                onChanged: (v) => setDialogState(() => selectedType = v!),
                child: Row(
                  children: const [
                    Expanded(
                      child: AppRadioItem<String>(
                        value: 'single',
                        label: Text('Single'),
                      ),
                    ),
                    Expanded(
                      child: AppRadioItem<String>(
                        value: 'batch',
                        label: Text('Batch'),
                      ),
                    ),
                  ],
                ),
              ),
              if (selectedType == 'batch')
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Judul Kegiatan'),
                  style: TextStyle(color: _primaryText(context)),
                ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal')),
            ElevatedButton(
                onPressed: creating
                    ? null
                    : () async {
                        final title = selectedType == 'single'
                            ? 'Kasbon Mandiri'
                            : titleCtrl.text.trim();
                        if (selectedType == 'batch' && title.isEmpty) return;

                        // Capture Navigator and Provider early
                        final navigator = Navigator.of(context);
                        final aProv = context.read<AdvanceProvider>();

                        setDialogState(() => creating = true);
                        final advance = await aProv.createUnsavedAdvance(
                          title,
                          "",
                          advanceType: selectedType,
                          reportYear: selectedYear,
                        );

                        if (!ctx.mounted) return;

                        if (advance != null) {
                          Navigator.pop(ctx);
                          navigator.push(
                            MaterialPageRoute(
                              builder: (_) => AdvanceDetailScreen(
                                advanceId: advance['id'],
                              ),
                            ),
                          );
                        } else {
                          setDialogState(() => creating = false);
                        }
                      },
                child: creating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Buat')),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _listScrollController.addListener(_handleListScroll);
    _filterMode = context.read<AdvanceProvider>().filterMode; // ✅ Sync mode
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<AdvanceProvider>().syncReportYear();
      if (!mounted) return;
      _reloadAdvances();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _listScrollController.removeListener(_handleListScroll);
    _listScrollController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final prov = context.watch<AdvanceProvider>();
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 750;
        final isVeryNarrow = constraints.maxWidth < 450;
        final useCompact = constraints.maxWidth < 500;
        final pagePadding = EdgeInsets.fromLTRB(isNarrow ? 16 : 24, useCompact ? 16 : 24, isNarrow ? 16 : 24, 16);
        return Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: AppScrollbar(
                            controller: _listScrollController,
                            thumbVisibility: true,
                            interactive: true,
                            child: RefreshIndicator(
                              onRefresh: () async => _reloadAdvances(),
                              child: Builder(
                                builder: (context) {
                                  final singles = prov.advances.where((a) => (a['advance_type'] ?? 'single') == 'single').toList();
                                  final batches = prov.advances.where((a) => (a['advance_type'] ?? 'single') == 'batch').toList();
                                  final displayList = _selectedType == 'single' ? singles : batches;
                                  final items = <dynamic>[...displayList];

                                  return CustomScrollView(
                                    key: const PageStorageKey('advance_list'),
                                    controller: _listScrollController,
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    slivers: [
                                      SliverToBoxAdapter(child: _buildScrollableAdvanceHeader(context, auth, prov, isNarrow, isVeryNarrow, _statusFilter == 'completed', pagePadding, useCompact)),
                                      if (prov.loading && prov.advances.isEmpty)
                                        const SliverFillRemaining(
                                          child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                                        )
                                      else if (items.isEmpty)
                                        SliverFillRemaining(
                                          hasScrollBody: false,
                                          child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.inbox_rounded, size: 64, color: _bodyColor(context).withValues(alpha: 0.3)), const SizedBox(height: 16), Text(_selectedType == 'single' ? 'Belum ada kasbon mandiri' : 'Belum ada kasbon batch', style: TextStyle(color: _bodyColor(context)))]))
                                        )
                                      else
                                        SliverPadding(
                                          padding: EdgeInsets.only(left: isNarrow ? 16 : 24, right: isNarrow ? 16 : 24, bottom: _selectionMode ? 100 : (isNarrow ? 16 : 24)),
                                          sliver: SliverList(
                                            delegate: SliverChildBuilderDelegate(
                                              (context, i) {
                                                final a = items[i] as Map<String, dynamic>;
                                                return RepaintBoundary(
                                                  child: AdvanceCard(
                                                    key: ValueKey('advance_${a['id']}'),
                                                    advance: a,
                                                    isManager: auth.isManager,
                                                    onDelete: _selectionMode ? null : () => _deleteAdvance(a['id']),
                                                    selectionMode: _selectionMode,
                                                    selected: _selectedAdvanceIds.contains(a['id']),
                                                    canSelect: _canDeleteAdvanceCard(a, auth),
                                                    onSelectionChanged: (v) => _toggleAdvanceSelection(a['id'], v),
                                                    onTap: () => Navigator.push(
                                                      context,
                                                      MaterialPageRoute(builder: (_) => AdvanceDetailScreen(advanceId: a['id'])),
                                                    ),
                                                  ),
                                                );
                                              },
                                              childCount: items.length,
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                      ),
                    ],
                  ),
                  if (_showScrollToTop && !_selectionMode)
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: FloatingActionButton.small(
                        heroTag: 'advance_scroll_to_top',
                        onPressed: scrollToTop,
                        backgroundColor:
                            _cardColor(context).withValues(alpha: 0.9),
                        child: const Icon(Icons.keyboard_arrow_up_rounded,
                            color: AppTheme.primary),
                      ),
                    ),
                  if (_selectionMode && _selectedAdvanceIds.isNotEmpty)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: Center(
                        child: FloatingActionButton.extended(
                          heroTag: 'advance_bulk_delete',
                          onPressed: _bulkDeleteAdvances,
                          backgroundColor: AppTheme.danger,
                          icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white),
                          label: Text(
                            'Hapus (${_selectedAdvanceIds.length})',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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

  Future<void> _deleteAdvance(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardColor(context),
        title: const Text('Hapus Kasbon'),
        content: const Text('Apakah Anda yakin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger), child: const Text('Hapus')),
        ],
      ),
    );
    if (confirm == true) {
      if (!mounted) return;
      await context.read<AdvanceProvider>().deleteAdvance(id);
    }
  }

  Widget _buildTypeToggle(bool useCompact) {
    final prov = context.read<AdvanceProvider>();
    final singlesCount =
        prov.advances.where((a) => (a['advance_type'] ?? 'single') == 'single').length;
    final batchesCount =
        prov.advances.where((a) => (a['advance_type'] ?? 'single') == 'batch').length;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _cardColor(context).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: context.isDark ? AppTheme.divider : AppTheme.lightDivider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildToggleButton(
              label: 'Kasbon Mandiri',
              count: singlesCount,
              value: 'single',
              useCompact: useCompact,
            ),
            const SizedBox(width: 4),
            _buildToggleButton(
              label: 'Kasbon Batch',
              count: batchesCount,
              value: 'batch',
              useCompact: useCompact,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required int count,
    required String value,
    required bool useCompact,
  }) {
    final isActive = _selectedType == value;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedType = value),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: useCompact
                ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
                : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? AppTheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: useCompact ? 11 : 13,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    color: isActive
                        ? Colors.white
                        : (context.isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.white.withValues(alpha: 0.2)
                        : (context.isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.05)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: useCompact ? 10 : 12,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.white : AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScrollableAdvanceHeader(BuildContext context, AuthProvider auth, AdvanceProvider prov, bool isNarrow, bool isVeryNarrow, bool canShowExport, EdgeInsets pagePadding, bool useCompact) {
    return Padding(
      padding: pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(auth.isManager ? 'Semua Kasbon' : 'Kasbon Saya', style: TextStyle(fontSize: useCompact ? 18 : (isNarrow ? 20 : 24), fontWeight: FontWeight.bold, color: _titleColor(context))),
              Text('${prov.advances.length} total', style: TextStyle(color: _bodyColor(context), fontSize: useCompact ? 10 : 13)),
            ])),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectionMode = !_selectionMode;
                      if (!_selectionMode) _selectedAdvanceIds.clear();
                    });
                  },
                  icon: Icon(
                    _selectionMode ? Icons.close_rounded : Icons.delete_outline_rounded,
                    color: _selectionMode ? AppTheme.danger : AppTheme.danger,
                    size: useCompact ? 22 : 26,
                  ),
                  tooltip: _selectionMode ? 'Batal' : 'Pilih Banyak',
                ),
                const SizedBox(width: 4),
                ElevatedButton.icon(
                  onPressed: _selectionMode ? null : () => _showCreateDialog(context),
                  icon: Icon(Icons.add, size: useCompact ? 16 : 20),
                  label: Text(isNarrow ? 'Buat' : 'Buat Kasbon', style: TextStyle(fontSize: useCompact ? 12 : 14)),
                  style: ElevatedButton.styleFrom(
                    padding: useCompact ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8) : null,
                    minimumSize: useCompact ? const Size(0, 36) : null,
                  ),
                ),
              ],
            ),
          ]),
          SizedBox(height: useCompact ? 10 : 16),
          _buildYearSummaryCard(context, prov.reportYear == 0 ? DateTime.now().year : prov.reportYear, useCompact),
          SizedBox(height: useCompact ? 10 : 16),
          TextField(
            controller: _searchCtrl,
            style: TextStyle(fontSize: useCompact ? 13 : 14),
            decoration: InputDecoration(
              isDense: useCompact,
              hintText: 'Cari kasbon...',
              prefixIcon: Icon(Icons.search, size: useCompact ? 18 : 24),
              contentPadding: useCompact ? const EdgeInsets.symmetric(vertical: 6) : null,
              suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: Icon(Icons.clear, size: useCompact ? 16 : 20), onPressed: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); _reloadAdvances(); }) : null
            ),
            onChanged: (v) { setState(() => _searchQuery = v); _scheduleAdvanceReload(); }
          ),
          SizedBox(height: useCompact ? 12 : 16),
          Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // SATU TOMBOL UNTUK SEMUA: Periode Data
                  CascadingYearFilter(
                    label: 'Periode Data',
                    selectedYear: prov.reportYear,
                    currentMode: _filterMode,
                    useCompact: useCompact,
                    startDate: _startDate,
                    endDate: _endDate,
                    onSelected: (year, mode) {
                      prov.setReportYear(year, reload: false);
                      setState(() {
                        _filterMode = mode;
                        // Data range tetap tersimpan di state
                      });
                      _reloadAdvances();
                    },
                    onRangeTap: () => _pickDateRange(context),
                  ),
                  const SizedBox(width: 12),
                  CascadingStatusFilter(
                    selectedStatus: _statusFilter,
                    useCompact: useCompact,
                    isManager: auth.isManager,
                    onSelected: (val) {
                      setState(() => _statusFilter = val);
                      _reloadAdvances();
                    },
                  ),
                  if (auth.isManager && canShowExport) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _exportExcel,
                      icon: const Icon(
                        Icons.table_chart_rounded,
                        color: AppTheme.success,
                      ),
                    ),
                    IconButton(
                      onPressed: _exportPdf,
                      icon: const Icon(
                        Icons.picture_as_pdf_rounded,
                        color: AppTheme.danger,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildTypeToggle(useCompact),
        ],
      ),
    );
  }

  Widget _buildYearSummaryCard(BuildContext context, int year, bool useCompact) {
    final total = _annualAdvanceTotal ?? 0;
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 750;

    final card = Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: useCompact ? 8 : 14),
      decoration: BoxDecoration(
        color: Colors.teal.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _dividerColor(context)),
      ),
      child: Row(children: [
        Container(padding: EdgeInsets.all(useCompact ? 6 : 8), decoration: BoxDecoration(color: Colors.teal.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.account_balance_wallet_rounded, color: Colors.teal, size: useCompact ? 18 : 20)),
        SizedBox(width: useCompact ? 10 : 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(year == 0 ? 'Permintaan Semua Tahun' : 'Permintaan Tahun $year', style: TextStyle(color: _bodyColor(context), fontSize: useCompact ? 9 : 11)),
          Text('Rp ${formatNumber(total)}', style: TextStyle(color: _primaryText(context), fontSize: useCompact ? 14 : 16, fontWeight: FontWeight.w700)),
        ]),
      ]),
    );

    if (!isNarrow) {
      return Row(children: [Expanded(child: card)]);
    }
    return card;
  }
}

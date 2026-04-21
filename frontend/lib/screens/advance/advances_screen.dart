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
import 'advance_detail_screen.dart';

class AdvancesScreen extends StatefulWidget {
  const AdvancesScreen({super.key});

  @override
  State<AdvancesScreen> createState() => _AdvancesScreenState();
}

class _AdvancesScreenState extends State<AdvancesScreen> {
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
  final bool _selectionMode = false;
  final Set<int> _selectedAdvanceIds = {};

  Color _cardColor(BuildContext context) => context.isDark ? AppTheme.card : AppTheme.lightCard;
  Color _titleColor(BuildContext context) => context.isDark ? AppTheme.cream : AppTheme.lightTextPrimary;
  Color _bodyColor(BuildContext context) => context.isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
  Color _primaryText(BuildContext context) => context.isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;

  void _handleListScroll() {
    if (!_listScrollController.hasClients) return;
    final shouldShow = _listScrollController.offset > 320;
    if (shouldShow != _showScrollToTop && mounted) setState(() => _showScrollToTop = shouldShow);
  }

  Future<void> _scrollToTop() async {
    if (!_listScrollController.hasClients) return;
    await _listScrollController.animateTo(0, duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic);
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
    });
  }



  Future<void> _loadAnnualAdvanceSummary() async {
    try {
      final prov = context.read<AdvanceProvider>();
      final year = prov.reportYear == 0 ? DateTime.now().year : prov.reportYear;
      final res = await context.read<AuthProvider>().api.getAdvances(reportYear: year);
      final advances = List<Map<String, dynamic>>.from(res['advances'] ?? []);
      final total = advances.fold<double>(0, (sum, a) => sum + (double.tryParse(a['total_amount']?.toString() ?? '0') ?? 0));
      if (mounted) setState(() => _annualAdvanceTotal = total);
    } catch (_) {}
  }

  void _reloadAdvances() {
    _searchDebounce?.cancel(); _searchDebounce = null;
    final prov = context.read<AdvanceProvider>();
    prov.loadAdvances(
      status: _statusFilter,
      startDate: _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : null,
      endDate: _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null,
      reportYear: prov.reportYear == 0 ? null : prov.reportYear,
      search: _searchQuery.isEmpty ? null : _searchQuery,
    );
    _loadAnnualAdvanceSummary();
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(context: context, firstDate: DateTime(2022), lastDate: DateTime(2030), initialDateRange: _startDate != null && _endDate != null ? DateTimeRange(start: _startDate!, end: _endDate!) : null);
    if (picked != null) { setState(() { _startDate = picked.start; _endDate = picked.end; }); _reloadAdvances(); }
  }

  void _clearDateRange() { setState(() { _startDate = null; _endDate = null; }); _reloadAdvances(); }

  Future<void> _exportExcel() async {
    try {
      final bytes = await context.read<AdvanceProvider>().exportExcel(startDate: _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : null, endDate: _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null);
      if (!mounted) return;
      await FileHelper.saveAndOpenFolder(context: context, bytes: bytes, filename: 'Laporan_Kasbon_${FileHelper.formatTimestamp()}.xlsx');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal export Excel: $e'), backgroundColor: AppTheme.danger));
    }
  }

  Future<void> _exportPdf() async {
    try {
      final bytes = await context.read<AdvanceProvider>().getBulkPdf(startDate: _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : null, endDate: _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null);
      if (!mounted) return;
      await FileHelper.saveAndOpenFile(context: context, bytes: bytes, filename: 'Laporan_Kasbon_${FileHelper.formatTimestamp()}.pdf');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal export PDF: $e'), backgroundColor: AppTheme.danger));
    }
  }

  void _showCreateDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    String selectedType = 'single';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: _cardColor(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Buat Kasbon Baru', style: TextStyle(color: _titleColor(context))),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            RadioGroup<String>(
              groupValue: selectedType,
              onChanged: (v) => setDialogState(() => selectedType = v!),
              child: Row(children: [
                Expanded(child: RadioListTile<String>(title: const Text('Single'), value: 'single')),
                Expanded(child: RadioListTile<String>(title: const Text('Batch'), value: 'batch')),
              ]),
            ),
            if (selectedType == 'batch') TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Judul Kegiatan'), style: TextStyle(color: _primaryText(context))),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                final title = selectedType == 'single' ? 'Kasbon Mandiri' : titleCtrl.text.trim();
                if (selectedType == 'batch' && title.isEmpty) return;
                final advance = await context.read<AdvanceProvider>().createUnsavedAdvance(title, "", advanceType: selectedType);
                if (ctx.mounted) Navigator.pop(ctx);
                if (advance != null && context.mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => AdvanceDetailScreen(advanceId: advance['id'])));
              },
              child: const Text('Buat'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _listScrollController.addListener(_handleListScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<AdvanceProvider>().syncReportYear();
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
                        child: prov.loading || prov.advances.isEmpty
                        ? Column(children: [
                            _buildScrollableAdvanceHeader(context, auth, prov, isNarrow, isVeryNarrow, _statusFilter == 'completed', pagePadding, useCompact),
                            Expanded(child: prov.loading
                              ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                              : Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.inbox_rounded, size: 64, color: _bodyColor(context).withValues(alpha: 0.3)), const SizedBox(height: 16), Text('Belum ada kasbon', style: TextStyle(color: _bodyColor(context)))]))),
                          ])
                        : Scrollbar(
                            controller: _listScrollController,
                            thumbVisibility: true,
                            thickness: 8,
                            child: RefreshIndicator(
                              onRefresh: () async => _reloadAdvances(),
                              child: Builder(
                                builder: (context) {
                                  final singles = prov.advances.where((a) => (a['advance_type'] ?? 'single') == 'single').toList();
                                  final batches = prov.advances.where((a) => (a['advance_type'] ?? 'single') == 'batch').toList();
                                  final items = <dynamic>[];
                                  if (singles.isNotEmpty) { items.add('__header_single__'); items.addAll(singles); }
                                  if (batches.isNotEmpty) { items.add('__header_batch__'); items.addAll(batches); }
                                  return CustomScrollView(
                                    controller: _listScrollController,
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    slivers: [
                                      SliverToBoxAdapter(child: _buildScrollableAdvanceHeader(context, auth, prov, isNarrow, isVeryNarrow, _statusFilter == 'completed', pagePadding, useCompact)),
                                      SliverPadding(
                                        padding: EdgeInsets.only(left: isNarrow ? 16 : 24, right: isNarrow ? 16 : 24, bottom: isNarrow ? 16 : 24),
                                        sliver: SliverList(
                                          delegate: SliverChildBuilderDelegate(
                                            (context, i) {
                                              final item = items[i];
                                              if (item == '__header_single__') return _groupHeader(Icons.receipt_long_rounded, 'Kasbon Mandiri (${singles.length})');
                                              if (item == '__header_batch__') return _groupHeader(Icons.folder_rounded, 'Kasbon Batch (${batches.length})');
                                              final a = item as Map<String, dynamic>;
                                              return RepaintBoundary(child: AdvanceCard(advance: a, isManager: auth.isManager, selectionMode: _selectionMode, selected: _selectedAdvanceIds.contains(a['id']), canSelect: _canDeleteAdvanceCard(a, auth), onSelectionChanged: (v) => _toggleAdvanceSelection(a['id'], v), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdvanceDetailScreen(advanceId: a['id']))).then((_) => _reloadAdvances())));
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
                    Positioned(right: 16, bottom: 16, child: FloatingActionButton.small(onPressed: _scrollToTop, backgroundColor: _cardColor(context).withValues(alpha: 0.96), child: const Icon(Icons.keyboard_arrow_up_rounded, color: AppTheme.primary))),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _groupHeader(IconData icon, String label) {
    return Padding(padding: const EdgeInsets.only(bottom: 12, top: 8), child: Row(children: [Icon(icon, size: 18, color: AppTheme.primary), const SizedBox(width: 8), Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _titleColor(context)))]));
  }

  Widget _buildScrollableAdvanceHeader(BuildContext context, AuthProvider auth, AdvanceProvider prov, bool isNarrow, bool isVeryNarrow, bool canShowExport, EdgeInsets pagePadding, bool useCompact) {
    return Padding(
      padding: pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(auth.isManager ? 'Semua Kasbon' : 'Kasbon Saya', style: TextStyle(fontSize: useCompact ? 18 : (isNarrow ? 20 : 24), fontWeight: FontWeight.w700, color: _titleColor(context))),
              Text('${prov.advances.length} total', style: TextStyle(color: _bodyColor(context), fontSize: useCompact ? 10 : 13)),
            ])),
            ElevatedButton.icon(
              onPressed: _selectionMode ? null : () => _showCreateDialog(context),
              icon: Icon(Icons.add, size: useCompact ? 18 : 20),
              label: Text(isNarrow ? 'Buat' : 'Buat Kasbon', style: TextStyle(fontSize: useCompact ? 13 : 14)),
              style: ElevatedButton.styleFrom(
                padding: useCompact ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8) : null,
                minimumSize: useCompact ? const Size(0, 36) : null,
              ),
            ),
          ]),
          SizedBox(height: useCompact ? 12 : 16),
          _buildYearSummaryCard(context, prov.reportYear == 0 ? DateTime.now().year : prov.reportYear, useCompact),
          SizedBox(height: useCompact ? 12 : 16),
          TextField(
            controller: _searchCtrl,
            style: TextStyle(fontSize: useCompact ? 13 : 14),
            decoration: InputDecoration(
              isDense: useCompact,
              hintText: 'Cari kasbon...',
              prefixIcon: Icon(Icons.search, size: useCompact ? 20 : 24),
              contentPadding: useCompact ? const EdgeInsets.symmetric(vertical: 8) : null,
              suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: Icon(Icons.clear, size: useCompact ? 18 : 20), onPressed: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); _reloadAdvances(); }) : null
            ),
            onChanged: (v) { setState(() => _searchQuery = v); _scheduleAdvanceReload(); }
          ),
          SizedBox(height: useCompact ? 12 : 16),
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
            Container(
              height: useCompact ? 32 : 40,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: _cardColor(context),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.isDark ? AppTheme.divider : AppTheme.lightDivider),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: prov.reportYear,
                  dropdownColor: _cardColor(context),
                  style: TextStyle(color: _primaryText(context), fontSize: useCompact ? 11 : 13, fontWeight: FontWeight.w500),
                  items: [
                    const DropdownMenuItem(value: 0, child: Text('Semua Tahun')),
                    ...List.generate(21, (index) => 2020 + index).map((y) => DropdownMenuItem(value: y, child: Text('Laporan $y'))),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    prov.setReportYear(value, reload: false);
                    _reloadAdvances();
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            StatusFilterChip(label: 'Semua', selected: _statusFilter == null, isMobile: useCompact, onTap: () { setState(() => _statusFilter = null); _reloadAdvances(); }),
            const SizedBox(width: 8),
            StatusFilterChip(label: 'Draft', selected: _statusFilter == 'draft', isMobile: useCompact, onTap: () { setState(() => _statusFilter = 'draft'); _reloadAdvances(); }),
            const SizedBox(width: 8),
            StatusFilterChip(label: 'Submitted', selected: _statusFilter == 'submitted', isMobile: useCompact, onTap: () { setState(() => _statusFilter = 'submitted'); _reloadAdvances(); }),
            const SizedBox(width: 8),
            StatusFilterChip(label: 'Approved', selected: _statusFilter == 'approved', isMobile: useCompact, onTap: () { setState(() => _statusFilter = 'approved'); _reloadAdvances(); }),
            const SizedBox(width: 8),
            StatusFilterChip(label: 'Rejected', selected: _statusFilter == 'rejected', isMobile: useCompact, onTap: () { setState(() => _statusFilter = 'rejected'); _reloadAdvances(); }),
            const SizedBox(width: 8),
            IconButton(onPressed: () => _pickDateRange(context), icon: Icon(Icons.date_range_rounded, color: _startDate != null ? AppTheme.primary : _bodyColor(context))),
            if (_startDate != null) IconButton(onPressed: _clearDateRange, icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.danger)),
            if (auth.isManager && canShowExport) ...[
              IconButton(onPressed: _exportExcel, icon: const Icon(Icons.table_chart_rounded, color: AppTheme.success)),
              IconButton(onPressed: _exportPdf, icon: const Icon(Icons.picture_as_pdf_rounded, color: AppTheme.danger)),
            ],
          ])),
        ],
      ),
    );
  }

  Widget _buildYearSummaryCard(BuildContext context, int year, bool useCompact) {
    final total = _annualAdvanceTotal ?? 0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: useCompact ? 8 : 14),
      decoration: BoxDecoration(color: Colors.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.teal.withValues(alpha: 0.25))),
      child: Row(children: [
        Container(padding: EdgeInsets.all(useCompact ? 6 : 8), decoration: BoxDecoration(color: Colors.teal.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.account_balance_wallet_rounded, color: Colors.teal, size: useCompact ? 18 : 20)),
        SizedBox(width: useCompact ? 10 : 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(year == 0 ? 'Permintaan Semua Tahun' : 'Permintaan Tahun $year', style: TextStyle(color: _bodyColor(context), fontSize: useCompact ? 9 : 11)),
          Text('Rp ${formatNumber(total)}', style: TextStyle(color: _primaryText(context), fontSize: useCompact ? 14 : 16, fontWeight: FontWeight.w700)),
        ]),
      ]),
    );
  }

}

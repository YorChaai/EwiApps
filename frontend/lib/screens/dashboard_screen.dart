import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settlement_provider.dart';
import '../theme/app_theme.dart';
import '../utils/file_helper.dart';
import '../utils/context_extensions.dart';
import '../widgets/notification_bell_icon.dart';
import 'settlement/settlement_detail_screen.dart';
import 'reports/report_screen.dart';
import 'advance/advances_screen.dart';
import 'advance/advance_detail_screen.dart';
import 'settings/settings_screen.dart';
import 'management/category_management_screen.dart';
import '../utils/responsive_layout.dart';
import 'widgets/sidebar.dart';
import 'widgets/page_selector.dart';
import 'widgets/common_widgets.dart';
import '../utils/app_snackbar.dart';
import '../providers/notification_provider.dart';
import '../models/notification_model.dart';

class DashboardScreen extends StatefulWidget {
  final int initialTabIndex;

  const DashboardScreen({super.key, this.initialTabIndex = 0});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _navIndex = 0;
  int _pendingSettlements = 0;
  int _pendingAdvances = 0;
  bool _sidebarExpanded = true;
  int? _lastNotificationId;
  Key _reportPageKey = UniqueKey();
  Key _settingsPageKey = UniqueKey();

  Color _surfaceColor(BuildContext context) => context.isDark ? AppTheme.surface : AppTheme.lightSurface;
  Color _dividerColor(BuildContext context) => context.isDark ? AppTheme.divider : AppTheme.lightDivider;
  Color _titleColor(BuildContext context) => context.isDark ? AppTheme.cream : AppTheme.lightTextPrimary;
  Color _bodyColor(BuildContext context) => context.isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

  @override
  void initState() {
    super.initState();
    _navIndex = widget.initialTabIndex;
    Future.microtask(() async {
      if (!mounted) return;
      final settlementProvider = context.read<SettlementProvider>();
      final notificationProvider = context.read<NotificationProvider>();
      await settlementProvider.syncReportYear();
      await Future.wait([
        settlementProvider.loadCategories(),
        settlementProvider.loadSettlements(),
        _fetchBadgeCounts(),
      ]);
      if (mounted) {
        notificationProvider.startPolling();
        _setupNotificationListener();
      }
    });
  }

  void _setupNotificationListener() {
    final provider = context.read<NotificationProvider>();
    provider.removeListener(_onNotificationUpdate);
    provider.addListener(_onNotificationUpdate);
  }

  void _onNotificationUpdate() {
    if (!mounted) return;
    final provider = context.read<NotificationProvider>();
    if (provider.notifications.isNotEmpty) {
      final latest = provider.notifications.first;
      if (_lastNotificationId == null) {
        _lastNotificationId = latest.id;
      } else if (latest.id > _lastNotificationId!) {
        _lastNotificationId = latest.id;
        _showNotificationSnackBar(latest);
      }
    }
  }

  void _showNotificationSnackBar(NotificationModel notification) {
    AppSnackbar.show(notification.message, isSuccess: true, duration: const Duration(seconds: 5));
  }

  @override
  void dispose() {
    try {
      if (mounted) context.read<NotificationProvider>().removeListener(_onNotificationUpdate);
    } catch (_) {}
    super.dispose();
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
    } catch (e) {
      debugPrint('Failed to fetch badge counts: $e');
    }
  }

  int? _extractIdFromPath(String path) {
    final parts = path.split('/');
    for (int i = parts.length - 1; i >= 0; i--) {
      final value = int.tryParse(parts[i]);
      if (value != null) return value;
    }
    return null;
  }

  Future<void> _handleNotificationTap(String rawPath) async {
    if (!mounted) return;
    final path = rawPath.trim().toLowerCase();
    final id = _extractIdFromPath(path);
    if (path.contains('/settlements')) {
      setState(() => _navIndex = 0);
      if (id != null) await Navigator.push(context, MaterialPageRoute(builder: (_) => SettlementDetailScreen(settlementId: id)));
      return;
    }
    if (path.contains('/advances')) {
      setState(() => _navIndex = 1);
      if (id != null) await Navigator.push(context, MaterialPageRoute(builder: (_) => AdvanceDetailScreen(advanceId: id)));
      return;
    }
    if (path.contains('/categories')) {
      if (context.read<AuthProvider>().isManager) setState(() => _navIndex = 3);
      return;
    }
    if (path.contains('/reports')) {
      if (context.read<AuthProvider>().isManager) setState(() => _navIndex = 2);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final isMobile = ResponsiveLayout.isMobile(context) || isAndroid;
    final isPhoneLandscape = ResponsiveLayout.isPhoneLandscape(context);
    final isTablet = ResponsiveLayout.isTablet(context);
    final safeWidth = ResponsiveLayout.safeWidth(context);
    final compactAppBar = safeWidth < 430;
    final showSidebar = !isMobile && !isAndroid;
    final sidebarWidth = showSidebar ? (isTablet || !_sidebarExpanded ? 80.0 : 240.0) : 0.0;
    final pages = [
      const _SettlementListView(),
      const AdvancesScreen(),
      if (auth.isManager) ReportScreen(key: _reportPageKey),
      if (auth.isManager) const CategoryManagementView(),
      SettingsScreen(key: _settingsPageKey),
    ];
    final currentIndex = _navIndex.clamp(0, pages.length - 1);

    // UI Scaling for mobile-like windows
    final useCompact = isMobile || safeWidth < 500;

    return Scaffold(
      body: Row(
        children: [
          if (showSidebar)
            SizedBox(
              width: sidebarWidth,
              child: DashboardSidebar(
                currentIndex: currentIndex,
                isManager: auth.isManager,
                fullName: auth.fullName,
                role: auth.roleDisplayName,
                onNotificationTap: _handleNotificationTap,
                onNavTap: (i) {
                  setState(() {
                    _navIndex = i;
                    if (i == 2) _reportPageKey = UniqueKey();
                    if (i == (auth.isManager ? 4 : 2)) _settingsPageKey = UniqueKey();
                  });
                },
                onLogout: () => auth.logout(),
                isMini: isTablet,
                isExpanded: _sidebarExpanded,
                onToggleExpand: isTablet ? null : () => setState(() => _sidebarExpanded = !_sidebarExpanded),
                pendingSettlements: auth.isManager ? _pendingSettlements : 0,
                pendingAdvances: auth.isManager ? _pendingAdvances : 0,
              ),
            ),
          if (showSidebar) Container(width: 1, color: _dividerColor(context)),
          Expanded(
            child: Scaffold(
              appBar: (isMobile || isAndroid || safeWidth < 500)
                  ? AppBar(
                      toolbarHeight: isPhoneLandscape ? 50 : (useCompact ? 56 : 64),
                      elevation: 0,
                      backgroundColor: _surfaceColor(context),
                      centerTitle: false,
                      titleSpacing: compactAppBar ? 8 : 16,
                      title: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: useCompact ? 6 : 8, vertical: useCompact ? 3 : 4),
                            decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(6)),
                            child: Text(auth.fullName.isNotEmpty ? auth.fullName[0].toUpperCase() : 'U', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: useCompact ? 11 : 12)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(auth.fullName.split(' ').first, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: _titleColor(context), fontSize: useCompact ? 13 : (compactAppBar ? 13 : 15), fontWeight: FontWeight.w600)),
                                if (!compactAppBar && safeWidth > 380) Text(auth.roleDisplayName, style: TextStyle(color: _bodyColor(context), fontSize: 9)),
                              ],
                            ),
                          ),                          const SizedBox(width: 8),
                          PageSelector(currentIndex: currentIndex, isManager: auth.isManager, compact: true, onChanged: (index) => setState(() => _navIndex = index)),
                        ],
                      ),
                      actions: [
                        NotificationBellIcon(onNotificationTap: _handleNotificationTap),
                        SizedBox(width: compactAppBar ? 2 : 4),
                        IconButton(icon: Icon(Icons.logout_rounded, size: useCompact ? 18 : 20), onPressed: () => auth.logout(), color: _bodyColor(context), tooltip: 'Logout'),
                        SizedBox(width: compactAppBar ? 4 : 8),
                      ],
                    )
                  : null,
              body: SafeArea(top: false, child: IndexedStack(index: currentIndex, children: pages)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettlementListView extends StatefulWidget {
  const _SettlementListView();
  @override
  State<_SettlementListView> createState() => _SettlementListViewState();
}

class _SettlementListViewState extends State<_SettlementListView> {
  static const Duration _searchDebounceDuration = Duration(milliseconds: 350);
  String? _statusFilter;
  DateTime? _startDate;
  DateTime? _endDate;
  String _searchQuery = '';
  double? _annualSettlementTotal;
  final ScrollController _listScrollController = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _searchDebounce;
  bool _showScrollToTop = false;
  final bool _selectionMode = false;
  final Set<int> _selectedSettlementIds = {};

  Color _cardColor(BuildContext context) => context.isDark ? AppTheme.card : AppTheme.lightCard;
  Color _titleColorLocal(BuildContext context) => context.isDark ? AppTheme.cream : AppTheme.lightTextPrimary;
  Color _bodyColorLocal(BuildContext context) => context.isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
  Color _primaryTextLocal(BuildContext context) => context.isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;


  void _handleListScroll() {
    if (!_listScrollController.hasClients) return;
    final shouldShow = _listScrollController.offset > 320;
    if (shouldShow != _showScrollToTop && mounted) setState(() => _showScrollToTop = shouldShow);
  }

  Future<void> _scrollToTop() async {
    if (!_listScrollController.hasClients) return;
    await _listScrollController.animateTo(0, duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic);
  }

  void _scheduleSettlementReload() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(_searchDebounceDuration, _reloadSettlements);
  }

  void _toggleSettlementSelection(int id, bool selected) {
    setState(() {
      if (selected) {
        _selectedSettlementIds.add(id);
      } else {
        _selectedSettlementIds.remove(id);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _listScrollController.addListener(_handleListScroll);
    final prov = context.read<SettlementProvider>();
    _statusFilter = prov.statusFilter;
    _searchQuery = prov.searchQuery ?? '';
    _searchCtrl.text = _searchQuery;
    if (prov.startDate != null) _startDate = DateTime.tryParse(prov.startDate!);
    if (prov.endDate != null) _endDate = DateTime.tryParse(prov.endDate!);
    _loadDefaultReportYearAndReload();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _listScrollController.removeListener(_handleListScroll);
    _listScrollController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDefaultReportYearAndReload() async {
    final prov = context.read<SettlementProvider>();
    await prov.syncReportYear();
    _reloadSettlements();
    _loadDashboardSummary();
    _loadAnnualSettlementSummary();
  }

  Future<void> _loadDashboardSummary() async {
    try {
      await context.read<AuthProvider>().api.getDashboardSummary();
    } catch (e) { debugPrint('ERROR dashboard summary: $e'); }
  }

  Future<void> _loadAnnualSettlementSummary() async {
    try {
      final prov = context.read<SettlementProvider>();
      final data = await prov.getSummary(year: prov.reportYear == 0 ? DateTime.now().year : prov.reportYear);
      if (mounted) setState(() => _annualSettlementTotal = ((data['grand_total'] ?? 0) as num).toDouble());
    } catch (e) { debugPrint('ERROR annual summary: $e'); }
  }

  void _reloadSettlements() {
    _searchDebounce?.cancel();
    _searchDebounce = null;
    final prov = context.read<SettlementProvider>();
    prov.loadSettlements(
      status: _statusFilter,
      startDate: _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : null,
      endDate: _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null,
      reportYear: prov.reportYear == 0 ? null : prov.reportYear,
      search: _searchQuery.isEmpty ? null : _searchQuery,
    );
    _loadAnnualSettlementSummary();
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2022),
      lastDate: DateTime(2030),
      initialDateRange: _startDate != null && _endDate != null ? DateTimeRange(start: _startDate!, end: _endDate!) : null,
    );
    if (picked != null) {
      setState(() { _startDate = picked.start; _endDate = picked.end; });
      _reloadSettlements();
    }
  }

  void _clearDateRange() {
    setState(() { _startDate = null; _endDate = null; });
    _reloadSettlements();
  }

  Future<void> _exportExcel() async {
    try {
      final prov = context.read<SettlementProvider>();
      final bytes = await prov.exportExcel(
        status: _statusFilter,
        startDate: _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : null,
        endDate: _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null,
      );
      final timestamp = FileHelper.formatTimestamp();
      if (!mounted) return;
      await FileHelper.saveAndOpenFolder(context: context, bytes: bytes, filename: 'Laporan_Settlement_$timestamp.xlsx');
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show('Gagal export Excel: $e', isError: true);
    }
  }

  Future<void> _exportPdf() async {
    try {
      final prov = context.read<SettlementProvider>();
      final bytes = await prov.getBulkPdf(
        status: _statusFilter,
        startDate: _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : null,
        endDate: _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null,
        reportYear: prov.reportYear,
      );
      final timestamp = FileHelper.formatTimestamp();
      if (!mounted) return;
      await FileHelper.saveAndOpenFile(context: context, bytes: bytes, filename: 'Laporan_Settlement_$timestamp.pdf');
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show('Gagal export PDF: $e', isError: true);
    }
  }

  void _showCreateDialog(BuildContext context) {
    final prov = context.read<SettlementProvider>();
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
          title: Text('Buat Settlement Baru',
              style: TextStyle(color: _titleColorLocal(context))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pemilihan Tahun
              DropdownButtonFormField<int>(
                initialValue: selectedYear,
                dropdownColor: _cardColor(context),
                decoration: InputDecoration(
                  labelText: 'Tahun Laporan',
                  labelStyle: TextStyle(color: _primaryTextLocal(context)),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: _primaryTextLocal(context).withValues(alpha: 0.3)),
                  ),
                ),
                style: TextStyle(color: _primaryTextLocal(context)),
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
                        label: Text('Sendiri'),
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
                  style: TextStyle(color: _primaryTextLocal(context)),
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
                            ? 'Pengeluaran Sendiri'
                            : titleCtrl.text.trim();
                        if (selectedType == 'batch' && title.isEmpty) return;

                        // Capture Navigator and SettlementProvider early
                        final navigator = Navigator.of(context);
                        final sProv = context.read<SettlementProvider>();

                        setDialogState(() => creating = true);
                        final result = await sProv.createSettlement(
                          title,
                          "",
                          settlementType: selectedType,
                          reportYear: selectedYear,
                        );

                        if (!ctx.mounted) return;

                        if (result != null) {
                          // Tutup dialog
                          Navigator.pop(ctx);

                          // Berpindah ke detail screen (gunakan navigator yang sudah dicapture)
                          navigator.push(
                            MaterialPageRoute(
                              builder: (_) => SettlementDetailScreen(
                                settlementId: result['id'],
                              ),
                            ),
                          );
                        } else {
                          setDialogState(() => creating = false);
                          AppSnackbar.show(sProv.error ?? 'Gagal membuat settlement', isError: true);
                        }
                      },
                child: creating                    ? const SizedBox(
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
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final prov = context.watch<SettlementProvider>();
    final canShowExport = _statusFilter == 'completed';
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
                        child: prov.loading || prov.settlements.isEmpty
                        ? CustomScrollView(
                            slivers: [
                              SliverToBoxAdapter(child: _buildScrollableSettlementHeader(context, auth, prov, isNarrow, isVeryNarrow, canShowExport, pagePadding, useCompact)),
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: prov.loading
                                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                                  : Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.inbox_rounded, size: 64, color: _bodyColorLocal(context).withValues(alpha: 0.3)), const SizedBox(height: 16), Text('Belum ada settlement', style: TextStyle(color: _bodyColorLocal(context)))])),
                              ),
                            ],
                          )
                        : Scrollbar(
                            controller: _listScrollController,
                            thumbVisibility: true,
                            thickness: 8,
                            child: RefreshIndicator(
                              onRefresh: () async => _reloadSettlements(),
                              child: Builder(
                                builder: (context) {
                                  final singles = prov.settlements.where((s) => (s['settlement_type'] ?? 'single') == 'single').toList();
                                  final batches = prov.settlements.where((s) => (s['settlement_type'] ?? 'single') == 'batch').toList();
                                  final items = <dynamic>[];
                                  if (singles.isNotEmpty) { items.add('__header_single__'); items.addAll(singles); }
                                  if (batches.isNotEmpty) { items.add('__header_batch__'); items.addAll(batches); }
                                  return CustomScrollView(
                                    controller: _listScrollController,
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    slivers: [
                                      SliverToBoxAdapter(child: _buildScrollableSettlementHeader(context, auth, prov, isNarrow, isVeryNarrow, canShowExport, pagePadding, useCompact)),
                                      SliverPadding(
                                        padding: EdgeInsets.only(left: isNarrow ? 16 : 24, right: isNarrow ? 16 : 24, bottom: isNarrow ? 16 : 24),
                                        sliver: SliverList(
                                          delegate: SliverChildBuilderDelegate(
                                            (context, i) {
                                              final item = items[i];
                                              if (item == '__header_single__') return _buildGroupHeader(Icons.receipt_long_rounded, 'Pengeluaran Sendiri (${singles.length})', AppTheme.primary);
                                              if (item == '__header_batch__') return _buildGroupHeader(Icons.folder_rounded, 'Pengeluaran Batch (${batches.length})', AppTheme.warning);
                                              final s = item as Map<String, dynamic>;
                                              return RepaintBoundary(
                                                child: SettlementCard(
                                                  key: ValueKey('settlement_${s['id']}'),
                                                  settlement: s,
                                                  isManager: auth.isManager,
                                                  onDelete: _selectionMode ? null : () => _deleteSettlement(s['id']),
                                                  selectionMode: _selectionMode,
                                                  selected: _selectedSettlementIds.contains(s['id']),
                                                  onSelectionChanged: (v) => _toggleSettlementSelection(s['id'], v),
                                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SettlementDetailScreen(settlementId: s['id']))).then((_) => _reloadSettlements()),
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
                        onPressed: _scrollToTop,
                        backgroundColor: _cardColor(context).withValues(alpha: 0.9),
                        child: const Icon(Icons.keyboard_arrow_up_rounded, color: AppTheme.primary),
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

  Widget _buildGroupHeader(IconData icon, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(children: [Icon(icon, size: 18, color: color), const SizedBox(width: 8), Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _titleColorLocal(context)))],),
    );
  }

  Widget _buildScrollableSettlementHeader(BuildContext context, AuthProvider auth, SettlementProvider prov, bool isNarrow, bool isVeryNarrow, bool canShowExport, EdgeInsets pagePadding, bool useCompact) {
    return Padding(
      padding: pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(auth.isManager ? 'Semua Settlement' : 'Settlement Saya', style: TextStyle(fontSize: useCompact ? 18 : (isNarrow ? 20 : 24), fontWeight: FontWeight.bold, color: _titleColorLocal(context))),
                Text('${prov.settlements.length} total', style: TextStyle(color: _bodyColorLocal(context), fontSize: useCompact ? 10 : 13)),
              ])),
              ElevatedButton.icon(
                onPressed: _selectionMode ? null : () => _showCreateDialog(context),
                icon: Icon(Icons.add, size: useCompact ? 16 : 20),
                label: Text(isNarrow ? 'Buat' : 'Buat Settlement', style: TextStyle(fontSize: useCompact ? 12 : 14)),
                style: ElevatedButton.styleFrom(
                  padding: useCompact ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8) : null,
                  minimumSize: useCompact ? const Size(0, 36) : null,
                ),
              ),
            ],
          ),
          SizedBox(height: useCompact ? 10 : 16),
          _buildSummaryCards(isNarrow, useCompact),
          SizedBox(height: useCompact ? 10 : 16),
          TextField(
            controller: _searchCtrl,
            style: TextStyle(fontSize: useCompact ? 13 : 14),
            decoration: InputDecoration(
              isDense: useCompact,
              hintText: 'Cari settlement...',
              prefixIcon: Icon(Icons.search, size: useCompact ? 18 : 24),
              contentPadding: useCompact ? const EdgeInsets.symmetric(vertical: 6) : null,
              suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: Icon(Icons.clear, size: useCompact ? 16 : 20), onPressed: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); _reloadSettlements(); }) : null,
            ),
            onChanged: (val) { setState(() => _searchQuery = val); _scheduleSettlementReload(); },
          ),
          SizedBox(height: useCompact ? 12 : 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
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
                      style: TextStyle(color: context.isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary, fontSize: useCompact ? 11 : 13, fontWeight: FontWeight.w500),
                      items: [
                        const DropdownMenuItem(value: 0, child: Text('Semua Tahun')),
                        ...List.generate(21, (index) => 2020 + index).map((y) => DropdownMenuItem(value: y, child: Text('Laporan $y'))),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        prov.setReportYear(value, reload: false);
                        _reloadSettlements();
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _FilterChipWidget(label: 'Semua', selected: _statusFilter == null, isMobile: useCompact, onTap: () { setState(() => _statusFilter = null); _reloadSettlements(); }),
                const SizedBox(width: 8),
                _FilterChipWidget(label: 'Draft', selected: _statusFilter == 'draft', isMobile: useCompact, onTap: () { setState(() => _statusFilter = 'draft'); _reloadSettlements(); }),
                const SizedBox(width: 8),
                _FilterChipWidget(label: 'Submitted', selected: _statusFilter == 'submitted', isMobile: useCompact, onTap: () { setState(() => _statusFilter = 'submitted'); _reloadSettlements(); }),
                const SizedBox(width: 8),
                _FilterChipWidget(label: 'Approved', selected: _statusFilter == 'approved', isMobile: useCompact, onTap: () { setState(() => _statusFilter = 'approved'); _reloadSettlements(); }),
                const SizedBox(width: 8),
                if (auth.isManager) _FilterChipWidget(label: 'Rejected', selected: _statusFilter == 'rejected', isMobile: useCompact, onTap: () { setState(() => _statusFilter = 'rejected'); _reloadSettlements(); }),

                const SizedBox(width: 8),
                IconButton(onPressed: () => _pickDateRange(context), icon: Icon(Icons.date_range_rounded, color: _startDate != null ? AppTheme.primary : _bodyColorLocal(context))),
                if (_startDate != null) IconButton(onPressed: _clearDateRange, icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.danger)),
                if (auth.isManager && canShowExport) ...[
                  const SizedBox(width: 8),
                  IconButton(onPressed: _exportExcel, icon: const Icon(Icons.table_chart_rounded, color: AppTheme.success)),
                  IconButton(onPressed: _exportPdf, icon: const Icon(Icons.picture_as_pdf_rounded, color: AppTheme.danger)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(bool isNarrow, bool useCompact) {
    final prov = context.read<SettlementProvider>();
    final total = _annualSettlementTotal ?? 0.0;
    final card = Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: useCompact ? 8 : 14),
      decoration: BoxDecoration(color: Colors.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.teal.withValues(alpha: 0.25))),
      child: Row(children: [
        Container(padding: EdgeInsets.all(useCompact ? 6 : 8), decoration: BoxDecoration(color: Colors.teal.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.account_balance_wallet_rounded, color: Colors.teal, size: useCompact ? 18 : 20)),
        SizedBox(width: useCompact ? 10 : 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(prov.reportYear == 0 ? 'Pengeluaran Semua Tahun' : 'Pengeluaran Tahun ${prov.reportYear}', style: TextStyle(fontSize: useCompact ? 9 : 11, color: _bodyColorLocal(context))),
          Text('Rp ${formatNumber(total)}', style: TextStyle(fontSize: useCompact ? 14 : 16, fontWeight: FontWeight.bold, color: _titleColorLocal(context))),
        ]),
      ]),
    );
    return isNarrow ? card : Row(children: [Expanded(child: card)]);
  }

  Future<void> _deleteSettlement(int id) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(backgroundColor: _cardColor(context), title: const Text('Hapus Settlement'), content: const Text('Apakah Anda yakin?'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')), ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger), child: const Text('Hapus'))]));
    if (confirm == true) {
      if (!mounted) return;
      await context.read<SettlementProvider>().deleteSettlement(id);
    }
  }
}

class _FilterChipWidget extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isMobile;
  final VoidCallback onTap;

  const _FilterChipWidget({
    required this.label,
    required this.selected,
    required this.isMobile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final borderColor = isDark ? AppTheme.divider : AppTheme.lightDivider;
    final textColor =
        isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 10 : 14,
          vertical: isMobile ? 6 : 8
        ),
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
            fontSize: isMobile ? 12 : 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? AppTheme.primary : textColor,
          ),
        ),
      ),
    );
  }
}

class StatusFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isMobile;
  final VoidCallback onTap;
  const StatusFilterChip({super.key, required this.label, required this.selected, this.isMobile = false, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return _FilterChipWidget(label: label, selected: selected, isMobile: isMobile, onTap: onTap);
  }
}

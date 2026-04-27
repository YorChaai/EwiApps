import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settlement_provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../utils/file_helper.dart';
import '../settings/balance_sheet_settings_screen.dart';
import '../management/category_tabular_screen.dart';
import '../management/dividend_management_screen.dart';
import '../management/revenue_management_screen.dart';
import '../management/tax_management_screen.dart';
import '../widgets/common_widgets.dart';
import '../../widgets/app_scrollbar.dart';

class AnnualReportScreen extends StatefulWidget {
  const AnnualReportScreen({super.key});

  @override
  State<AnnualReportScreen> createState() => _AnnualReportScreenState();
}

class _AnnualReportScreenState extends State<AnnualReportScreen> {
  int _selectedYear = 2024;
  String _filterMode = 'report'; // 'report' or 'actual'
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  Map<String, dynamic>? _reportData;
  List<Map<String, dynamic>> _categories = [];
  final ScrollController _scrollController = ScrollController();
  final ScrollController _expenseTableHorizontalController = ScrollController();
  final ScrollController _expenseTableVerticalController = ScrollController();
  final ScrollController _table1Controller = ScrollController();
  final ScrollController _table2Controller = ScrollController();
  final ScrollController _table3Controller = ScrollController();
  final ScrollController _table5Controller = ScrollController();
  final ScrollController _table1VController = ScrollController();
  final ScrollController _table2VController = ScrollController();
  final ScrollController _table3VController = ScrollController();
  final ScrollController _table5VController = ScrollController();
  final _currencyFormat = NumberFormat('#,##0', 'id_ID');

  // Cache untuk optimasi performa
  List<List<Map<String, dynamic>>>? _cachedGroupedExpenses;
  final Map<int, String> _subcategoryLabelCache = {};
  int? _lastProcessedReportYear;

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
  Color _cardColor(BuildContext context) =>
      _isDark(context) ? AppTheme.card : AppTheme.lightCard;
  Color _surfaceColor(BuildContext context) =>
      _isDark(context) ? AppTheme.surface : AppTheme.lightSurface;
  Color _dividerColor(BuildContext context) =>
      _isDark(context) ? AppTheme.divider : AppTheme.lightDivider;
  Color _titleColor(BuildContext context) =>
      _isDark(context) ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
  Color _bodyColor(BuildContext context) =>
      _isDark(context) ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
  Color _primaryText(BuildContext context) =>
      _isDark(context) ? AppTheme.textPrimary : AppTheme.lightTextPrimary;

  @override
  void initState() {
    super.initState();
    _loadDefaultReportYearAndFetch();
    _fetchCategories();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _expenseTableHorizontalController.dispose();
    _expenseTableVerticalController.dispose();
    _table1Controller.dispose();
    _table2Controller.dispose();
    _table3Controller.dispose();
    _table5Controller.dispose();
    _table1VController.dispose();
    _table2VController.dispose();
    _table3VController.dispose();
    _table5VController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    try {
      final api = context.read<AuthProvider>().api;
      final res = await api.getCategories();
      if (res.containsKey('categories')) {
        final cats = (res['categories'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        cats.sort(
          (a, b) => (a['sort_order'] ?? 999).compareTo(b['sort_order'] ?? 999),
        );
        if (mounted) setState(() => _categories = cats);
      }
    } catch (_) {}
  }

  Future<void> _loadDefaultReportYearAndFetch() async {
    try {
      final prov = context.read<SettlementProvider>();
      await prov.syncReportYear();
      if (mounted) setState(() => _selectedYear = prov.reportYear);
    } catch (_) {}
    await _fetchReport();
  }

  Future<void> _fetchReport() async {
    final controllers = <ScrollController>[
      _scrollController,
      _expenseTableHorizontalController,
      _expenseTableVerticalController,
      _table1Controller,
      _table2Controller,
      _table3Controller,
      _table5Controller,
      _table1VController,
      _table2VController,
      _table3VController,
      _table5VController,
    ];
    for (final c in controllers) {
      if (c.hasClients) c.jumpTo(0);
    }
    setState(() {
      _isLoading = true;
      _cachedGroupedExpenses = null;
      _subcategoryLabelCache.clear();
    });
    try {
      final api = context.read<AuthProvider>().api;

      // Persiapkan parameter tanggal untuk mode range
      final effectiveStartDate = _filterMode == 'range' && _startDate != null
          ? DateFormat('yyyy-MM-dd').format(_startDate!)
          : null;
      final effectiveEndDate = _filterMode == 'range' && _endDate != null
          ? DateFormat('yyyy-MM-dd').format(_endDate!)
          : null;

      // Note: Backend getAnnualReport might need updates if it doesn't support startDate/endDate yet
      // For now we keep existing signature but add support if needed
      final data = await api.getAnnualReport(
        year: _filterMode == 'range' ? null : _selectedYear,
        mode: _filterMode,
        startDate: effectiveStartDate,
        endDate: effectiveEndDate,
      );
      if (mounted) {
        setState(() {
          _reportData = data;
          _lastProcessedReportYear = _selectedYear;
          // Pre-calculate grouping immediately after data arrives
          final rawExpenses = _asListMap(data['operation_cost']?['data']);
          if (rawExpenses.isNotEmpty) {
            _cachedGroupedExpenses = _groupAnnualExpenses(rawExpenses);
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDateRange() async {
    final range = await AppDateRangePicker.show(
      context,
      initialRange: (_startDate != null && _endDate != null)
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );
    if (range != null) {
      setState(() {
        _startDate = range.start;
        _endDate = range.end;
        _filterMode = 'range';
      });
      _fetchReport();
    }
  }

  Future<void> _exportExcel() async {
    setState(() => _isLoading = true);
    try {
      final api = context.read<AuthProvider>().api;

      final effectiveStartDate = _filterMode == 'range' && _startDate != null
          ? DateFormat('yyyy-MM-dd').format(_startDate!)
          : null;
      final effectiveEndDate = _filterMode == 'range' && _endDate != null
          ? DateFormat('yyyy-MM-dd').format(_endDate!)
          : null;

      final bytes = await api.getAnnualReportExcel(
        year: _filterMode == 'range' ? null : _selectedYear,
        mode: _filterMode,
        startDate: effectiveStartDate,
        endDate: effectiveEndDate,
      );
      if (!mounted) return;
      final suffix = _filterMode == 'range'
          ? '${DateFormat('yyyyMMdd').format(_startDate!)}-${DateFormat('yyyyMMdd').format(_endDate!)}'
          : '$_selectedYear';
      await FileHelper.saveAndOpenFile(
        context: context,
        bytes: bytes,
        filename: 'Revenue-Cost_$suffix.xlsx',
        subFolder: 'Reports/Annual/Excel',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  List<Map<String, dynamic>> _asListMap(dynamic data) {
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '').toString().replaceAll(',', '')) ?? 0;
  }

  String _fmtMoney(dynamic value) {
    final v = _toDouble(value);
    return 'Rp ${_currencyFormat.format(v)}';
  }

  String _fmtDate(dynamic value) {
    final text = (value ?? '').toString();
    if (text.isEmpty) return '';
    try {
      final dt = DateTime.tryParse(text);
      return dt == null ? text : DateFormat('dd-MMM-yy').format(dt);
    } catch (_) {
      return text;
    }
  }

  DateTime _parseDate(dynamic value) {
    final text = (value ?? '').toString();
    if (text.isEmpty) return DateTime(_selectedYear, 1, 1);
    return DateTime.tryParse(text) ?? DateTime(_selectedYear, 1, 1);
  }

  int? _extractImportedRow(dynamic text) {
    final raw = (text ?? '').toString();
    if (raw.isEmpty) return null;
    final m = RegExp(
      r'Imported from row\s+(\d+)',
      caseSensitive: false,
    ).firstMatch(raw);
    return m == null ? null : int.tryParse(m.group(1) ?? '');
  }

  int _extractBatchNumber(String text) {
    final match = RegExp(
      r'\bbatch\s*#?\s*(\d+)\b',
      caseSensitive: false,
    ).firstMatch(text);
    return match == null
        ? (1 << 30)
        : (int.tryParse(match.group(1) ?? '') ?? (1 << 30));
  }

  bool _isBatchSettlement(Map<String, dynamic> item) {
    final stype = (item['settlement_type'] ?? '')
        .toString()
        .toLowerCase()
        .trim();
    if (stype == 'batch') return true;
    if (stype == 'single') return false;
    final title = (item['settlement_title'] ?? '').toString().toLowerCase();
    return title.contains('batch');
  }

  String _cleanSettlementTitle(String title) {
    var text = title.trim();
    if (text.isEmpty) return 'Tanpa Settlement';
    text = text.replaceFirst(
      RegExp(r'^\s*single\s*[-:]\s*', caseSensitive: false),
      '',
    );
    text = text.replaceFirst(
      RegExp(r'^\s*batch\s*#?\s*\d+\s*[-:]\s*', caseSensitive: false),
      '',
    );
    text = text.replaceFirst(
      RegExp(r'^\s*batch\s*[-:]\s*', caseSensitive: false),
      '',
    );
    return text.trim().isEmpty ? 'Tanpa Settlement' : text.trim();
  }

  String _extractNoteSubcategory(Map<String, dynamic> item) {
    final notes = (item['notes'] ?? '').toString().trim();
    if (notes.isEmpty) return '';
    final match = RegExp(
      r'\bSubcategory:\s*([^|]+)',
      caseSensitive: false,
    ).firstMatch(notes);
    return match?.group(1)?.trim() ?? '';
  }

  int _subcategorySortBucket(String label) {
    final text = label.trim();
    if (text.isEmpty || text == '-') return 2;
    if (text.contains(',')) return 0;
    return 1;
  }

  List<List<Map<String, dynamic>>> _groupAnnualExpenses(
    List<Map<String, dynamic>> expenses,
  ) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final e in expenses) {
      final sid = (e['settlement_id'] ?? '').toString();
      final key = sid.isNotEmpty
          ? 'id:$sid'
          : 'title:${(e['settlement_title'] ?? '').toString()}';
      grouped.putIfAbsent(key, () => <Map<String, dynamic>>[]).add(e);
    }
    final groups = grouped.values.toList();
    for (final g in groups) {
      g.sort((a, b) {
        final bucketCmp = _subcategorySortBucket(
          _expenseSubcategoryLabel(a),
        ).compareTo(_subcategorySortBucket(_expenseSubcategoryLabel(b)));
        if (bucketCmp != 0) return bucketCmp;
        final aSub = _expenseSubcategoryLabel(a).toLowerCase();
        final bSub = _expenseSubcategoryLabel(b).toLowerCase();
        if (aSub != bSub) return aSub.compareTo(bSub);
        final aImported = _extractImportedRow(a['notes']);
        final bImported = _extractImportedRow(b['notes']);
        if (aImported != null || bImported != null) {
          final ai = aImported ?? (1 << 30);
          final bi = bImported ?? (1 << 30);
          if (ai != bi) return ai.compareTo(bi);
        }
        final da = _parseDate(a['date']);
        final db = _parseDate(b['date']);
        if (da != db) return da.compareTo(db);
        return (int.tryParse((a['id'] ?? '0').toString()) ?? 0).compareTo(
          int.tryParse((b['id'] ?? '0').toString()) ?? 0,
        );
      });
    }
    groups.sort((a, b) {
      final af = a.first;
      final bf = b.first;
      final aSub = _expenseSubcategoryLabel(af);
      final bSub = _expenseSubcategoryLabel(bf);
      final subBucketCmp = _subcategorySortBucket(
        aSub,
      ).compareTo(_subcategorySortBucket(bSub));
      if (subBucketCmp != 0) return subBucketCmp;
      if (aSub.toLowerCase() != bSub.toLowerCase()) {
        return aSub.toLowerCase().compareTo(bSub.toLowerCase());
      }
      final aBatch = _isBatchSettlement(af);
      final bBatch = _isBatchSettlement(bf);
      if (aBatch != bBatch) return aBatch ? 1 : -1;
      final aDate = a
          .map((x) => _parseDate(x['date']))
          .reduce((x, y) => x.isBefore(y) ? x : y);
      final bDate = b
          .map((x) => _parseDate(x['date']))
          .reduce((x, y) => x.isBefore(y) ? x : y);
      if (aBatch && bBatch) {
        final aNum = _extractBatchNumber(
          (af['settlement_title'] ?? '').toString(),
        );
        final bNum = _extractBatchNumber(
          (bf['settlement_title'] ?? '').toString(),
        );
        if (aNum != bNum) return aNum.compareTo(bNum);
      }
      final dateCmpVal = aDate.compareTo(bDate);
      return dateCmpVal != 0
          ? dateCmpVal
          : (int.tryParse((af['settlement_id'] ?? '0').toString()) ?? 0)
                .compareTo(
                  int.tryParse((bf['settlement_id'] ?? '0').toString()) ?? 0,
                );
    });
    return groups;
  }

  String _expenseSubcategoryLabel(Map<String, dynamic> item) {
    final backendSub = (item['subcategory_name'] ?? '').toString().trim();
    if (backendSub.isNotEmpty && backendSub != '-') return backendSub;
    final rawDesc = (item['description'] ?? '').toString();
    final extracted = RegExp(r'^\[(.*?)\]\s*(.*)$').firstMatch(rawDesc);
    if (extracted?.group(1) != null) return extracted!.group(1)!.trim();
    final noteSub = _extractNoteSubcategory(item);
    if (noteSub.isNotEmpty) return noteSub;
    return backendSub;
  }

  List<double> _getColumnWidths(String title, int colCount, bool useCompact) {
    if (title.contains('Tabel 4')) {
      return [
        100,
        50,
        400,
        100,
        160,
        80,
        80,
        ...List<double>.filled(math.max(colCount - 7, 0), 200),
      ];
    }
    if (title.contains('Tabel 1')) {
      return [
        100,
        50,
        280,
        140,
        70,
        70,
        120,
        150,
        100,
        140,
        110,
        110,
        100,
        180,
      ];
    }
    if (title.contains('Tabel 2')) {
      return [
        100,
        50,
        250,
        130,
        70,
        70,
        130,
        110,
        130,
        110,
        130,
        110,
        130,
        110,
      ];
    }
    if (title.contains('Tabel 3')) {
      return [110, 50, 180, 150, 150, 150];
    }
    if (title.contains('Tabel 5')) {
      return [250, 200];
    }
    return List<double>.filled(colCount, 150);
  }

  Widget _buildTableCard({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
    required ScrollController controller,
    required ScrollController verticalController,
    Set<int> boldRows = const {},
    bool useCompact = false,
  }) {
    const double leftScrollbarSpace = 14;
    final colWidths = _getColumnWidths(title, headers.length, useCompact);
    final totalWidth = colWidths.fold<double>(0, (a, b) => a + b);
    final rowHeight = title.contains('Tabel 4') ? 60.0 : 52.0;

    return Card(
      color: _cardColor(context),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _dividerColor(context)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: useCompact ? 6 : 10,
          vertical: useCompact ? 8 : 12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: _titleColor(context),
                fontWeight: FontWeight.bold,
                fontSize: useCompact ? 14 : 15,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                border: Border.all(color: _dividerColor(context)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: AppScrollbar(
                controller: verticalController,
                thumbVisibility: true,
                interactive: true,
                scrollbarOrientation: ScrollbarOrientation.left,
                notificationPredicate: (notification) =>
                    notification.metrics.axis == Axis.vertical,
                child: Padding(
                  padding: const EdgeInsets.only(left: leftScrollbarSpace),
                  child: AppScrollbar(
                    controller: controller,
                    thumbVisibility: true,
                    interactive: true,
                    scrollDirection: Axis.horizontal,
                    notificationPredicate: (notification) =>
                        notification.metrics.axis == Axis.horizontal,
                    child: SingleChildScrollView(
                      controller: controller,
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),
                      child: SizedBox(
                        width: totalWidth + leftScrollbarSpace,
                        child: Column(
                          children: [
                            // Header Row
                            Container(
                              color: _surfaceColor(context),
                              height: 48,
                              child: Row(
                                children: headers.asMap().entries.map((e) {
                                  return _buildExpenseTableCell(
                                    value: e.value,
                                    width: colWidths[e.key],
                                    useCompact: useCompact,
                                    isBold: true,
                                    textAlign: e.key == 1
                                        ? TextAlign.center
                                        : (_isNumericLikeCell(e.value, e.key)
                                              ? TextAlign.right
                                              : TextAlign.left),
                                    fontSize: 13,
                                  );
                                }).toList(),
                              ),
                            ),
                            // Lazy Body (Dynamic Height)
                            SizedBox(
                              height: math
                                  .min(
                                    rows.length * rowHeight,
                                    useCompact ? 650.0 : 800.0,
                                  )
                                  .toDouble()
                                  .clamp(rowHeight, 800.0),
                              child: RepaintBoundary(
                                child: NotificationListener<ScrollNotification>(
                                  onNotification: (notification) {
                                    if (notification.metrics.axis ==
                                        Axis.vertical) {
                                      if (notification
                                              is ScrollUpdateNotification &&
                                          notification.scrollDelta != null) {
                                        final delta = notification.scrollDelta!;
                                        final metrics = notification.metrics;
                                        if ((delta > 0 &&
                                                metrics.pixels >=
                                                    metrics.maxScrollExtent) ||
                                            (delta < 0 &&
                                                metrics.pixels <= 0)) {
                                          _scrollController.position.jumpTo(
                                            (_scrollController.offset + delta)
                                                .clamp(
                                                  0,
                                                  _scrollController
                                                      .position
                                                      .maxScrollExtent,
                                                ),
                                          );
                                        }
                                      } else if (notification
                                          is OverscrollNotification) {
                                        _scrollController.position.jumpTo(
                                          (_scrollController.offset +
                                                  notification.overscroll)
                                              .clamp(
                                                0,
                                                _scrollController
                                                    .position
                                                    .maxScrollExtent,
                                              ),
                                        );
                                      }
                                    }
                                    return false;
                                  },
                                  child: ListView.builder(
                                    controller: verticalController,
                                    itemCount: rows.length,
                                    itemExtent: rowHeight,
                                    cacheExtent: 1000,
                                    padding: const EdgeInsets.only(left: 2),
                                    physics: const ClampingScrollPhysics(),
                                    itemBuilder: (context, rowIndex) {
                                      final row = rows[rowIndex];
                                      final isBold = boldRows.contains(rowIndex);
                                      return Container(
                                        decoration: BoxDecoration(
                                          color: isBold
                                              ? _surfaceColor(context)
                                              : (rowIndex.isEven
                                                    ? (_isDark(context)
                                                          ? const Color(
                                                              0xFF1E293B,
                                                            )
                                                          : const Color(
                                                              0xFFF1F5F9,
                                                            ))
                                                    : (_isDark(context)
                                                          ? const Color(
                                                              0xFF0F172A,
                                                            )
                                                          : Colors.white)),
                                          border: Border(
                                            bottom: BorderSide(
                                              color: _dividerColor(context),
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: row.asMap().entries.map((e) {
                                            return _buildExpenseTableCell(
                                              value: e.value,
                                              width: colWidths[e.key],
                                              useCompact: useCompact,
                                              isBold: isBold,
                                              textAlign: e.key == 1
                                                  ? TextAlign.center
                                                  : (_isNumericLikeCell(
                                                          headers[e.key],
                                                          e.key,
                                                        )
                                                        ? TextAlign.right
                                                        : TextAlign.left),
                                            );
                                          }).toList(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
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
    );
  }

  bool _isNumericLikeCell(String header, int index) {
    final text = header.toLowerCase().trim();
    if (index == 1) return true;
    return text == 'amount' ||
        text == 'amt' ||
        text == 'rate' ||
        text == 'value' ||
        text == 'val' ||
        text == 'ppn' ||
        text.startsWith('pph') ||
        text.startsWith('dpp') ||
        text == 'fee' ||
        text == 'nilai' ||
        text == 'total';
  }

  Widget _buildExpenseTableCell({
    required String value,
    required double width,
    required bool useCompact,
    required bool isBold,
    required TextAlign textAlign,
    int maxLines = 1,
    double? fontSize,
  }) {
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(
        horizontal: useCompact ? 8 : 10,
        vertical: useCompact ? 8 : 10,
      ),
      alignment: switch (textAlign) {
        TextAlign.right => Alignment.centerRight,
        TextAlign.center => Alignment.center,
        _ => Alignment.centerLeft,
      },
      child: Text(
        value,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: fontSize ?? 13,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: isBold ? _titleColor(context) : _primaryText(context),
        ),
      ),
    );
  }



  Widget _buildCacheInfo(bool useCompact, {bool isCompact = false}) {
    final source = (_reportData?['cache_source'] ?? '').toString();
    final generated = (_reportData?['cache_generated_at'] ??
            _reportData?['generated_at'] ??
            '')
        .toString();
    String label = (source == 'cache')
        ? 'CACHE (tidak hit DB)'
        : (source == 'refresh' ? 'REFRESH (DB terbaru)' : 'INIT');
    return Container(
      width: isCompact ? null : double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 16,
        vertical: isCompact ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: _surfaceColor(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _dividerColor(context)),
      ),
      child: Text(
        isCompact
            ? '$label | Generated: ${generated.length > 10 ? generated.substring(11, 16) : ''}'
            : 'Display Source: $label | Generated: ${_fmtDate(generated)} ${generated.length > 10 ? generated.substring(11, 19).trim() : ''}',
        style: TextStyle(
          color: _bodyColor(context),
          fontSize: useCompact || isCompact ? 11 : 13,
          height: 1.2,
        ),
      ),
    );
  }

  Widget _buildDisplayTables(bool useCompact) {
    final revenueData = _asListMap(_reportData?['revenue']?['data']);
    final taxData = _asListMap(_reportData?['tax']?['data']);
    final dividendData = _asListMap(_reportData?['dividend']?['data']);
    final expenseData = _asListMap(_reportData?['operation_cost']?['data']);

    final List<List<String>> revenueRows = revenueData
        .asMap()
        .entries
        .map(
          (e) => [
            _fmtDate(e.value['invoice_date']),
            '${e.key + 1}',
            e.value['description']?.toString() ?? '',
            _fmtMoney(e.value['invoice_value']),
            e.value['currency']?.toString() ?? 'IDR',
            _toDouble(e.value['currency_exchange'] ?? 1).toStringAsFixed(0),
            e.value['invoice_number']?.toString() ?? '',
            e.value['client']?.toString() ?? '',
            _fmtDate(e.value['receive_date']),
            _fmtMoney(e.value['amount_received']),
            _fmtMoney(e.value['ppn']),
            _fmtMoney(e.value['pph_23']),
            _fmtMoney(e.value['transfer_fee']),
            e.value['remark']?.toString() ?? '',
          ],
        )
        .toList();
    revenueRows.add([
      'TOTAL',
      '',
      '',
      _fmtMoney(_reportData?['revenue']?['total_amount_received'] ?? 0),
      '',
      '',
      '',
      '',
      '',
      _fmtMoney(_reportData?['revenue']?['total_amount_received'] ?? 0),
      _fmtMoney(_reportData?['revenue']?['total_ppn'] ?? 0),
      _fmtMoney(_reportData?['revenue']?['total_pph23'] ?? 0),
      '',
      '',
    ]);

    final List<List<String>> taxRows = taxData
        .asMap()
        .entries
        .map(
          (e) => [
            _fmtDate(e.value['date']),
            '${e.key + 1}',
            e.value['description']?.toString() ?? '',
            _fmtMoney(e.value['transaction_value']),
            e.value['currency']?.toString() ?? 'IDR',
            _toDouble(e.value['currency_exchange'] ?? 1).toStringAsFixed(0),
            _fmtMoney(e.value['transaction_value']),
            _fmtMoney(e.value['ppn']),
            _fmtMoney(e.value['transaction_value']),
            _fmtMoney(e.value['pph_21']),
            _fmtMoney(e.value['transaction_value']),
            _fmtMoney(e.value['pph_23']),
            _fmtMoney(e.value['transaction_value']),
            _fmtMoney(e.value['pph_26']),
          ],
        )
        .toList();
    taxRows.add([
      'TOTAL',
      '',
      '',
      '',
      '',
      '',
      '',
      _fmtMoney(_reportData?['tax']?['total_ppn'] ?? 0),
      '',
      _fmtMoney(_reportData?['tax']?['total_pph21'] ?? 0),
      '',
      _fmtMoney(_reportData?['tax']?['total_pph23'] ?? 0),
      '',
      _fmtMoney(_reportData?['tax']?['total_pph26'] ?? 0),
    ]);

    final List<List<String>> dividendRows = dividendData
        .asMap()
        .entries
        .map(
          (e) => [
            _fmtDate(e.value['date']),
            '${e.key + 1}',
            e.value['name']?.toString() ?? '-',
            _fmtMoney(_reportData?['dividend']?['profit_retained'] ?? 0),
            _fmtMoney(_reportData?['dividend']?['total_amount'] ?? 0),
            _fmtMoney(_reportData?['dividend']?['dividend_per_person'] ?? 0),
          ],
        )
        .toList();
    dividendRows.add([
      'TOTAL',
      '',
      '',
      _fmtMoney(_reportData?['dividend']?['profit_retained'] ?? 0),
      _fmtMoney(_reportData?['dividend']?['total_amount'] ?? 0),
      _fmtMoney(_reportData?['dividend']?['dividend_per_person'] ?? 0),
    ]);

    // ✅ Optimasi: Gunakan cache jika tersedia dan tahun laporan tidak berubah
    final List<List<Map<String, dynamic>>> expenseGroups;
    if (_cachedGroupedExpenses != null &&
        _lastProcessedReportYear == _selectedYear) {
      expenseGroups = _cachedGroupedExpenses!;
    } else {
      expenseGroups = _groupAnnualExpenses(expenseData);
    }

    // ✅ 1. Pre-calculate totals for ALL categories first to identify non-zero ones
    final Map<int, double> tempTotals = {};
    for (var group in expenseGroups) {
      for (var e in group) {
        final catName = e['category_name']?.toString() ?? '';
        final amount = _toDouble(e['idr_amount'] ?? e['amount']);
        // Find category ID by name
        int catId = -1;
        for (var c in _categories) {
          if ((c['name'] ?? '').toString().toLowerCase() == catName.toLowerCase()) {
            catId = c['id'];
            break;
          }
        }
        if (catId != -1) {
          tempTotals[catId] = (tempTotals[catId] ?? 0) + amount;
        }
      }
    }

    // ✅ 2. Filter categories that have total > 0
    final filteredCategories = _categories.where((c) {
      final id = c['id'];
      return (tempTotals[id] ?? 0) > 0;
    }).toList();

    // ✅ 3. Build headers and totals based on filtered categories
    final catHeaders = filteredCategories.isNotEmpty
        ? filteredCategories.map((c) => (c['name'] ?? '').toString()).toList()
        : ['Expenses'];
    final catTotals = List<double>.filled(catHeaders.length, 0);

    // Helper to get index in filtered list
    int getFilteredCatIndex(String categoryName) {
      final target = categoryName.toLowerCase().trim();
      for (int i = 0; i < filteredCategories.length; i++) {
        final name = (filteredCategories[i]['name'] ?? '').toString().toLowerCase();
        if (name == target) return i;
      }
      return -1;
    }

    final List<List<String>> expenseRows = <List<String>>[];
    final expenseBoldRows = <int>{};

    // RESTORE GROUPING LOGIC EXACTLY
    final List<Map<String, dynamic>> allSingles = [];
    final List<List<Map<String, dynamic>>> allBatches = [];
    for (final group in expenseGroups) {
      if (_isBatchSettlement(group.first)) {
        allBatches.add(group);
      } else {
        allSingles.addAll(group);
      }
    }

    // Sort batches by ID (Ascending) to match Excel/Database
    allBatches.sort(
      (a, b) => (int.tryParse(a.first['settlement_id']?.toString() ?? '0') ?? 0)
          .compareTo(
            int.tryParse(b.first['settlement_id']?.toString() ?? '0') ?? 0,
          ),
    );

    // 1. Single Expenses
    final Map<String, List<Map<String, dynamic>>> singleMap = {};
    for (final e in allSingles) {
      final sub = _expenseSubcategoryLabel(e);
      singleMap.putIfAbsent(sub, () => []).add(e);
    }
    final sortedSingleSubs = singleMap.keys.toList()
      ..sort(
        (a, b) =>
            _subcategorySortBucket(a).compareTo(_subcategorySortBucket(b)) != 0
            ? _subcategorySortBucket(a).compareTo(_subcategorySortBucket(b))
            : a.toLowerCase().compareTo(b.toLowerCase()),
      );

    int singleCounter = 0;
    for (final sub in sortedSingleSubs) {
      expenseBoldRows.add(expenseRows.length);
      expenseRows.add([
        '',
        '',
        sub,
        '',
        '',
        '',
        '',
        ...List.filled(catHeaders.length, ''),
      ]);
      for (final e in singleMap[sub]!) {
        singleCounter++;
        final amount = _toDouble(e['idr_amount'] ?? e['amount']);
        final idx = getFilteredCatIndex(e['category_name'] ?? '');
        final rowCats = List<String>.filled(catHeaders.length, '-');
        if (idx < catHeaders.length) {
          rowCats[idx] = _fmtMoney(amount);
          catTotals[idx] += amount;
        }
        expenseRows.add([
          _fmtDate(e['date']),
          '$singleCounter',
          e['description']?.toString() ?? '',
          e['source']?.toString() ?? '',
          _fmtMoney(amount),
          e['currency']?.toString() ?? 'IDR',
          _toDouble(e['currency_exchange'] ?? 1).toStringAsFixed(0),
          ...rowCats,
        ]);
      }
    }

    // ✅ ADD SEPARATOR (MATCH EXCEL)
    expenseBoldRows.add(expenseRows.length);
    expenseRows.add([
      '',
      '',
      'OPERATION COST AND OFFICE - Expenses Report',
      '',
      '',
      '',
      '',
      ...List.filled(catHeaders.length, ''),
    ]);

    // 2. Batch Expenses (Expense#1, Expense#2...)
    int batchCounter = 0;
    for (final group in allBatches) {
      batchCounter++;
      expenseBoldRows.add(expenseRows.length);
      final settlementTitle = _cleanSettlementTitle(
        group.first['settlement_title']?.toString() ?? 'Tanpa Settlement',
      );
      expenseRows.add([
        'Expense#$batchCounter',
        ':',
        settlementTitle,
        '',
        '',
        '',
        '',
        ...List.filled(catHeaders.length, ''),
      ]);

      final Map<String, List<Map<String, dynamic>>> subMap = {};
      for (final e in group) {
        final sub = _expenseSubcategoryLabel(e);
        subMap.putIfAbsent(sub, () => []).add(e);
      }
      final sortedBatchSubs = subMap.keys.toList()
        ..sort(
          (a, b) =>
              _subcategorySortBucket(a).compareTo(_subcategorySortBucket(b)) !=
                  0
              ? _subcategorySortBucket(a).compareTo(_subcategorySortBucket(b))
              : a.toLowerCase().compareTo(b.toLowerCase()),
        );

      for (final sub in sortedBatchSubs) {
        expenseBoldRows.add(expenseRows.length);
        expenseRows.add([
          '',
          '',
          sub,
          '',
          '',
          '',
          '',
          ...List.filled(catHeaders.length, ''),
        ]);
        int subCounter = 0;
        for (final e in subMap[sub]!) {
          subCounter++;
          final amount = _toDouble(e['idr_amount'] ?? e['amount']);
          final idx = getFilteredCatIndex(e['category_name'] ?? '');
          final rowCats = List<String>.filled(catHeaders.length, '-');
          if (idx < catHeaders.length) {
            rowCats[idx] = _fmtMoney(amount);
            catTotals[idx] += amount;
          }
          expenseRows.add([
            _fmtDate(e['date']),
            '$subCounter',
            e['description']?.toString() ?? '',
            e['source']?.toString() ?? '',
            _fmtMoney(amount),
            e['currency']?.toString() ?? 'IDR',
            _toDouble(e['currency_exchange'] ?? 1).toStringAsFixed(0),
            ...rowCats,
          ]);
        }
      }
    }

    expenseRows.add([
      'TOTAL',
      '',
      '',
      '',
      _fmtMoney(_reportData?['operation_cost']?['total_expenses'] ?? 0),
      '',
      '',
      ...catTotals.map(_fmtMoney),
    ]);

    final settings = (_reportData?['dividend']?['settings'] as Map?) ?? {};
    final List<List<String>> neracaRows = [
      ['Kas Sebelumnya', _fmtMoney(settings['opening_cash_balance'] ?? 0)],
      ['Piutang Usaha', _fmtMoney(settings['accounts_receivable'] ?? 0)],
      ['Pajak di Muka', _fmtMoney(settings['prepaid_tax_pph23'] ?? 0)],
      ['Hutang Usaha', _fmtMoney(settings['accounts_payable'] ?? 0)],
      ['Modal Saham', _fmtMoney(settings['share_capital'] ?? 0)],
    ];

    return Column(
      children: [
        _buildTableCard(
          title: 'Tabel 1: REVENUE & TAX',
          headers: const [
            'Date',
            '#',
            'Desc',
            'Value',
            'Curr',
            'Rate',
            'Inv No',
            'Client',
            'Rec Date',
            'Amount',
            'PPN',
            'PPH23',
            'Fee',
            'Rem',
          ],
          rows: revenueRows,
          controller: _table1Controller,
          verticalController: _table1VController,
          useCompact: useCompact,
        ),
        _buildTableCard(
          title: 'Tabel 2: PAJAK',
          headers: const [
            'Date',
            '#',
            'Desc',
            'Val',
            'Cur',
            'Rate',
            'DPP1',
            'PPN',
            'DPP2',
            'PPH21',
            'DPP3',
            'PPH23',
            'DPP4',
            'PPH26',
          ],
          rows: taxRows,
          controller: _table2Controller,
          verticalController: _table2VController,
          useCompact: useCompact,
        ),
        _buildTableCard(
          title: 'Tabel 3: DIVIDEN',
          headers: const [
            'Date',
            '#',
            'Nama',
            'Profit',
            'Dividen',
            'Per Person',
          ],
          rows: dividendRows,
          controller: _table3Controller,
          verticalController: _table3VController,
          useCompact: useCompact,
        ),
        _buildTableCard(
          title: 'Tabel 4: OPERATION COST',
          headers: [
            'Date',
            '#',
            'Activity',
            'Src',
            'Amount',
            'Cur',
            'Rate',
            ...catHeaders,
          ],
          rows: expenseRows,
          boldRows: expenseBoldRows,
          controller: _expenseTableHorizontalController,
          verticalController: _expenseTableVerticalController,
          useCompact: useCompact,
        ),
        _buildTableCard(
          title: 'Tabel 5: NERACA',
          headers: const ['Parameter', 'Nilai'],
          rows: neracaRows,
          controller: _table5Controller,
          verticalController: _table5VController,
          useCompact: useCompact,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final useCompact = screenWidth < 550;
    final showMainScrollbar = screenWidth > (useCompact ? 550 : 800);

    return Scaffold(
      backgroundColor: _surfaceColor(context),
      appBar: AppBar(
        title: useCompact
            ? const SizedBox.shrink() // Sembunyikan judul di layar sempit
            : const Text(
                'Laporan Tahunan',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
        backgroundColor: _cardColor(context),
        titleSpacing: useCompact ? 0 : NavigationToolbar.kMiddleSpacing,
        actions: [
          // Filter Periode Cascading (Laporan, Year, Range)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: CascadingYearFilter(
              selectedYear: _selectedYear,
              currentMode: _filterMode,
              useCompact: useCompact,
              startDate: _startDate,
              endDate: _endDate,
              onSelected: (year, mode) {
                setState(() {
                  _selectedYear = year;
                  _filterMode = mode;
                });
                _fetchReport();
              },
              onRangeTap: _pickDateRange,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.sort, color: AppTheme.primary),
            onPressed: () => _navTo(const CategoryTabularScreen()),
            tooltip: 'Kategori Tabular',
          ),
          IconButton(
            icon: const Icon(Icons.table_view, color: Colors.green),
            onPressed: _isLoading ? null : _exportExcel,
            tooltip: 'Export Excel',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _reportData == null
          ? Center(
              child: Text(
                'Tidak ada data.',
                style: TextStyle(color: _titleColor(context)),
              ),
            )
          : AppScrollbar(
              controller: _scrollController,
              thumbVisibility: showMainScrollbar,
              trackVisibility: showMainScrollbar,
              interactive: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.fromLTRB(
                  useCompact ? 12 : 16,
                  16,
                  useCompact ? 12 : 16,
                  96,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (useCompact) ...[
                      Text(
                        'Laporan Tahunan',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _titleColor(context),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _buildSummaryCards(useCompact),
                    const SizedBox(height: 16),
                    _buildCacheInfo(useCompact),
                    const SizedBox(height: 12),
                    _buildInputButtons(useCompact),
                    const SizedBox(height: 12),
                    _buildDisplayTables(useCompact),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCards(bool useCompact) {
    final revTotal = _toDouble(
      _reportData?['revenue']?['total_amount_received'] ?? 0,
    );
    final taxTotal =
        _toDouble(_reportData?['tax']?['total_ppn'] ?? 0) +
        _toDouble(_reportData?['tax']?['total_pph21'] ?? 0) +
        _toDouble(_reportData?['tax']?['total_pph23'] ?? 0) +
        _toDouble(_reportData?['tax']?['total_pph26'] ?? 0);
    final opTotal = _toDouble(
      _reportData?['operation_cost']?['total_expenses'] ?? 0,
    );
    final cards = [
      _buildCard('Received', revTotal, Colors.green, useCompact),
      _buildCard('Tax Out', taxTotal, Colors.orange, useCompact),
      _buildCard('Op. Cost', opTotal, AppTheme.primary, useCompact),
    ];
    return useCompact
        ? Column(
            children: cards
                .map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: c,
                  ),
                )
                .toList(),
          )
        : Row(
            children: cards
                .map(
                  (c) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: c,
                    ),
                  ),
                )
                .toList(),
          );
  }

  Widget _buildCard(String title, double amount, Color color, bool useCompact) {
    return Container(
      padding: EdgeInsets.all(useCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: _cardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _dividerColor(context)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: _bodyColor(context),
                    fontSize: useCompact ? 10 : 12,
                  ),
                ),
                Text(
                  _fmtMoney(amount),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: useCompact ? 15 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.trending_up_rounded,
            color: color.withValues(alpha: 0.3),
            size: useCompact ? 20 : 24,
          ),
        ],
      ),
    );
  }

  Widget _buildInputButtons(bool useCompact) {
    final style = ElevatedButton.styleFrom(
      padding: EdgeInsets.symmetric(
        horizontal: useCompact ? 8 : 16,
        vertical: useCompact ? 8 : 12,
      ),
      minimumSize: Size(0, useCompact ? 36 : 44),
      textStyle: TextStyle(
        fontSize: useCompact ? 11 : 13,
        fontWeight: FontWeight.bold,
      ),
    );
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ElevatedButton.icon(
          style: style,
          onPressed: () =>
              _navTo(RevenueManagementScreen(
                initialYear: _selectedYear,
                initialFilterMode: _filterMode,
                initialStartDate: _startDate,
                initialEndDate: _endDate,
              )),
          icon: const Icon(Icons.receipt, size: 16),
          label: const Text('Revenue'),
        ),
        ElevatedButton.icon(
          style: style,
          onPressed: () =>
              _navTo(TaxManagementScreen(
                initialYear: _selectedYear,
                initialFilterMode: _filterMode,
                initialStartDate: _startDate,
                initialEndDate: _endDate,
              )),
          icon: const Icon(Icons.account_balance, size: 16),
          label: const Text('Pajak'),
        ),
        ElevatedButton.icon(
          style: style,
          onPressed: () =>
              _navTo(DividendManagementScreen(
                initialYear: _selectedYear,
                initialFilterMode: _filterMode,
              )),
          icon: const Icon(Icons.wallet, size: 16),
          label: const Text('Dividen'),
        ),
        ElevatedButton.icon(
          style: style,
          onPressed: () =>
              _navTo(BalanceSheetSettingsScreen(
                initialYear: _selectedYear,
                initialFilterMode: _filterMode,
              )),
          icon: const Icon(Icons.assessment, size: 16),
          label: const Text('Neraca'),
        ),
      ],
    );
  }

  void _navTo(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    _fetchReport();
  }
}

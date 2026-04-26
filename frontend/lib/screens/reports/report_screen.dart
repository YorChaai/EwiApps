import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/settlement_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/file_helper.dart';
import '../../widgets/app_scrollbar.dart';
import 'annual_report_screen.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _tableVerticalController = ScrollController();
  int _selectedYear = 2024;
  DateTime? _startDate;
  DateTime? _endDate;
  Map<String, dynamic>? _summary;
  bool _loading = false;
  final _currencyFormat = NumberFormat('#,##0', 'id_ID');
  final _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agt',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
  Color _cardColor(BuildContext context) =>
      _isDark(context) ? AppTheme.card : AppTheme.lightCard;
  Color _surfaceColor(BuildContext context) =>
      _isDark(context) ? AppTheme.surface : AppTheme.lightSurface;
  Color _dividerColor(BuildContext context) =>
      _isDark(context) ? AppTheme.divider : AppTheme.lightDivider;
  Color _titleColor(BuildContext context) =>
      _isDark(context) ? AppTheme.cream : AppTheme.lightTextPrimary;
  Color _bodyColor(BuildContext context) =>
      _isDark(context) ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
  Color _primaryText(BuildContext context) =>
      _isDark(context) ? AppTheme.textPrimary : AppTheme.lightTextPrimary;

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    _tableVerticalController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadDefaultYearAndSummary();
  }

  Future<void> _loadDefaultYearAndSummary() async {
    setState(() => _loading = true);
    try {
      final prov = context.read<SettlementProvider>();
      await prov.syncReportYear();
      if (mounted) setState(() => _selectedYear = prov.reportYear);
    } catch (_) {}
    await _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() => _loading = true);
    try {
      final prov = context.read<SettlementProvider>();
      final data = await prov.getSummary(
        year: _selectedYear,
        startDate: _startDate != null
            ? DateFormat('yyyy-MM-dd').format(_startDate!)
            : null,
        endDate: _endDate != null
            ? DateFormat('yyyy-MM-dd').format(_endDate!)
            : null,
      );
      setState(() => _summary = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
    setState(() => _loading = false);
  }

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: (_startDate != null && _endDate != null)
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );
    if (range != null) {
      setState(() {
        _startDate = range.start;
        _endDate = range.end;
      });
      _loadSummary();
    }
  }

  void _clearDateRange() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _loadSummary();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final useCompact = screenWidth < 550;
    final isNarrow = screenWidth < 800;

    if (_loading) {
      return Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }
    if (_summary == null) {
      return Center(
        child: Text(
          'Tidak ada data',
          style: TextStyle(color: _bodyColor(context)),
        ),
      );
    }

    return AppScrollbar(
      controller: _verticalController,
      thumbVisibility: true,
      interactive: true,
      child: SingleChildScrollView(
        controller: _verticalController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                useCompact ? 16 : 32,
                useCompact ? 20 : 28,
                useCompact ? 16 : 32,
                20,
              ),
              child: isNarrow
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderInfo(useCompact),
                        SizedBox(height: useCompact ? 12 : 16),
                        _buildActions(useCompact),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(flex: 1, child: _buildHeaderInfo(useCompact)),
                        const SizedBox(width: 16),
                        Expanded(flex: 2, child: _buildActions(useCompact)),
                      ],
                    ),
            ),
            const Divider(height: 1),
            Padding(
              padding: EdgeInsets.fromLTRB(
                useCompact ? 12 : 16,
                useCompact ? 12 : 16,
                useCompact ? 12 : 16,
                64,
              ),
              child: _buildSummaryTableScrollableBody(useCompact),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfo(bool useCompact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Laporan Summary',
          style: TextStyle(
            fontSize: useCompact ? 18 : 24,
            fontWeight: FontWeight.w700,
            color: _titleColor(context),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Per kategori per bulan',
          style: TextStyle(
            color: _bodyColor(context),
            fontSize: useCompact ? 11 : 14,
          ),
        ),
        if (_startDate != null && _endDate != null) ...[
          const SizedBox(height: 4),
          Text(
            '${DateFormat('dd MMM yyyy').format(_startDate!)} - ${DateFormat('dd MMM yyyy').format(_endDate!)}',
            style: TextStyle(
              color: AppTheme.accent,
              fontSize: useCompact ? 11 : 13,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActions(bool useCompact) {
    final buttons = [
      DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedYear,
          dropdownColor: _cardColor(context),
          style: TextStyle(
            color: _primaryText(context),
            fontSize: useCompact ? 12 : 13,
            fontWeight: FontWeight.bold,
          ),
          items: {...List.generate(21, (i) => 2020 + i), _selectedYear}
              .where((y) => y != 0)
              .map((y) => DropdownMenuItem(
                    value: y,
                    child: Text('Laporan $y'),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) {
              setState(() => _selectedYear = v);
              _loadSummary();
            }
          },
        ),
      ),
      TextButton.icon(
        onPressed: _pickDateRange,
        icon: Icon(Icons.date_range_rounded, size: 18, color: AppTheme.primary),
        label: Text(
          'Range',
          style: TextStyle(
            color: AppTheme.primary,
            fontSize: useCompact ? 12 : 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: useCompact ? 4 : 8),
        ),
      ),
      if (_startDate != null)
        IconButton(
          onPressed: _clearDateRange,
          tooltip: 'Clear Range',
          icon: Icon(
            Icons.close_rounded,
            color: AppTheme.danger,
            size: 20,
          ),
        ),
      TextButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AnnualReportScreen()),
        ),
        icon: Icon(Icons.assessment_rounded, size: 18, color: AppTheme.primary),
        label: Text(
          'Laporan Tahunan',
          style: TextStyle(
            color: AppTheme.primary,
            fontSize: useCompact ? 12 : 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: useCompact ? 4 : 8),
        ),
      ),
      IconButton(
        onPressed: _exportSummaryPdf,
        tooltip: 'Export PDF',
        icon: Icon(
          Icons.picture_as_pdf_rounded,
          color: AppTheme.danger,
          size: 22,
        ),
      ),
      IconButton(
        onPressed: _exportFullExcel,
        tooltip: 'Export Excel',
        icon: Icon(
          Icons.table_view_rounded,
          color: AppTheme.success,
          size: 22,
        ),
      ),
    ];

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      alignment: useCompact ? WrapAlignment.start : WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: buttons,
    );
  }

  Widget _buildSummaryCell({
    required String value,
    required double width,
    required bool isBold,
    TextAlign align = TextAlign.right,
    Color? color,
    double fontSize = 12,
  }) {
    return Container(
      width: width,
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: align == TextAlign.right
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Text(
        value,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color:
              color ?? (isBold ? _titleColor(context) : _primaryText(context)),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildSummaryTableScrollableBody(bool useCompact) {
    final summaryList = List<Map<String, dynamic>>.from(
      _summary!['summary'] ?? [],
    );
    final grandTotal = (_summary!['grand_total'] ?? 0).toDouble();

    const double leftScrollbarSpace = 14;
    final double colKategori = 180;
    final double colMonth = 110;
    final double colTotal = 140;
    final double totalWidth = colKategori + (colMonth * 12) + colTotal;
    final double rowHeight = 48.0;
    final double bodyHeight = math
        .min((summaryList.length + 1) * rowHeight, useCompact ? 650.0 : 800.0)
        .toDouble();

    return Card(
      color: _cardColor(context),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _dividerColor(context)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: useCompact ? 6 : 10,
          vertical: useCompact ? 8 : 12,
        ),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            border: Border.all(color: _dividerColor(context)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: AppScrollbar(
            controller: _tableVerticalController,
            thumbVisibility: true,
            interactive: true,
            scrollbarOrientation: ScrollbarOrientation.left,
            notificationPredicate: (notification) =>
                notification.metrics.axis == Axis.vertical,
            child: Padding(
              padding: const EdgeInsets.only(left: leftScrollbarSpace),
              child: AppScrollbar(
                controller: _horizontalController,
                thumbVisibility: true,
                interactive: true,
                scrollDirection: Axis.horizontal,
                notificationPredicate: (notification) =>
                    notification.metrics.axis == Axis.horizontal,
                child: SingleChildScrollView(
                  controller: _horizontalController,
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  child: SizedBox(
                    width: totalWidth + 10,
                    child: Column(
                      children: [
                        // Header Table
                        Container(
                          color: _surfaceColor(context),
                          height: 48,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildSummaryCell(
                                value: 'Kategori',
                                width: colKategori,
                                isBold: true,
                                align: TextAlign.left,
                                fontSize: 13,
                              ),
                              ..._months.map(
                                (m) => _buildSummaryCell(
                                  value: m,
                                  width: colMonth,
                                  isBold: true,
                                  fontSize: 13,
                                ),
                              ),
                              _buildSummaryCell(
                                value: 'TOTAL',
                                width: colTotal,
                                isBold: true,
                                color: AppTheme.accent,
                                fontSize: 13,
                              ),
                            ],
                          ),
                        ),
                        // Body Table
                        SizedBox(
                          height: bodyHeight + 4,
                          child: RepaintBoundary(
                            child: NotificationListener<ScrollNotification>(
                              onNotification: (notification) {
                                if (notification.metrics.axis ==
                                    Axis.vertical) {
                                  final m = notification.metrics;
                                  if (notification
                                          is ScrollUpdateNotification &&
                                      notification.scrollDelta != null) {
                                    final d = notification.scrollDelta!;
                                    if ((d > 0 &&
                                            m.pixels >= m.maxScrollExtent) ||
                                        (d < 0 && m.pixels <= 0)) {
                                      _verticalController.position.jumpTo(
                                        (_verticalController.offset + d).clamp(
                                          0,
                                          _verticalController
                                              .position
                                              .maxScrollExtent,
                                        ),
                                      );
                                    }
                                  } else if (notification
                                      is OverscrollNotification) {
                                    _verticalController.position.jumpTo(
                                      (_verticalController.offset +
                                              notification.overscroll)
                                          .clamp(
                                            0,
                                            _verticalController
                                                .position
                                                .maxScrollExtent,
                                          ),
                                    );
                                  }
                                }
                                return false;
                              },
                              child: ListView.builder(
                                controller: _tableVerticalController,
                                itemCount: summaryList.length + 1,
                                itemExtent: rowHeight,
                                cacheExtent: 1000,
                                padding: const EdgeInsets.fromLTRB(2, 0, 0, 4),
                                physics: const ClampingScrollPhysics(),
                                itemBuilder: (context, index) {
                                  if (index < summaryList.length) {
                                    final cat = summaryList[index];
                                    final monthly =
                                        cat['monthly'] as Map<String, dynamic>;
                                    final isParent = cat['is_parent'] ?? false;
                                    final level = (cat['level'] ?? 0) as int;

                                    return Container(
                                      decoration: BoxDecoration(
                                        color: index.isEven
                                            ? (_isDark(context)
                                                  ? const Color(0xFF1E293B)
                                                  : const Color(0xFFF1F5F9))
                                            : (_isDark(context)
                                                  ? const Color(0xFF0F172A)
                                                  : Colors.white),
                                        border: Border(
                                          bottom: BorderSide(
                                            color: _dividerColor(context),
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: colKategori,
                                            padding: EdgeInsets.only(
                                              left: 8.0 + (level * 12.0),
                                              right: 8.0,
                                            ),
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              cat['category'],
                                              style: TextStyle(
                                                fontWeight: isParent
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                                fontSize: isParent ? 13 : 12,
                                                color: isParent
                                                    ? _titleColor(context)
                                                    : _primaryText(context),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          for (int i = 1; i <= 12; i++)
                                            _buildSummaryCell(
                                              value: _currencyFormat.format(
                                                (monthly['$i'] ?? 0).toDouble(),
                                              ),
                                              width: colMonth,
                                              isBold: false,
                                              align: TextAlign.right,
                                            ),
                                          _buildSummaryCell(
                                            value: _currencyFormat.format(
                                              cat['yearly_total'] ?? 0,
                                            ),
                                            width: colTotal,
                                            isBold: true,
                                            color: AppTheme.accent,
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  return Container(
                                    decoration: BoxDecoration(
                                      color: _surfaceColor(context),
                                      border: Border(
                                        top: BorderSide(
                                          color: _dividerColor(context),
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _buildSummaryCell(
                                          value: 'GRAND TOTAL',
                                          width: colKategori,
                                          isBold: true,
                                          align: TextAlign.left,
                                        ),
                                        ...List.generate(12, (mIdx) {
                                          double monthTotal = 0;
                                          for (final cat in summaryList) {
                                            monthTotal +=
                                                ((cat['monthly']
                                                            as Map<
                                                              String,
                                                              dynamic
                                                            >)['${mIdx + 1}'] ??
                                                        0)
                                                    .toDouble();
                                          }
                                          return _buildSummaryCell(
                                            value: monthTotal > 0
                                                ? _currencyFormat.format(
                                                    monthTotal,
                                                  )
                                                : '-',
                                            width: colMonth,
                                            isBold: true,
                                          );
                                        }),
                                        _buildSummaryCell(
                                          value:
                                              'Rp ${_currencyFormat.format(grandTotal)}',
                                          width: colTotal,
                                          isBold: true,
                                          color: AppTheme.accent,
                                        ),
                                      ],
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
      ),
    );
  }

  Future<void> _exportFullExcel() async {
    try {
      final prov = context.read<SettlementProvider>();
      final start = _startDate ?? DateTime(_selectedYear, 1, 1);
      final end = _endDate ?? DateTime(_selectedYear, 12, 31);
      final bytes = await prov.exportExcel(
        startDate: DateFormat('yyyy-MM-dd').format(start),
        endDate: DateFormat('yyyy-MM-dd').format(end),
      );
      final filename =
          'summary_${DateFormat('yyyyMMdd').format(start)}_${DateFormat('yyyyMMdd').format(end)}.xlsx';
      if (mounted) {
        await FileHelper.saveAndOpenFolder(
          context: context,
          bytes: bytes,
          filename: filename,
          successMessage: 'Excel Summary berhasil disimpan.',
          subFolder: 'Reports/Summary/Excel',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal export: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  Future<void> _exportSummaryPdf() async {
    try {
      final prov = context.read<SettlementProvider>();
      final bytes = await prov.getSummaryPdf(
        year: _selectedYear,
        startDate: _startDate != null
            ? DateFormat('yyyy-MM-dd').format(_startDate!)
            : null,
        endDate: _endDate != null
            ? DateFormat('yyyy-MM-dd').format(_endDate!)
            : null,
      );
      final suffix = (_startDate != null && _endDate != null)
          ? '${DateFormat('yyyyMMdd').format(_startDate!)}_${DateFormat('yyyyMMdd').format(_endDate!)}'
          : '$_selectedYear';
      final filename = 'summary_$suffix.pdf';
      if (mounted) {
        await FileHelper.saveAndOpenFile(
          context: context,
          bytes: bytes,
          filename: filename,
          successMessage: 'PDF Summary berhasil disimpan.',
          subFolder: 'Reports/Summary/PDF',
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
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/settlement_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/file_helper.dart';
import 'annual_report_screen.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();
  int _selectedYear = 2024;
  DateTime? _startDate;
  DateTime? _endDate;
  Map<String, dynamic>? _summary;
  bool _loading = false;
  final _currencyFormat = NumberFormat('#,##0', 'id_ID');
  final _months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];

  bool _isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;
  Color _cardColor(BuildContext context) => _isDark(context) ? AppTheme.card : AppTheme.lightCard;
  Color _surfaceColor(BuildContext context) => _isDark(context) ? AppTheme.surface : AppTheme.lightSurface;
  Color _dividerColor(BuildContext context) => _isDark(context) ? AppTheme.divider : AppTheme.lightDivider;
  Color _titleColor(BuildContext context) => _isDark(context) ? AppTheme.cream : AppTheme.lightTextPrimary;
  Color _bodyColor(BuildContext context) => _isDark(context) ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
  Color _primaryText(BuildContext context) => _isDark(context) ? AppTheme.textPrimary : AppTheme.lightTextPrimary;

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
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
        startDate: _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : null,
        endDate: _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null,
      );
      setState(() => _summary = data);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger));
    }
    setState(() => _loading = false);
  }

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2035), initialDateRange: (_startDate != null && _endDate != null) ? DateTimeRange(start: _startDate!, end: _endDate!) : null);
    if (range != null) { setState(() { _startDate = range.start; _endDate = range.end; }); _loadSummary(); }
  }

  void _clearDateRange() { setState(() { _startDate = null; _endDate = null; }); _loadSummary(); }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final useCompact = screenWidth < 550;
    final isNarrow = screenWidth < 800;

    if (_loading) return Center(child: CircularProgressIndicator(color: AppTheme.primary));
    if (_summary == null) return Center(child: Text('Tidak ada data', style: TextStyle(color: _bodyColor(context))));

    return Scrollbar(
      controller: _verticalController,
      thumbVisibility: true,
      thickness: 8,
      child: SingleChildScrollView(
        controller: _verticalController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(useCompact ? 16 : 32, useCompact ? 20 : 28, useCompact ? 16 : 32, 20),
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
              padding: EdgeInsets.fromLTRB(useCompact ? 12 : 24, useCompact ? 12 : 24, useCompact ? 12 : 24, 48),
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
          style: TextStyle(color: _bodyColor(context), fontSize: useCompact ? 11 : 14),
        ),
        if (_startDate != null && _endDate != null) ...[
          const SizedBox(height: 4),
          Text(
            '${DateFormat('dd MMM yyyy').format(_startDate!)} - ${DateFormat('dd MMM yyyy').format(_endDate!)}',
            style: TextStyle(color: AppTheme.accent, fontSize: useCompact ? 11 : 13),
          ),
        ],
      ],
    );
  }

  Widget _buildActions(bool useCompact) {
    final buttons = [
      Container(
        height: useCompact ? 36 : 40,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: _cardColor(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _dividerColor(context)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: _selectedYear,
            dropdownColor: _cardColor(context),
            style: TextStyle(color: _primaryText(context), fontSize: useCompact ? 12 : 14),
            items: { ...List.generate(21, (i) => 2020 + i), _selectedYear }.where((y) => y != 0).map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
            onChanged: (v) { if (v != null) { setState(() => _selectedYear = v); _loadSummary(); } },
          ),
        ),
      ),
      _actionButton(
        onPressed: _pickDateRange,
        icon: Icons.date_range_rounded,
        label: 'Range',
        useCompact: useCompact,
        isOutlined: true,
      ),
      if (_startDate != null)
        IconButton(onPressed: _clearDateRange, tooltip: 'Clear Range', icon: Icon(Icons.close_rounded, color: AppTheme.danger, size: useCompact ? 20 : 24)),
      _actionButton(
        onPressed: _exportSummaryPdf,
        icon: Icons.picture_as_pdf_rounded,
        label: 'PDF',
        useCompact: useCompact,
      ),
      _actionButton(
        onPressed: _exportFullExcel,
        icon: Icons.download_rounded,
        label: 'Excel',
        useCompact: useCompact,
      ),
      _actionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AnnualReportScreen())),
        icon: Icons.assessment_rounded,
        label: 'Tahunan',
        useCompact: useCompact,
      ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: useCompact ? WrapAlignment.start : WrapAlignment.end,
      children: buttons,
    );
  }

  Widget _actionButton({required VoidCallback onPressed, required IconData icon, required String label, required bool useCompact, bool isOutlined = false}) {
    final style = ElevatedButton.styleFrom(
      padding: EdgeInsets.symmetric(horizontal: useCompact ? 10 : 16, vertical: 0),
      minimumSize: Size(0, useCompact ? 36 : 42),
      textStyle: TextStyle(fontSize: useCompact ? 12 : 14, fontWeight: FontWeight.w600),
    );

    if (isOutlined) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: useCompact ? 16 : 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: useCompact ? 10 : 16, vertical: 0),
          minimumSize: Size(0, useCompact ? 36 : 42),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: useCompact ? 16 : 18),
      label: Text(label),
      style: style,
    );
  }

  Widget _buildSummaryTableScrollableBody(bool useCompact) {
    final summaryList = List<Map<String, dynamic>>.from(_summary!['summary'] ?? []);
    final grandTotal = (_summary!['grand_total'] ?? 0).toDouble();

    return Scrollbar(
      controller: _horizontalController,
      thumbVisibility: true,
      thickness: 8,
      child: SingleChildScrollView(
        controller: _horizontalController,
        scrollDirection: Axis.horizontal,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: _cardColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _dividerColor(context)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: DataTable(
                  headingRowColor: WidgetStateProperty.all(_surfaceColor(context)),
                  columnSpacing: useCompact ? 12 : 20,
                  horizontalMargin: useCompact ? 12 : 16,
                  headingRowHeight: useCompact ? 40 : 56,
                  dataRowMinHeight: useCompact ? 32 : 48,
                  dataRowMaxHeight: useCompact ? 48 : 56,
                  columns: [
                    DataColumn(label: Text('Kategori', style: TextStyle(fontWeight: FontWeight.w600, color: _titleColor(context), fontSize: useCompact ? 12 : 14))),
                    ..._months.map((m) => DataColumn(label: Text(m, style: TextStyle(fontWeight: FontWeight.w600, color: _titleColor(context), fontSize: useCompact ? 11 : 13)), numeric: true)),
                    DataColumn(label: Text('TOTAL', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.accent, fontSize: useCompact ? 12 : 14)), numeric: true),
                  ],
                  rows: [
                    ...summaryList.map((cat) {
                      final monthly = cat['monthly'] as Map<String, dynamic>;
                      final isParent = cat['is_parent'] ?? false;
                      return DataRow(
                        cells: [
                          DataCell(
                            SizedBox(
                              width: useCompact ? 120 : 180,
                              child: Padding(
                                padding: EdgeInsets.only(left: (cat['level'] ?? 0) * 12.0),
                                child: Text(
                                  cat['category'],
                                  style: TextStyle(
                                    fontWeight: isParent ? FontWeight.w700 : FontWeight.w500,
                                    fontSize: useCompact ? (isParent ? 12 : 11) : (isParent ? 14 : 13),
                                    color: isParent ? _titleColor(context) : _primaryText(context),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                          ...List.generate(12, (i) {
                            final val = (monthly['${i + 1}'] ?? 0).toDouble();
                            return DataCell(Text(val > 0 ? _currencyFormat.format(val) : '-', style: TextStyle(color: val > 0 ? _primaryText(context) : _bodyColor(context), fontSize: useCompact ? 10 : 12)));
                          }),
                          DataCell(Text(_currencyFormat.format(cat['yearly_total'] ?? 0), style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.accent, fontSize: useCompact ? 11 : 13))),
                        ],
                      );
                    }),
                    DataRow(
                      color: WidgetStateProperty.all(AppTheme.primary.withValues(alpha: 0.08)),
                      cells: [
                        DataCell(Text('GRAND TOTAL', style: TextStyle(fontWeight: FontWeight.w700, color: _titleColor(context), fontSize: useCompact ? 11 : 13))),
                        ...List.generate(12, (i) {
                          double monthTotal = 0;
                          for (final cat in summaryList) {
                            monthTotal += ((cat['monthly'] as Map<String, dynamic>)['${i + 1}'] ?? 0).toDouble();
                          }
                          return DataCell(Text(monthTotal > 0 ? _currencyFormat.format(monthTotal) : '-', style: TextStyle(fontWeight: FontWeight.w600, fontSize: useCompact ? 10 : 12)));
                        }),
                        DataCell(Text('Rp ${_currencyFormat.format(grandTotal)}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: useCompact ? 12 : 14, color: AppTheme.accent))),
                      ],
                    ),
                  ],
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
      final bytes = await prov.exportExcel(startDate: DateFormat('yyyy-MM-dd').format(start), endDate: DateFormat('yyyy-MM-dd').format(end));
      final filename = 'summary_${DateFormat('yyyyMMdd').format(start)}_${DateFormat('yyyyMMdd').format(end)}.xlsx';
      if (mounted) await FileHelper.saveAndOpenFolder(context: context, bytes: bytes, filename: filename, successMessage: 'Excel Summary berhasil disimpan.');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal export: $e'), backgroundColor: AppTheme.danger));
    }
  }

  Future<void> _exportSummaryPdf() async {
    try {
      final prov = context.read<SettlementProvider>();
      final bytes = await prov.getSummaryPdf(year: _selectedYear, startDate: _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : null, endDate: _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null);
      final suffix = (_startDate != null && _endDate != null) ? '${DateFormat('yyyyMMdd').format(_startDate!)}_${DateFormat('yyyyMMdd').format(_endDate!)}' : '$_selectedYear';
      final filename = 'summary_$suffix.pdf';
      if (mounted) await FileHelper.saveAndOpenFile(context: context, bytes: bytes, filename: filename, successMessage: 'PDF Summary berhasil disimpan.');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal export PDF: $e'), backgroundColor: AppTheme.danger));
    }
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/tax_provider.dart';
import '../../theme/app_theme.dart';

class TaxManagementScreen extends StatefulWidget {
  final int? initialYear;

  const TaxManagementScreen({super.key, this.initialYear});

  @override
  State<TaxManagementScreen> createState() => _TaxManagementScreenState();
}

class _TaxManagementScreenState extends State<TaxManagementScreen> {
  late int _selectedYear;
  final _dateFmt = DateFormat('yyyy-MM-dd');
  final _displayFmt = DateFormat('dd-MMM-yy');
  final Set<int> _selectedTaxIds = <int>{};

  // Helper untuk theme-aware colors
  bool _isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;
  Color _cardColor(BuildContext context) => _isDark(context) ? AppTheme.card : AppTheme.lightCard;
  Color _surfaceColor(BuildContext context) => _isDark(context) ? AppTheme.surface : AppTheme.lightSurface;
  Color _textColor(BuildContext context) => _isDark(context) ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
  Color _secondaryTextColor(BuildContext context) => _isDark(context) ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
  Color _creamColor(BuildContext context) => _isDark(context) ? AppTheme.cream : AppTheme.lightTextPrimary;

  String _displayDate(dynamic value) {
    final text = (value ?? '').toString();
    if (text.isEmpty) return '';
    try {
      final dt = DateTime.tryParse(text);
      if (dt == null) return text;
      return _displayFmt.format(dt);
    } catch (_) {
      return text;
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear ?? DateTime.now().year;
    Future.microtask(_loadData);
  }

  String get _startDate => '$_selectedYear-01-01';
  String get _endDate => '$_selectedYear-12-31';

  Future<void> _loadData() async {
    final provider = context.read<TaxProvider>();
    await provider.fetchTaxes(
      startDate: _startDate,
      endDate: _endDate,
    );
    await provider.fetchTaxCombineGroups(year: _selectedYear);
  }

  /// Parse Indonesian numeric format: "1.500.000,50" → 1500000.50
  double? _toDouble(String value) {
    final cleaned = value.trim().replaceAll(' ', '');
    if (cleaned.isEmpty) return null;

    // Cek format Indonesia: titik sebagai ribuan, koma sebagai desimal
    // Contoh: "1.500.000,50" atau "1500000" atau "1,50"
    if (cleaned.contains(',')) {
      // Format Indonesia: hapus titik (ribuan), ganti koma dengan titik (desimal)
      final fixed = cleaned.replaceAll('.', '').replaceAll(',', '.');
      return double.tryParse(fixed);
    }

    // Format standard: hapus semua separator
    final parsed = double.tryParse(cleaned);
    if (parsed != null) return parsed;

    // Fallback: coba hapus titik dan parse ulang
    return double.tryParse(cleaned.replaceAll('.', ''));
  }

  /// Format numeric value to Indonesian format: 1500000.50 → "1.500.000,50"
  String _formatNumericInput(dynamic value) {
    if (value == null) return '';
    final num = value is double ? value : double.tryParse('$value');
    if (num == null) return '$value';

    // Pisahkan integer dan desimal
    final integerPart = num.truncate().abs();
    final decimalPart = num - num.truncate();

    // Format integer dengan pemisah ribuan
    final formattedInteger = integerPart
        .toString()
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]}.',
        );

    // Tambahkan tanda minus jika negatif
    final sign = num < 0 ? '-' : '';

    if (decimalPart > 0) {
      final decimalStr = decimalPart.toStringAsFixed(2).substring(1);
      return '$sign$formattedInteger,$decimalStr';
    }

    return '$sign$formattedInteger';
  }

  Future<void> _saveTax({
    required Map<String, dynamic> payload,
    int? id,
  }) async {
    final prov = context.read<TaxProvider>();
    if (id == null) {
      await prov.createTax(payload, startDate: _startDate, endDate: _endDate);
    } else {
      await prov.updateTax(
        id,
        payload,
        startDate: _startDate,
        endDate: _endDate,
      );
    }
  }

  Future<void> _showTaxDialog([Map<String, dynamic>? data]) async {
    final formKey = GlobalKey<FormState>();
    final now = DateTime.now();
    final defaultDate = _selectedYear == 0 || _selectedYear == now.year ? now : DateTime(_selectedYear, 12, 31);
    final date = TextEditingController(
      text:
          data?['date']?.toString().substring(0, 10) ??
          _dateFmt.format(defaultDate),
    );
    final description = TextEditingController(text: data?['description'] ?? '');
    final transactionValue = TextEditingController(
      text: _formatNumericInput(data?['transaction_value']),
    );
    final currency = TextEditingController(text: data?['currency'] ?? 'IDR');
    final currencyExchange = TextEditingController(
      text: _formatNumericInput(data?['currency_exchange']),
    );
    final ppn = TextEditingController(text: _formatNumericInput(data?['ppn']));
    final pph21 = TextEditingController(
      text: _formatNumericInput(data?['pph_21']),
    );
    final pph23 = TextEditingController(
      text: _formatNumericInput(data?['pph_23']),
    );
    final pph26 = TextEditingController(
      text: _formatNumericInput(data?['pph_26']),
    );

    Future<void> pickDate(TextEditingController ctrl) async {
      final init =
          DateTime.tryParse(ctrl.text) ?? DateTime(_selectedYear, 1, 1);
      final picked = await showDatePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime(2035),
        initialDate: init,
      );
      if (picked != null) {
        ctrl.text = _dateFmt.format(picked);
      }
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardColor(ctx),
        title: Text(
          data == null ? 'Tambah Pajak' : 'Edit Pajak',
          style: TextStyle(color: _creamColor(ctx)),
        ),
        content: SizedBox(
          width: 760,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _dateField(date, 'Date', pickDate),
                  _textField(
                    description,
                    'Detail/Description',
                    width: 720,
                    required: true,
                  ),
                  _numberField(
                    transactionValue,
                    'Transaction Value',
                    required: true,
                  ),
                  _textField(currency, 'Currency'),
                  _numberField(currencyExchange, 'Currency Exchange'),
                  _numberField(ppn, 'PPN'),
                  _numberField(pph21, 'PPh (pasal 21)'),
                  _numberField(pph23, 'PPh (pasal 23)'),
                  _numberField(pph26, 'PPh (pasal 26)'),
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
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final payload = <String, dynamic>{
                'date': date.text.trim(),
                'description': description.text.trim(),
                'transaction_value': _toDouble(transactionValue.text),
                'currency': currency.text.trim().isEmpty
                    ? 'IDR'
                    : currency.text.trim(),
                'currency_exchange': _toDouble(currencyExchange.text),
                'ppn': _toDouble(ppn.text),
                'pph_21': _toDouble(pph21.text),
                'pph_23': _toDouble(pph23.text),
                'pph_26': _toDouble(pph26.text),
              };
              try {
                await _saveTax(payload: payload, id: data?['id'] as int?);
                if (!mounted) return;
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      data == null ? 'Pajak ditambahkan' : 'Pajak diupdate',
                    ),
                    backgroundColor: AppTheme.success,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal simpan: $e'),
                    backgroundColor: AppTheme.danger,
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

  Future<void> _deleteTax(Map<String, dynamic> item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardColor(ctx),
        title: Text('Hapus Pajak?', style: TextStyle(color: _creamColor(ctx))),
        content: Text(
          item['description'] ?? '-',
          style: TextStyle(color: _secondaryTextColor(ctx)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!mounted) return;

    try {
      await context.read<TaxProvider>().deleteTax(
        item['id'] as int,
        startDate: _startDate,
        endDate: _endDate,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pajak dihapus'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal hapus: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  int _itemId(Map<String, dynamic> item) {
    return int.tryParse('${item['id'] ?? 0}') ?? 0;
  }

  Map<int, Map<String, dynamic>> _groupByRowId(List<dynamic> groups) {
    final map = <int, Map<String, dynamic>>{};
    for (final raw in groups) {
      final group = Map<String, dynamic>.from(raw as Map);
      final rowIds = (group['row_ids'] as List?) ?? const [];
      for (final rowId in rowIds) {
        final parsed = int.tryParse('$rowId');
        if (parsed != null) {
          map[parsed] = group;
        }
      }
    }
    return map;
  }

  int? _selectedCombineGroupId(Map<int, Map<String, dynamic>> groupByRowId) {
    if (_selectedTaxIds.isEmpty) return null;
    final ids = _selectedTaxIds
        .map((rowId) => groupByRowId[rowId]?['id'])
        .where((value) => value != null)
        .map((value) => int.tryParse('$value'))
        .whereType<int>()
        .toSet();
    if (ids.length != 1) return null;
    return ids.first;
  }

  Future<void> _combineSelectedTaxes() async {
    if (_selectedTaxIds.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pilih minimal 2 data pajak.'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    try {
      await context.read<TaxProvider>().createTaxCombineGroup(
        year: _selectedYear,
        rowIds: _selectedTaxIds.toList()..sort(),
      );
      if (!mounted) return;
      setState(() => _selectedTaxIds.clear());
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Combine pajak disimpan.'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal combine pajak: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  Future<void> _releaseSelectedTaxCombine(
    Map<int, Map<String, dynamic>> groupByRowId,
  ) async {
    final groupId = _selectedCombineGroupId(groupByRowId);
    if (groupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Pilih data yang berada dalam satu group combine yang sama.',
          ),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    try {
      await context.read<TaxProvider>().deleteTaxCombineGroup(
        id: groupId,
        year: _selectedYear,
      );
      if (!mounted) return;
      setState(() => _selectedTaxIds.clear());
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Combine pajak dilepas.'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal melepas combine pajak: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    double width = 230,
    bool required = false,
  }) {
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null
            : null,
      ),
    );
  }

  Widget _numberField(
    TextEditingController controller,
    String label, {
    bool required = false,
  }) {
    return SizedBox(
      width: 230,
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label),
        validator: (v) {
          if (!required && (v == null || v.trim().isEmpty)) return null;
          return _toDouble(v ?? '') == null ? 'Angka tidak valid' : null;
        },
      ),
    );
  }

  Widget _dateField(
    TextEditingController controller,
    String label,
    Future<void> Function(TextEditingController) pickDate,
  ) {
    return SizedBox(
      width: 230,
      child: TextFormField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: IconButton(
            icon: const Icon(Icons.date_range_rounded),
            onPressed: () => pickDate(controller),
          ),
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Wajib diisi';
          return DateTime.tryParse(v.trim()) == null
              ? 'Tanggal tidak valid'
              : null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<TaxProvider>();
    final items = prov.taxes;
    final groupByRowId = _groupByRowId(prov.combineGroups);

    return Scaffold(
      backgroundColor: _surfaceColor(context),
      appBar: AppBar(
        title: Text('Input Pajak Pengeluaran'),
        backgroundColor: _cardColor(context),
        actions: [
          DropdownButton<int>(
            value: _selectedYear,
            dropdownColor: _cardColor(context),
            style: TextStyle(color: _textColor(context)),
            items: {
              ...List.generate(21, (i) => 2020 + i),
              _selectedYear
            }.where((y) => y != 0).map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
            onChanged: (v) async {
              if (v == null) return;
              setState(() {
                _selectedYear = v;
                _selectedTaxIds.clear();
              });
              await _loadData();
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTaxDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: prov.isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        OutlinedButton.icon(
                          onPressed: prov.isLoading ? null : _combineSelectedTaxes,
                          icon: const Icon(Icons.merge_type_rounded),
                          label: Text(
                            'Combine Manual (${_selectedTaxIds.length})',
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: prov.isLoading
                              ? null
                              : () => _releaseSelectedTaxCombine(groupByRowId),
                          icon: const Icon(Icons.call_split_rounded),
                          label: const Text('Lepas Combine'),
                        ),
                        TextButton(
                          onPressed: _selectedTaxIds.isEmpty
                              ? null
                              : () => setState(() => _selectedTaxIds.clear()),
                          child: const Text('Clear Pilihan'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manual combine default-nya kosong. Pilih baris berurutan dengan tanggal yang sama persis, lalu tekan Combine Manual.',
                      style: TextStyle(color: _secondaryTextColor(context)),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(_cardColor(context)),
                        dataRowColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return _isDark(context) ? AppTheme.cardHover : AppTheme.lightCardHover;
                          }
                          return _cardColor(context);
                        }),
                        columns: const [
                          DataColumn(label: Text('Pilih')),
                          DataColumn(label: Text('Group')),
                          DataColumn(label: Text('Date')),
                          DataColumn(label: Text('#')),
                          DataColumn(label: Text('Description')),
                          DataColumn(label: Text('Trans Value')),
                          DataColumn(label: Text('Curr')),
                          DataColumn(label: Text('Rate')),
                          DataColumn(label: Text('DPP PPN')),
                          DataColumn(label: Text('PPN')),
                          DataColumn(label: Text('DPP PPh21')),
                          DataColumn(label: Text('PPh21')),
                          DataColumn(label: Text('DPP PPh23')),
                          DataColumn(label: Text('PPh23')),
                          DataColumn(label: Text('DPP PPh26')),
                          DataColumn(label: Text('PPh26')),
                          DataColumn(label: Text('Aksi')),
                        ],
                        rows: items.asMap().entries.map<DataRow>((entry) {
                          final idx = entry.key;
                          final e = Map<String, dynamic>.from(
                            entry.value as Map,
                          );
                          final rowId = _itemId(e);
                          final val =
                              double.tryParse(
                                e['transaction_value']?.toString() ?? '0',
                              ) ??
                              0;
                          final group = groupByRowId[rowId];
                          final isSelected = _selectedTaxIds.contains(rowId);
                          return DataRow(
                            selected: isSelected,
                            onSelectChanged: rowId <= 0
                                ? null
                                : (value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedTaxIds.add(rowId);
                                      } else {
                                        _selectedTaxIds.remove(rowId);
                                      }
                                    });
                                  },
                            cells: [
                              DataCell(
                                Checkbox(
                                  value: isSelected,
                                  onChanged: rowId <= 0
                                      ? null
                                      : (value) {
                                          setState(() {
                                            if (value == true) {
                                              _selectedTaxIds.add(rowId);
                                            } else {
                                              _selectedTaxIds.remove(rowId);
                                            }
                                          });
                                        },
                                ),
                              ),
                              DataCell(
                                Text(group == null ? '-' : 'C${group['id']}'),
                              ),
                              DataCell(Text(_displayDate(e['date']))),
                              DataCell(Text('${idx + 1}')),
                              DataCell(
                                SizedBox(
                                  width: 300,
                                  child: Text(
                                    e['description'] ?? '-',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              DataCell(Text('$val')),
                              DataCell(Text('${e['currency'] ?? 'IDR'}')),
                              DataCell(Text('${e['currency_exchange'] ?? 1}')),
                              DataCell(
                                Text(
                                  (double.tryParse(e['ppn']?.toString() ?? '0') ??
                                              0) >
                                          0
                                      ? '$val'
                                      : '0',
                                ),
                              ),
                              DataCell(Text('${e['ppn'] ?? 0}')),
                              DataCell(
                                Text(
                                  (double.tryParse(
                                                e['pph_21']?.toString() ??
                                                    e['pph_2_1']?.toString() ??
                                                    '0',
                                              ) ??
                                              0) >
                                          0
                                      ? '$val'
                                      : '0',
                                ),
                              ),
                              DataCell(Text('${e['pph_2_1'] ?? e['pph_21'] ?? 0}')),
                              DataCell(
                                Text(
                                  (double.tryParse(
                                                e['pph_23']?.toString() ?? '0',
                                              ) ??
                                              0) >
                                          0
                                      ? '$val'
                                      : '0',
                                ),
                              ),
                              DataCell(Text('${e['pph_23'] ?? 0}')),
                              DataCell(
                                Text(
                                  (double.tryParse(
                                                e['pph_26']?.toString() ?? '0',
                                              ) ??
                                              0) >
                                          0
                                      ? '$val'
                                      : '0',
                                ),
                              ),
                              DataCell(Text('${e['pph_26'] ?? 0}')),
                              DataCell(
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () => _showTaxDialog(e),
                                      icon: Icon(
                                        Icons.edit,
                                        color: AppTheme.accent,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _deleteTax(e),
                                      icon: Icon(
                                        Icons.delete_outline,
                                        color: AppTheme.danger,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 100), // Padding extra agar tidak tertabrak FAB
                  ],
                ),
              ),
            ),
    );
  }
}

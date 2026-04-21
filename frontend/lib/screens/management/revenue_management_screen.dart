import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/revenue_provider.dart';
import '../../theme/app_theme.dart';

class RevenueManagementScreen extends StatefulWidget {
  final int? initialYear;

  const RevenueManagementScreen({super.key, this.initialYear});

  @override
  State<RevenueManagementScreen> createState() =>
      _RevenueManagementScreenState();
}

class _RevenueManagementScreenState extends State<RevenueManagementScreen> {
  late int _selectedYear;
  final _dateFmt = DateFormat('yyyy-MM-dd');
  final _displayFmt = DateFormat('dd-MMM-yy');
  final _numberFmt = NumberFormat('#,##0', 'id_ID');
  final Set<int> _selectedRevenueIds = <int>{};

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
    final provider = context.read<RevenueProvider>();
    await provider.fetchRevenues(
      startDate: _startDate,
      endDate: _endDate,
    );
    await provider.fetchRevenueCombineGroups(year: _selectedYear);
  }

  Future<void> _saveRevenue({
    required Map<String, dynamic> payload,
    int? id,
  }) async {
    final prov = context.read<RevenueProvider>();
    if (id == null) {
      await prov.createRevenue(
        payload,
        startDate: _startDate,
        endDate: _endDate,
      );
    } else {
      await prov.updateRevenue(
        id,
        payload,
        startDate: _startDate,
        endDate: _endDate,
      );
    }
  }

  double? _toDouble(String value) {
    var cleaned = value.trim().replaceAll(' ', '');
    if (cleaned.isEmpty) return null;

    if (cleaned.contains('.') && cleaned.contains(',')) {
      if (cleaned.lastIndexOf(',') > cleaned.lastIndexOf('.')) {
        cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
      } else {
        cleaned = cleaned.replaceAll(',', '');
      }
    } else if (cleaned.contains(',')) {
      final commaCount = ','.allMatches(cleaned).length;
      if (commaCount == 1 && cleaned.split(',').last.length <= 2) {
        cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
      } else {
        cleaned = cleaned.replaceAll(',', '');
      }
    } else if ('.'.allMatches(cleaned).length > 1) {
      cleaned = cleaned.replaceAll('.', '');
    }

    return double.tryParse(cleaned);
  }

  String _formatNumericInput(dynamic value) {
    final number = value is num
        ? value.toDouble()
        : double.tryParse((value ?? '').toString());
    if (number == null || number == 0) return '';
    return _numberFmt.format(number);
  }

  Future<void> _showRevenueDialog([Map<String, dynamic>? data]) async {
    final formKey = GlobalKey<FormState>();
    final now = DateTime.now();
    final defaultDate = _selectedYear == 0 || _selectedYear == now.year ? now : DateTime(_selectedYear, 12, 31);
    final invoiceDate = TextEditingController(
      text:
          data?['invoice_date']?.toString().substring(0, 10) ??
          _dateFmt.format(defaultDate),
    );
    final description = TextEditingController(text: data?['description'] ?? '');
    final invoiceValue = TextEditingController(
      text: _formatNumericInput(data?['invoice_value']),
    );
    final currency = TextEditingController(text: data?['currency'] ?? 'IDR');
    final currencyExchange = TextEditingController(
      text: data?['currency_exchange']?.toString() ?? '',
    );
    final invoiceNumber = TextEditingController(
      text: data?['invoice_number'] ?? '',
    );
    final client = TextEditingController(text: data?['client'] ?? '');
    final receiveDate = TextEditingController(
      text: data?['receive_date']?.toString().substring(0, 10) ?? '',
    );
    final amountReceived = TextEditingController(
      text: _formatNumericInput(data?['amount_received']),
    );
    final ppn = TextEditingController(text: _formatNumericInput(data?['ppn']));
    final pph23 = TextEditingController(
      text: _formatNumericInput(data?['pph_23']),
    );
    final transferFee = TextEditingController(
      text: _formatNumericInput(data?['transfer_fee']),
    );
    final remark = TextEditingController(text: data?['remark'] ?? '');
    String revenueType = data?['revenue_type'] ?? 'pendapatan_langsung';

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
          data == null ? 'Tambah Revenue' : 'Edit Revenue',
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
                  _dateField(invoiceDate, 'Invoice Date', pickDate),
                  _textField(
                    description,
                    'Detail/Description',
                    width: 720,
                    required: true,
                  ),
                  _numberField(invoiceValue, 'Invoice Value', required: true),
                  _textField(currency, 'Currency'),
                  _numberField(currencyExchange, 'Currency Exchange'),
                  _textField(invoiceNumber, 'Invoice Number'),
                  _textField(client, 'Client'),
                  _dateField(
                    receiveDate,
                    'Receive Date',
                    pickDate,
                    allowEmpty: true,
                  ),
                  _numberField(amountReceived, 'Amount Received'),
                  _numberField(ppn, 'PPn'),
                  _numberField(pph23, 'PPh (Pasal 23)'),
                  _numberField(transferFee, 'Biaya transfer'),
                  _dropdownField(
                    revenueType,
                    'Revenue',
                    [
                      {'label': 'PENDAPATAN LANGSUNG', 'value': 'pendapatan_langsung'},
                      {'label': 'PENDAPATAN LAIN LAIN', 'value': 'pendapatan_lain_lain'},
                    ],
                    (v) => setState(() => revenueType = v ?? 'pendapatan_langsung'),
                    width: 720,
                  ),
                  _textField(remark, 'Remark', width: 720, hintText: 'Con : Pemungut'),
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
                'invoice_date': invoiceDate.text.trim(),
                'description': description.text.trim(),
                'invoice_value': _toDouble(invoiceValue.text),
                'currency': currency.text.trim().isEmpty
                    ? 'IDR'
                    : currency.text.trim(),
                'currency_exchange': _toDouble(currencyExchange.text),
                'invoice_number': invoiceNumber.text.trim(),
                'client': client.text.trim(),
                'receive_date': receiveDate.text.trim().isEmpty
                    ? null
                    : receiveDate.text.trim(),
                'amount_received': _toDouble(amountReceived.text),
                'ppn': _toDouble(ppn.text),
                'pph_23': _toDouble(pph23.text),
                'transfer_fee': _toDouble(transferFee.text),
                'remark': remark.text.trim(),
                'revenue_type': revenueType,
              };
              try {
                await _saveRevenue(payload: payload, id: data?['id'] as int?);
                if (!mounted) return;
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      data == null ? 'Revenue ditambahkan' : 'Revenue diupdate',
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

  Future<void> _deleteRevenue(Map<String, dynamic> item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardColor(ctx),
        title: Text('Hapus Revenue?', style: TextStyle(color: _creamColor(ctx))),
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
      await context.read<RevenueProvider>().deleteRevenue(
        item['id'] as int,
        startDate: _startDate,
        endDate: _endDate,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Revenue dihapus'),
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
    if (_selectedRevenueIds.isEmpty) return null;
    final ids = _selectedRevenueIds
        .map((rowId) => groupByRowId[rowId]?['id'])
        .where((value) => value != null)
        .map((value) => int.tryParse('$value'))
        .whereType<int>()
        .toSet();
    if (ids.length != 1) return null;
    return ids.first;
  }

  Future<void> _combineSelectedRevenue() async {
    if (_selectedRevenueIds.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pilih minimal 2 data revenue.'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    try {
      await context.read<RevenueProvider>().createRevenueCombineGroup(
        year: _selectedYear,
        rowIds: _selectedRevenueIds.toList()..sort(),
      );
      if (!mounted) return;
      setState(() => _selectedRevenueIds.clear());
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Combine revenue disimpan.'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal combine revenue: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  Future<void> _releaseSelectedRevenueCombine(
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
      await context.read<RevenueProvider>().deleteRevenueCombineGroup(
        id: groupId,
        year: _selectedYear,
      );
      if (!mounted) return;
      setState(() => _selectedRevenueIds.clear());
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Combine revenue dilepas.'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal melepas combine revenue: $e'),
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
    String? hintText,
  }) {
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          hintStyle: TextStyle(
            color: _textColor(context).withValues(alpha: 0.4),
            fontSize: 13,
          ),
        ),
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
    Future<void> Function(TextEditingController) pickDate, {
    bool allowEmpty = false,
  }) {
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
          if (allowEmpty && (v == null || v.trim().isEmpty)) return null;
          if (v == null || v.trim().isEmpty) return 'Wajib diisi';
          return DateTime.tryParse(v.trim()) == null
              ? 'Tanggal tidak valid'
              : null;
        },
      ),
    );
  }

  Widget _dropdownField(
    String value,
    String label,
    List<Map<String, String>> options,
    ValueChanged<String?> onChanged, {
    double width = 230,
  }) {
    return SizedBox(
      width: width,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: options.any((o) => o['value'] == value) ? value : options.first['value'],
            isExpanded: true,
            style: TextStyle(color: _textColor(context), fontSize: 16),
            items: options.map((option) {
              return DropdownMenuItem<String>(
                value: option['value'],
                child: Text(option['label']!),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<RevenueProvider>();
    final items = prov.revenues;
    final groupByRowId = _groupByRowId(prov.combineGroups);

    return Scaffold(
      backgroundColor: _surfaceColor(context),
      appBar: AppBar(
        title: Text('Input Revenue'),
        backgroundColor: _cardColor(context),
        actions: [
          DropdownButton<int>(
            value: _selectedYear,
            dropdownColor: _cardColor(context),
            style: TextStyle(color: _textColor(context)),
            items: {
              ...List.generate(30, (i) => 2020 + i),
              _selectedYear
            }.where((y) => y != 0).map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
            onChanged: (v) async {
              if (v == null) return;
              setState(() {
                _selectedYear = v;
                _selectedRevenueIds.clear();
              });
              await _loadData();
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRevenueDialog(),
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
                          onPressed: prov.isLoading ? null : _combineSelectedRevenue,
                          icon: const Icon(Icons.merge_type_rounded),
                          label: Text(
                            'Combine Manual (${_selectedRevenueIds.length})',
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: prov.isLoading
                              ? null
                              : () => _releaseSelectedRevenueCombine(groupByRowId),
                          icon: const Icon(Icons.call_split_rounded),
                          label: const Text('Lepas Combine'),
                        ),
                        TextButton(
                          onPressed: _selectedRevenueIds.isEmpty
                              ? null
                              : () => setState(() => _selectedRevenueIds.clear()),
                          child: const Text('Clear Pilihan'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manual combine default-nya kosong. Pilih baris berurutan dengan Receive Date yang sama persis, lalu tekan Combine Manual.',
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
                          DataColumn(label: Text('Inv Value')),
                          DataColumn(label: Text('Curr')),
                          DataColumn(label: Text('Rate')),
                          DataColumn(label: Text('Inv No')),
                          DataColumn(label: Text('Client')),
                          DataColumn(label: Text('Recv Date')),
                          DataColumn(label: Text('Recv Amt')),
                          DataColumn(label: Text('PPN')),
                          DataColumn(label: Text('PPh23')),
                          DataColumn(label: Text('Fee')),
                          DataColumn(label: Text('Remark')),
                          DataColumn(label: Text('Aksi')),
                        ],
                        rows: items.asMap().entries.map<DataRow>((entry) {
                          final idx = entry.key;
                          final e = Map<String, dynamic>.from(
                            entry.value as Map,
                          );
                          final rowId = _itemId(e);
                          final group = groupByRowId[rowId];
                          final isSelected = _selectedRevenueIds.contains(rowId);
                          return DataRow(
                            selected: isSelected,
                            onSelectChanged: rowId <= 0
                                ? null
                                : (value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedRevenueIds.add(rowId);
                                      } else {
                                        _selectedRevenueIds.remove(rowId);
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
                                              _selectedRevenueIds.add(rowId);
                                            } else {
                                              _selectedRevenueIds.remove(rowId);
                                            }
                                          });
                                        },
                                ),
                              ),
                              DataCell(
                                Text(group == null ? '-' : 'C${group['id']}'),
                              ),
                              DataCell(Text(_displayDate(e['invoice_date']))),
                              DataCell(Text('${idx + 1}')),
                              DataCell(
                                SizedBox(
                                  width: 250,
                                  child: Text(
                                    e['description'] ?? '-',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(_formatNumericInput(e['invoice_value'])),
                              ),
                              DataCell(Text('${e['currency'] ?? 'IDR'}')),
                              DataCell(Text('${e['currency_exchange'] ?? 1}')),
                              DataCell(Text('${e['invoice_number'] ?? '-'}')),
                              DataCell(Text('${e['client'] ?? '-'}')),
                              DataCell(Text(_displayDate(e['receive_date']))),
                              DataCell(
                                Text(_formatNumericInput(e['amount_received'])),
                              ),
                              DataCell(Text(_formatNumericInput(e['ppn']))),
                              DataCell(Text(_formatNumericInput(e['pph_23']))),
                              DataCell(
                                Text(_formatNumericInput(e['transfer_fee'])),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 150,
                                  child: Text(
                                    e['remark'] ?? '-',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () => _showRevenueDialog(e),
                                      icon: Icon(
                                        Icons.edit,
                                        color: AppTheme.accent,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _deleteRevenue(e),
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

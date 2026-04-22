import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/dividend_provider.dart';
import '../../theme/app_theme.dart';

class DividendManagementScreen extends StatefulWidget {
  final int? initialYear;

  const DividendManagementScreen({super.key, this.initialYear});

  @override
  State<DividendManagementScreen> createState() =>
      _DividendManagementScreenState();
}

class _DividendManagementScreenState extends State<DividendManagementScreen> {
  late int _selectedYear;
  final _dateFmt = DateFormat('yyyy-MM-dd');
  final _profitRetainedController = TextEditingController();

  // Helper untuk theme-aware colors
  bool _isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;
  Color _cardColor(BuildContext context) => _isDark(context) ? AppTheme.card : AppTheme.lightCard;
  Color _surfaceColor(BuildContext context) => _isDark(context) ? AppTheme.surface : AppTheme.lightSurface;
  Color _textColor(BuildContext context) => _isDark(context) ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
  Color _secondaryTextColor(BuildContext context) => _isDark(context) ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
  Color _creamColor(BuildContext context) => _isDark(context) ? AppTheme.cream : AppTheme.lightTextPrimary;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear ?? DateTime.now().year;
    Future.microtask(_loadData);
  }

  @override
  void dispose() {
    _profitRetainedController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final provider = context.read<DividendProvider>();
    await provider.fetchDividends(year: _selectedYear);
    if (!mounted) return;
    final settings = Map<String, dynamic>.from(
      (provider.summary['settings'] ?? const <String, dynamic>{}) as Map,
    );
    _profitRetainedController.text = _formatPlain(
      settings['profit_retained'] ?? provider.summary['profit_retained'],
    );
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();

    final raw = (value ?? '').toString().trim();
    if (raw.isEmpty) return 0;

    var cleaned = raw.replaceAll(' ', '');
    final dotCount = '.'.allMatches(cleaned).length;
    final commaCount = ','.allMatches(cleaned).length;

    if (dotCount > 1 && commaCount == 0) {
      cleaned = cleaned.replaceAll('.', '');
    } else if (cleaned.contains('.') && cleaned.contains(',')) {
      cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
    } else if (cleaned.contains(',')) {
      cleaned = cleaned.replaceAll(',', '.');
    }

    return double.tryParse(cleaned) ?? 0;
  }

  String _fmtMoney(dynamic value) {
    final raw = _toDouble(value).toStringAsFixed(0);
    final chars = raw.split('');
    final out = StringBuffer();
    for (int i = 0; i < chars.length; i++) {
      final reverseIndex = chars.length - i;
      out.write(chars[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        out.write('.');
      }
    }
    return 'Rp $out';
  }

  String _formatPlain(dynamic value) {
    final amount = _toDouble(value);
    if (amount == 0) return '';
    return amount.toStringAsFixed(0);
  }

  Future<void> _showRecipientDialog([Map<String, dynamic>? data]) async {
    final formKey = GlobalKey<FormState>();
    final now = DateTime.now();
    final defaultDate = _selectedYear == 0 || _selectedYear == now.year ? now : DateTime(_selectedYear, 12, 31);
    final date = TextEditingController(
      text:
          data?['date']?.toString().substring(0, 10) ??
          _dateFmt.format(defaultDate),
    );
    final name = TextEditingController(text: data?['name'] ?? '');

    Future<void> pickDate(TextEditingController ctrl) async {
      final init =
          DateTime.tryParse(ctrl.text) ?? DateTime(_selectedYear, 12, 31);
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
          data == null ? 'Tambah Penerima Dividen' : 'Edit Penerima Dividen',
          style: TextStyle(color: _creamColor(ctx)),
        ),
        content: SizedBox(
          width: 560,
          child: Form(
            key: formKey,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _dateField(date, 'Tanggal', pickDate),
                _textField(name, 'Nama Penerima', width: 280, required: true),
              ],
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
                'name': name.text.trim(),
              };
              try {
                final provider = context.read<DividendProvider>();
                if (data == null) {
                  payload['profit_retained'] =
                      _toDouble(_profitRetainedController.text);
                  await provider.createDividend(payload, year: _selectedYear);
                } else {
                  await provider.updateDividend(
                    data['id'] as int,
                    payload,
                    year: _selectedYear,
                  );
                }
                if (!mounted || !ctx.mounted) return;
                Navigator.pop(ctx);
                _profitRetainedController.text =
                    _formatPlain(provider.summary['profit_retained']);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      data == null
                          ? 'Penerima dividen ditambahkan'
                          : 'Penerima dividen diupdate',
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

  Future<void> _saveProfitRetained() async {
    try {
      await context.read<DividendProvider>().updateDividendSetting(
        _selectedYear,
        {'profit_retained': _toDouble(_profitRetainedController.text)},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profit ditahan diupdate'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal update profit ditahan: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  Future<void> _deleteDividend(Map<String, dynamic> item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardColor(ctx),
        title: Text(
          'Hapus Penerima Dividen?',
          style: TextStyle(color: _creamColor(ctx)),
        ),
        content: Text(
          item['name'] ?? '-',
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
    if (ok != true || !mounted) return;

    try {
      await context.read<DividendProvider>().deleteDividend(
        item['id'] as int,
        year: _selectedYear,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Penerima dividen dihapus'),
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

  Widget _dateField(
    TextEditingController controller,
    String label,
    Future<void> Function(TextEditingController) onPick,
  ) {
    return SizedBox(
      width: 230,
      child: TextFormField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => onPick(controller),
          ),
        ),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
        onTap: () => onPick(controller),
      ),
    );
  }

  Widget _buildCalculationCard(Map<String, dynamic> summary) {
    final profitAfterTax = _toDouble(summary['profit_after_tax']);
    final profitRetained = _toDouble(_profitRetainedController.text);
    final recipientCount = (summary['recipient_count'] ?? 0) as int;
    final dividendDistributed = (profitAfterTax - profitRetained).clamp(
      0,
      double.infinity,
    );
    final dividendPerPerson = recipientCount > 0
        ? dividendDistributed / recipientCount
        : 0.0;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget metric(String label, String value) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.surface : AppTheme.lightSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isDark ? AppTheme.divider : AppTheme.lightDivider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary)),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      color: isDark ? AppTheme.card : AppTheme.lightCard,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hitung Dividen',
              style: TextStyle(
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            // Fix: Row dengan Expanded untuk form input
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _profitRetainedController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Profit Ditahan',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    onChanged: (_) {},
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _saveProfitRetained,
                  child: const Text('Simpan & Hitung'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Fix: Row metrics dengan Flexible untuk responsive
            Row(
              children: [
                Expanded(child: metric('Profit After Tax', _fmtMoney(profitAfterTax))),
                const SizedBox(width: 12),
                Expanded(child: metric('Dividen Dibagi', _fmtMoney(dividendDistributed))),
                const SizedBox(width: 12),
                Expanded(child: metric('Dibagi per Orang', _fmtMoney(dividendPerPerson))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<DividendProvider>();
    final items = prov.dividends;
    final summary = prov.summary;

    return Scaffold(
      backgroundColor: _surfaceColor(context),
      appBar: AppBar(
        title: const Text('Manajemen Dividen'),
        backgroundColor: _cardColor(context),
        actions: [
          DropdownButton<int>(
            value: _selectedYear,
            dropdownColor: _cardColor(context),
            style: TextStyle(color: _textColor(context)),
            items: {
              ...List.generate(31, (index) => 2020 + index),
              _selectedYear
            }.where((y) => y != 0).map((y) => DropdownMenuItem(
                      value: y,
                      child: Text('Tahun $y'),
                    )).toList(),
            onChanged: (value) async {
              if (value == null) return;
              setState(() => _selectedYear = value);
              await _loadData();
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _showRecipientDialog(),
            icon: const Icon(Icons.add),
            tooltip: 'Tambah Penerima',
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRecipientDialog(),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Tambah Penerima'),
      ),
      body: prov.isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                _buildCalculationCard(summary),
                const SizedBox(height: 16),
                if (items.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: Text(
                        'Belum ada penerima dividen.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  )
                else
                  ...items.map((rawItem) {
                    final item = Map<String, dynamic>.from(
                      rawItem as Map<dynamic, dynamic>,
                    );
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        color: AppTheme.card,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          title: Text(
                            (item['name'] ?? '-').toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '${(item['date'] ?? '').toString()} | Bagian/orang: ${_fmtMoney(summary['dividend_per_person'])}',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          ),
                          trailing: Wrap(
                            spacing: 4,
                            children: [
                              IconButton(
                                onPressed: () => _showRecipientDialog(item),
                                icon: const Icon(Icons.edit_outlined),
                                color: Colors.amber,
                              ),
                              IconButton(
                                onPressed: () => _deleteDividend(item),
                                icon: const Icon(Icons.delete_outline),
                                color: AppTheme.danger,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}

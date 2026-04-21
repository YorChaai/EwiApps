import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/dividend_provider.dart';
import '../../theme/app_theme.dart';

class BalanceSheetSettingsScreen extends StatefulWidget {
  final int? initialYear;

  const BalanceSheetSettingsScreen({super.key, this.initialYear});

  @override
  State<BalanceSheetSettingsScreen> createState() =>
      _BalanceSheetSettingsScreenState();
}

class _BalanceSheetSettingsScreenState extends State<BalanceSheetSettingsScreen> {
  late int _selectedYear;
  final _openingCashController = TextEditingController();
  final _accountsReceivableController = TextEditingController();
  final _prepaidTaxController = TextEditingController();
  final _prepaidExpensesController = TextEditingController();
  final _otherReceivablesController = TextEditingController();
  final _officeInventoryController = TextEditingController();
  final _otherAssetsController = TextEditingController();
  final _accountsPayableController = TextEditingController();
  final _salaryPayableController = TextEditingController();
  final _shareholderPayableController = TextEditingController();
  final _accruedExpensesController = TextEditingController();
  final _shareCapitalController = TextEditingController();
  final _retainedEarningsBalanceController = TextEditingController();

  // Helper untuk theme-aware colors
  bool _isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;
  Color _cardColor(BuildContext context) => _isDark(context) ? AppTheme.card : AppTheme.lightCard;
  Color _surfaceColor(BuildContext context) => _isDark(context) ? AppTheme.surface : AppTheme.lightSurface;
  Color _textColor(BuildContext context) => _isDark(context) ? AppTheme.textPrimary : AppTheme.lightTextPrimary;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear ?? DateTime.now().year;
    Future.microtask(_loadData);
  }

  @override
  void dispose() {
    _openingCashController.dispose();
    _accountsReceivableController.dispose();
    _prepaidTaxController.dispose();
    _prepaidExpensesController.dispose();
    _otherReceivablesController.dispose();
    _officeInventoryController.dispose();
    _otherAssetsController.dispose();
    _accountsPayableController.dispose();
    _salaryPayableController.dispose();
    _shareholderPayableController.dispose();
    _accruedExpensesController.dispose();
    _shareCapitalController.dispose();
    _retainedEarningsBalanceController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final provider = context.read<DividendProvider>();
    await provider.fetchDividends(year: _selectedYear);
    if (!mounted) return;
    final settings = Map<String, dynamic>.from(
      (provider.summary['settings'] ?? const <String, dynamic>{}) as Map,
    );
    _openingCashController.text = _formatPlain(settings['opening_cash_balance']);
    _accountsReceivableController.text = _formatPlain(
      settings['accounts_receivable'],
    );
    _prepaidTaxController.text = _formatPlain(settings['prepaid_tax_pph23']);
    _prepaidExpensesController.text = _formatPlain(settings['prepaid_expenses']);
    _otherReceivablesController.text = _formatPlain(
      settings['other_receivables'],
    );
    _officeInventoryController.text = _formatPlain(settings['office_inventory']);
    _otherAssetsController.text = _formatPlain(settings['other_assets']);
    _accountsPayableController.text = _formatPlain(
      settings['accounts_payable'],
    );
    _salaryPayableController.text = _formatPlain(settings['salary_payable']);
    _shareholderPayableController.text = _formatPlain(
      settings['shareholder_payable'],
    );
    _accruedExpensesController.text = _formatPlain(
      settings['accrued_expenses'],
    );
    _shareCapitalController.text = _formatPlain(settings['share_capital']);
    _retainedEarningsBalanceController.text = _formatPlain(
      settings['retained_earnings_balance'],
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

  String _formatPlain(dynamic value) {
    final amount = _toDouble(value);
    if (amount == 0) return '';
    return amount.toStringAsFixed(0);
  }

  Future<void> _saveSettings() async {
    try {
      await context.read<DividendProvider>().updateDividendSetting(
        _selectedYear,
        {
          'opening_cash_balance': _toDouble(_openingCashController.text),
          'accounts_receivable': _toDouble(_accountsReceivableController.text),
          'prepaid_tax_pph23': _toDouble(_prepaidTaxController.text),
          'prepaid_expenses': _toDouble(_prepaidExpensesController.text),
          'other_receivables': _toDouble(_otherReceivablesController.text),
          'office_inventory': _toDouble(_officeInventoryController.text),
          'other_assets': _toDouble(_otherAssetsController.text),
          'accounts_payable': _toDouble(_accountsPayableController.text),
          'salary_payable': _toDouble(_salaryPayableController.text),
          'shareholder_payable': _toDouble(_shareholderPayableController.text),
          'accrued_expenses': _toDouble(_accruedExpensesController.text),
          'share_capital': _toDouble(_shareCapitalController.text),
          'retained_earnings_balance': _toDouble(
            _retainedEarningsBalanceController.text,
          ),
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Setting neraca tahunan diupdate'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal update setting neraca: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  Widget _field(String label, TextEditingController controller) {
    return SizedBox(
      width: 260,
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<DividendProvider>();

    return Scaffold(
      backgroundColor: _surfaceColor(context),
      appBar: AppBar(
        title: const Text('Manajemen Neraca'),
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
          const SizedBox(width: 12),
        ],
      ),
      body: prov.isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: AppTheme.card,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Setting Neraca Tahunan',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _field('Kas Tahun Sebelumnya', _openingCashController),
                            _field('Piutang Usaha', _accountsReceivableController),
                            _field(
                              'Pajak Bayar di Muka (pph23)',
                              _prepaidTaxController,
                            ),
                            _field(
                              'Biaya Bayar di Muka',
                              _prepaidExpensesController,
                            ),
                            _field(
                              'Piutang Lain Lain',
                              _otherReceivablesController,
                            ),
                            _field('Inventaris Kantor', _officeInventoryController),
                            _field('Aktiva Lain Lain', _otherAssetsController),
                            _field('Hutang Usaha', _accountsPayableController),
                            _field('Hutang Gaji', _salaryPayableController),
                            _field(
                              'Hutang Pemegang Saham',
                              _shareholderPayableController,
                            ),
                            _field(
                              'Biaya Masih Harus Dibayar',
                              _accruedExpensesController,
                            ),
                            _field('Modal Saham', _shareCapitalController),
                            _field(
                              'Laba Ditahan Awal',
                              _retainedEarningsBalanceController,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: _saveSettings,
                            child: const Text('Simpan Setting Neraca'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

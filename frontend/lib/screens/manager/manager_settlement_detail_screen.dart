import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settlement_provider.dart';
import '../../providers/auth_provider.dart';
import 'package:intl/intl.dart';

class ManagerSettlementDetailScreen extends StatefulWidget {
  final int settlementId;

  const ManagerSettlementDetailScreen({super.key, required this.settlementId});

  @override
  State<ManagerSettlementDetailScreen> createState() =>
      _ManagerSettlementDetailScreenState();
}

class _ManagerSettlementDetailScreenState
    extends State<ManagerSettlementDetailScreen> {
  final _idrCurrencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final _foreignCurrencyFormat = NumberFormat('#,##0.##', 'en_US');
  final Set<int> _checkedExpenseIds = {};

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatExpenseAmount(dynamic expense) {
    final currency = (expense['currency'] ?? 'IDR').toString().toUpperCase();
    final amount = _toDouble(expense['amount']);

    if (currency == 'IDR') {
      return _idrCurrencyFormat.format(amount);
    }

    return '$currency ${_foreignCurrencyFormat.format(amount)}';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettlementProvider>().loadSettlement(widget.settlementId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    // Import AuthProvider if needed, but assuming it's available as needed.
    // We can use provider directly.
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Persetujuan')),
      body: Consumer<SettlementProvider>(
        builder: (context, provider, child) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        provider.loadSettlement(widget.settlementId),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          final settlement = provider.currentSettlement;
          if (settlement == null) {
            return const Center(child: Text('Data tidak ditemukan.'));
          }

          final expenses = settlement['expenses'] as List? ?? [];

          return Column(
            children: [
              _buildSettlementInfo(settlement),
              const Divider(height: 1),
              Expanded(
                child: expenses.isEmpty
                    ? const Center(child: Text('Tidak ada rincian biaya.'))
                    : _buildExpensesList(expenses, provider),
              ),
              if (settlement['status'] == 'submitted')
                _buildApprovalActions(settlement['id'], settlement, provider),
              if (auth.isManager && ['draft', 'submitted', 'rejected'].contains(settlement['status']))
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _deleteSettlement(settlement['id'], provider),
                      icon: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                      label: const Text('Hapus Seluruh Pengajuan', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSettlementInfo(Map<String, dynamic> settlement) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            settlement['title'],
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text('Diajukan oleh: ${settlement['creator_name'] ?? 'Unknown'}'),
          Text(
            'Total Diajukan: ${_idrCurrencyFormat.format(settlement['total_amount'] ?? 0)}',
          ),
          Row(
            children: [
              const Text('Status: '),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(
                    settlement['status'],
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  settlement['status'].toString().toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(settlement['status']),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesList(List expenses, SettlementProvider provider) {
    return ListView.builder(
      itemExtent: 85.0,
      cacheExtent: 340,
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final expense = expenses[index];
        final expenseId = expense['id'] as int;
        final isPending = expense['status'] == 'pending';
        final isChecked = _checkedExpenseIds.contains(expenseId);
        final categoryStatus = (expense['category_status'] ?? 'approved').toString().toLowerCase();
        final isCategoryApproved = categoryStatus == 'approved';

        final isRejected = expense['status'] == 'rejected';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: isRejected ? 4 : 2,
          color: isRejected ? Colors.red.shade50 : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isRejected ? const BorderSide(color: Colors.red, width: 1) : BorderSide.none,
          ),
          child: ExpansionTile(
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isPending)
                  Checkbox(
                    value: isChecked,
                    onChanged: isCategoryApproved
                        ? (value) {
                            setState(() {
                              if (value == true) {
                                _checkedExpenseIds.add(expenseId);
                              } else {
                                _checkedExpenseIds.remove(expenseId);
                              }
                            });
                          }
                        : null,
                    activeColor: Colors.green,
                  ),
                const SizedBox(width: 8),
                Icon(
                  _getIconForStatus(expense['status']),
                  color: _getStatusColor(expense['status']),
                ),
              ],
            ),
            title: Text(expense['description'] ?? 'No Description'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Builder(builder: (context) {
                  final catName = expense['category_name'] ?? '-';
                  String subCat = catName;
                  if (catName.contains(' > ')) {
                    subCat = catName.split(' > ').last;
                  }
                  return Text(
                    '$subCat - ${_formatExpenseAmount(expense)}',
                  );
                }),
                if (!isCategoryApproved && isPending)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      '⚠️ Kategori belum di-approve',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (expense['notes'] != null &&
                        expense['notes'].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          'Catatan: ${expense['notes']}',
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                    if (expense['status'] == 'pending')
                      Align(
                        alignment: Alignment.centerRight,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.end,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.close, color: Colors.red),
                              label: const Text(
                                'Tolak',
                                style: TextStyle(color: Colors.red),
                              ),
                              onPressed: () =>
                                  _rejectExpense(expense['id'], provider),
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.check),
                              label: const Text('Setujui'),
                              onPressed: () =>
                                  _approveExpense(expense['id'], provider),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildApprovalActions(int settlementId, Map<String, dynamic> settlement, SettlementProvider provider) {
    final expenses = settlement['expenses'] as List? ?? [];
    final hasRejected = expenses.any((e) => (e['status'] ?? '').toString().toLowerCase() == 'rejected');

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;
          final buttons = [
            OutlinedButton.icon(
              icon: const Icon(Icons.close),
              label: const Text('Tolak Semua'),
              onPressed: () => _rejectAll(settlementId, provider),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('Setujui Semua'),
              onPressed: hasRejected ? null : () => _approveAll(settlementId, provider),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ];

          if (isNarrow) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [buttons[0], const SizedBox(height: 12), buttons[1]],
            );
          }

          return Row(
            children: [
              Expanded(child: buttons[0]),
              const SizedBox(width: 16),
              Expanded(child: buttons[1]),
            ],
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
      case 'completed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'submitted':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconForStatus(String status) {
    switch (status) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.pending;
    }
  }

                // logika aksi

  Future<void> _approveExpense(
    int expenseId,
    SettlementProvider provider,
  ) async {
    // cek apakah kategori sudah approved
    final expense = provider.currentSettlement?['expenses']
        .firstWhere((e) => e['id'] == expenseId, orElse: () => null);
    if (expense != null) {
      final categoryStatus = (expense['category_status'] ?? 'approved').toString().toLowerCase();
      if (categoryStatus != 'approved') {
        final categoryName = expense['category_name'] ?? 'Kategori ini';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$categoryName belum di-approve. Silakan approve kategori terlebih dahulu.'),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: 'Ke Kategori',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.pop(context);
                  // navigate to category page - for now just show message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Silakan buka halaman Kategori untuk approve'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
              ),
            ),
          );
        }
        return;
      }
    }

    final success = await provider.approveExpense(expenseId, 'approve');
    if (success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Biaya disetujui')));
      // remove from checked after approve
      setState(() {
        _checkedExpenseIds.remove(expenseId);
      });
    }
  }

  Future<void> _rejectExpense(
    int expenseId,
    SettlementProvider provider,
  ) async {
    final controller = TextEditingController();
    final notes = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alasan Penolakan'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Masukkan alasan...'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (notes != null) {
      final success = await provider.approveExpense(
        expenseId,
        'reject',
        notes: notes,
      );
      if (success && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Biaya ditolak')));
      }
    }
  }

  Future<void> _approveAll(
    int settlementId,
    SettlementProvider provider,
  ) async {
    final settlement = provider.currentSettlement;
    if (settlement == null) return;

    final expenses = settlement['expenses'] as List? ?? [];
    final pendingItems = expenses.where((e) => e['status'] == 'pending').toList();

    // Validasi: semua item pending harus dicentang
    if (_checkedExpenseIds.length != pendingItems.length) {
      if (mounted) {
        final remaining = pendingItems.length - _checkedExpenseIds.length;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Masih ada $remaining item yang belum diperiksa. '
              'Gunakan checkbox untuk menandai checklist.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Setujui Semua?'),
        content: const Text(
          'Apakah Anda yakin ingin menyetujui semua biaya dalam pengajuan ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Setujui'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await provider.approveAllSettlement(settlementId);
      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seluruh pengajuan telah disetujui')),
        );
      }
    }
  }

  Future<void> _rejectAll(int settlementId, SettlementProvider provider) async {
    final settlement = provider.currentSettlement;
    if (settlement == null) return;

    final expenses = settlement['expenses'] as List? ?? [];
    final pendingItems = expenses.where((e) => e['status'] == 'pending').toList();

    if (_checkedExpenseIds.length != pendingItems.length) {
      if (mounted) {
        final remaining = pendingItems.length - _checkedExpenseIds.length;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Masih ada $remaining item yang belum diperiksa sebelum menolak pengajuan.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final controller = TextEditingController();
    final notes = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tolak Semua?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Apakah Anda yakin ingin menolak semua biaya dalam pengajuan ini?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Alasan penolakan...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Ya, Tolak Semua'),
          ),
        ],
      ),
    );

    if (notes != null) {
      final success = await provider.rejectAllSettlement(
        settlementId,
        notes: notes,
      );
      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seluruh pengajuan telah ditolak')),
        );
      }
    }
  }

  Future<void> _deleteSettlement(int settlementId, SettlementProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Pengajuan?'),
        content: const Text('Tindakan ini tidak bisa dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await provider.deleteSettlement(settlementId);
      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengajuan berhasil dihapus')),
        );
      }
    }
  }
}

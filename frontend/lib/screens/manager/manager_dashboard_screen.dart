import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settlement_provider.dart';
import '../../providers/advance_provider.dart';
import 'manager_settlement_detail_screen.dart';

class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettlementProvider>().loadSettlements(status: 'submitted');
      context.read<AdvanceProvider>().loadAdvances(status: 'submitted');
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manager Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Unduh Laporan Excel',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fitur unduh laporan akan segera hadir'),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Persetujuan Settlement'),
            Tab(text: 'Persetujuan Uang Muka'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildSettlementsForApproval(), _buildAdvancesForApproval()],
      ),
    );
  }

  Widget _buildSettlementsForApproval() {
    return Consumer<SettlementProvider>(
      builder: (context, provider, _) {
        if (provider.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: ${provider.error}'),
                ElevatedButton(
                  onPressed: () =>
                      provider.loadSettlements(status: 'submitted'),
                  child: const Text('Refresh'),
                ),
              ],
            ),
          );
        }

        final settlements = provider.settlements
            .where((s) => s['status'] == 'submitted')
            .toList();
        if (settlements.isEmpty) {
          return const Center(
            child: Text('Tidak ada settlement yang butuh persetujuan.'),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadSettlements(status: 'submitted'),
          child: ListView.builder(
            itemExtent: 72.0,
            cacheExtent: 288,
            itemCount: settlements.length,
            itemBuilder: (context, index) {
              final s = settlements[index];
              return ListTile(
                title: Text(s['title']),
                subtitle: Text(
                  'Oleh: ${s['creator_name']} - Total: ${s['total_amount']}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ManagerSettlementDetailScreen(settlementId: s['id']),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAdvancesForApproval() {
    return Consumer<AdvanceProvider>(
      builder: (context, provider, _) {
        if (provider.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: ${provider.error}'),
                ElevatedButton(
                  onPressed: () => provider.loadAdvances(status: 'submitted'),
                  child: const Text('Refresh'),
                ),
              ],
            ),
          );
        }

        final advances = provider.advances
            .where((a) => a['status'] == 'submitted')
            .toList();
        if (advances.isEmpty) {
          return const Center(child: Text('Tidak ada permintaan uang muka.'));
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadAdvances(status: 'submitted'),
          child: ListView.builder(
            itemExtent: 72.0,
            cacheExtent: 288,
            itemCount: advances.length,
            itemBuilder: (context, index) {
              final a = advances[index];
              return ListTile(
                title: Text((a['title'] ?? '-').toString()),
                subtitle: Text(
                  'Oleh: ${a['requester_name']} - Jumlah: ${a['total_amount']}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showAdvanceApprovalDialog(a, provider),
              );
            },
          ),
        );
      },
    );
  }

  void _showAdvanceApprovalDialog(
    Map<String, dynamic> advance,
    AdvanceProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Proses Permintaan"),
        content: Text(
          "Proses permintaan uang muka untuk '${advance['title'] ?? '-'}'?",
        ),
        actions: [
          TextButton(
            child: const Text("Tolak"),
            onPressed: () async {
              final controller = TextEditingController();
              final notes = await showDialog<String>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Alasan Penolakan'),
                  content: TextField(
                    controller: controller,
                    decoration: const InputDecoration(hintText: 'Alasan...'),
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
              if (notes != null && context.mounted) {
                await provider.rejectAdvance(advance['id'], notes);
                if (context.mounted) Navigator.of(context).pop();
              }
            },
          ),
          TextButton(
            child: const Text("Setujui"),
            onPressed: () async {
              await provider.approveAdvance(advance['id']);
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

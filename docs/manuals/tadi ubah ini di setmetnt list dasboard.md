pertama tadi benerin ini Edit 1**: Tambah state variable `_selectedType
"
bool _showScrollToTop = false;
  bool _selectionMode = false;
  final Set<int> _selectedSettlementIds = {};
  String _selectedType = 'single';

  Color _cardColor(BuildContext context) =>
      context.isDark ? AppTheme.card : AppTheme.lightCard;
  void resetFilters() {
    if (!mounted) return;
    setState(() {
      _statusFilter = null;
      _searchQuery = '';
      _searchCtrl.clear();
      _startDate = null;
      _endDate = null;
      _selectedType = 'single';
    });
    context.read<SettlementProvider>().clearFilters();
    scrollToTop();
                                    )
                                    .toList();
                                final items = <dynamic>[];
                                if (singles.isNotEmpty) {
                                  items.add('__header_single__');
                                  items.addAll(singles);
                                }
                                if (batches.isNotEmpty) {
                                  items.add('__header_batch__');
                                  items.addAll(batches);
                                }
                                final displayList =
                                    _selectedType == 'single'
                                        ? singles
                                        : batches;
                                final items = <dynamic>[...displayList];

                                return CustomScrollView(
                                  key: const PageStorageKey('settlement_list'),
                                        ),
                                      )
                                    else if (prov.settlements.isEmpty)
                                    else if (items.isEmpty)
                                      SliverFillRemaining(
                                        hasScrollBody: false,
                                        child: Center(
                                        ),
                                        sliver: SliverList(
                                          delegate: SliverChildBuilderDelegate((
                                            context,
                                            i,
                                          ) {
                                            final item = items[i];
                                            if (item == '__header_single__') {
                                              return _buildGroupHeader(
                                                Icons.receipt_long_rounded,
                                                'Pengeluaran Sendiri (${singles.length})',
                                                AppTheme.primary,
                                              );
                                            }
                                            if (item == '__header_batch__') {
                                              return _buildGroupHeader(
                                                Icons.folder_rounded,
                                                'Pengeluaran Batch (${batches.length})',
                                                AppTheme.warning,
                                              );
                                            }
                                            final s =
                                                item as Map<String, dynamic>;
                                                items[i] as Map<String, dynamic>;
                                            return RepaintBoundary(
                                              child: SettlementCard(
                                                key: ValueKey(
              ],
            ),
          ),
          SizedBox(height: useCompact ? 12 : 16),
          _buildTypeToggle(useCompact),
        ],
      ),
    );
  }

  Widget _buildTypeToggle(bool useCompact) {
    final prov = context.read<SettlementProvider>();
    final singlesCount = prov.settlements
        .where((s) => (s['settlement_type'] ?? 'single') == 'single')
        .length;
    final batchesCount = prov.settlements
        .where((s) => (s['settlement_type'] ?? 'single') == 'batch')
        .length;

    Widget buildBtn(String label, int count, String value) {
      final isActive = _selectedType == value;
      return OutlinedButton(
        onPressed: () => setState(() => _selectedType = value),
        style: OutlinedButton.styleFrom(
          backgroundColor: isActive ? AppTheme.primary : Colors.transparent,
          side: const BorderSide(color: AppTheme.primary),
          foregroundColor: isActive ? Colors.white : AppTheme.primary,
          padding: useCompact
              ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
              : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          minimumSize: useCompact ? const Size(0, 32) : const Size(0, 40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: useCompact ? 11 : 13,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppTheme.primary,
          ),
        ),
      );
    }

    return Row(
      children: [
        buildBtn('Pengeluaran Sendiri', singlesCount, 'single'),
        SizedBox(width: useCompact ? 8 : 12),
        buildBtn('Pengeluaran Batch', batchesCount, 'batch'),
      ],
    );
  }

  Widget _buildSummaryCards(bool isNarrow, bool useCompact) {
    final prov = context.read<SettlementProvider>();
    final total = _annualSettlementTotal ?? 0.0;
    "

Luar biasa — semua 6 perubahan diterapkan sekaligus. Sekarang verifikasi hasilnya dengan membaca bagian-bagian kritis:

"
Hanya ada 1 warning: `_buildGroupHeader` tidak lagi dipakai karena kita sudah hapus logika header. Hapus method tersebut:
"
  }

  Widget _buildGroupHeader(IconData icon, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _titleColorLocal(context),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildScrollableSettlementHeader(
    BuildContext context,
    "

"
Bersih, tidak ada issue!** ✅

---

Berikut rangkuman semua perubahan yang telah diterapkan:

### 1. State variable baru (L389)
```D:\2. Organize\1. Projects\MiniProjectKPI_EWI\frontend\lib\screens\dashboard_screen.dart#L389
  String _selectedType = 'single';
```

### 2. `resetFilters()` — tambah reset `_selectedType`
```D:\2. Organize\1. Projects\MiniProjectKPI_EWI\frontend\lib\screens\dashboard_screen.dart#L430-433
    setState(() {
      _statusFilter = null;
      ...
      _selectedType = 'single';
    });
```

### 3. Builder — logika `items` diganti filter per tab
```D:\2. Organize\1. Projects\MiniProjectKPI_EWI\frontend\lib\screens\dashboard_screen.dart#L857-862
                                final displayList =
                                    _selectedType == 'single'
                                        ? singles
                                        : batches;
                                final items = <dynamic>[...displayList];
```

### 4. Empty state check pakai `items.isEmpty`
Sebelumnya `prov.settlements.isEmpty` — sekarang `items.isEmpty` agar tab yang kosong (misal tidak ada batch) pun menampilkan pesan kosong yang tepat.

### 5. `SliverChildBuilderDelegate` — langsung render `SettlementCard`
Kondisi `__header_single__` / `__header_batch__` dihapus, diganti:
```D:\2. Organize\1. Projects\MiniProjectKPI_EWI\frontend\lib\screens\dashboard_screen.dart#L925-926
                                            final s =
                                                items[i] as Map<String, dynamic>;
```

### 6. `_buildTypeToggle(useCompact)` — widget toggle baru
Ditambahkan di akhir Column `_buildScrollableSettlementHeader`, dengan dua `OutlinedButton`:
- Tab aktif: background `AppTheme.primary`, teks putih
- Tab tidak aktif: transparan, border + teks `AppTheme.primary`
- Menampilkan jumlah `(singlesCount)` / `(batchesCount)` di samping label

### 7. `_buildGroupHeader` dihapus
Karena sudah tidak digunakan setelah header statis dihilangkan.
"


ini full kode di ubah tadi ada merah di hapus dna hijau di tambah
"


bool _selectionMode = false;
  final Set<int> _selectedSettlementIds = {};
  String _selectedType = 'single';

  Color _cardColor(BuildContext context) =>
      context.isDark ? AppTheme.card : AppTheme.lightCard;
      _startDate = null;
      _endDate = null;
      _selectedType = 'single';
    });
    context.read<SettlementProvider>().clearFilters();
    scrollToTop();
  }
                                    )
                                    .toList();
                                final items = <dynamic>[];
                                if (singles.isNotEmpty) {
                                  items.add('__header_single__');
                                  items.addAll(singles);
                                }
                                if (batches.isNotEmpty) {
                                  items.add('__header_batch__');
                                  items.addAll(batches);
                                }
                                final displayList =
                                    _selectedType == 'single'
                                        ? singles
                                        : batches;
                                final items = <dynamic>[...displayList];

                                return CustomScrollView(
                                  key: const PageStorageKey('settlement_list'),
                                        ),
                                      )
                                    else if (prov.settlements.isEmpty)
                                    else if (items.isEmpty)
                                      SliverFillRemaining(
                                        hasScrollBody: false,
                                        child: Center(
                                            i,
                                          ) {
                                            final item = items[i];
                                            if (item == '__header_single__') {
                                              return _buildGroupHeader(
                                                Icons.receipt_long_rounded,
                                                'Pengeluaran Sendiri (${singles.length})',
                                                AppTheme.primary,
                                              );
                                            }
                                            if (item == '__header_batch__') {
                                              return _buildGroupHeader(
                                                Icons.folder_rounded,
                                                'Pengeluaran Batch (${batches.length})',
                                                AppTheme.warning,
                                              );
                                            }
                                            final s =
                                                item as Map<String, dynamic>;
                                                items[i] as Map<String, dynamic>;
                                            return RepaintBoundary(
                                              child: SettlementCard(
                                                key: ValueKey(
  }

  Widget _buildGroupHeader(IconData icon, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _titleColorLocal(context),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildScrollableSettlementHeader(
    BuildContext context,
            ),
          ),
          SizedBox(height: useCompact ? 12 : 16),
          _buildTypeToggle(useCompact),
        ],
      ),
    );
  }

  Widget _buildTypeToggle(bool useCompact) {
    final prov = context.read<SettlementProvider>();
    final singlesCount = prov.settlements
        .where((s) => (s['settlement_type'] ?? 'single') == 'single')
        .length;
    final batchesCount = prov.settlements
        .where((s) => (s['settlement_type'] ?? 'single') == 'batch')
        .length;

    Widget buildBtn(String label, int count, String value) {
      final isActive = _selectedType == value;
      return OutlinedButton(
        onPressed: () => setState(() => _selectedType = value),
        style: OutlinedButton.styleFrom(
          backgroundColor: isActive ? AppTheme.primary : Colors.transparent,
          side: const BorderSide(color: AppTheme.primary),
          foregroundColor: isActive ? Colors.white : AppTheme.primary,
          padding: useCompact
              ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
              : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          minimumSize: useCompact ? const Size(0, 32) : const Size(0, 40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: useCompact ? 11 : 13,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppTheme.primary,
          ),
        ),
      );
    }

    return Row(
      children: [
        buildBtn('Pengeluaran Sendiri', singlesCount, 'single'),
        SizedBox(width: useCompact ? 8 : 12),
        buildBtn('Pengeluaran Batch', batchesCount, 'batch'),
      ],
    );
  }

  Widget _buildSummaryCards(bool isNarrow, bool useCompact) {
    final prov = context.read<SettlementProvider>();
    final total = _annualSettlementTotal ?? 0.0;
    final card = Container(
"

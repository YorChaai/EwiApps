final ScrollController _scrollController = ScrollController();
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
  final _currencyFormat = NumberFormat('#,##0', 'id_ID');

  bool _isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;
  Color _cardColor(BuildContext context) => _isDark(context) ? AppTheme.card : AppTheme.lightCard;
  Color _surfaceColor(BuildContext context) => _isDark(context) ? AppTheme.surface : AppTheme.lightSurface;
  Color _dividerColor(BuildContext context) => _isDark(context) ? AppTheme.divider : AppTheme.lightDivider;
  Color _titleColor(BuildContext context) => _isDark(context) ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
  Color _bodyColor(BuildContext context) => _isDark(context) ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
  Color _primaryText(BuildContext context) => _isDark(context) ? AppTheme.textPrimary : AppTheme.lightTextPrimary;

  @override
  void initState() {
    super.initState();
    _loadDefaultReportYearAndFetch();
    _fetchCategories();
  }

  @override
      final api = context.read<AuthProvider>().api;
      final res = await api.getCategories();
      // Backend return: {'categories': [...]}
      if (res.containsKey('categories')) {
        final cats = (res['categories'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        // Sort by sort_order (ascending)
        cats.sort((a, b) {
          final orderA = a['sort_order'] ?? 999;
          final orderB = b['sort_order'] ?? 999;
          return orderA.compareTo(orderB);
        });
        setState(() => _categories = cats);
        final cats = (res['categories'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        cats.sort((a, b) => (a['sort_order'] ?? 999).compareTo(b['sort_order'] ?? 999));
        if (mounted) setState(() => _categories = cats);
      }
    } catch (_) {
      // Ignore error, use fallback
    }
    } catch (_) {}
  }

  Future<void> _loadDefaultReportYearAndFetch() async {
      final prov = context.read<SettlementProvider>();
      await prov.syncReportYear();
      if (mounted) {
        setState(() => _selectedYear = prov.reportYear);
      }
    } catch (_) {
      // fallback
    }
      if (mounted) setState(() => _selectedYear = prov.reportYear);
    } catch (_) {}
    await _fetchReport();
  }

      final api = context.read<AuthProvider>().api;
      final data = await api.getAnnualReport(year: _selectedYear);
      setState(() => _reportData = data);
      if (mounted) setState(() => _reportData = data);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to fetch report: $e'),
          backgroundColor: Colors.red,
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      if (mounted) setState(() => _isLoading = false);
    }
  }

      final api = context.read<AuthProvider>().api;
      final bytes = await api.getAnnualReportPdf(year: _selectedYear);
      final fileName = 'Laporan_Tahunan_$_selectedYear.pdf';
      if (!mounted) return;
      await FileHelper.saveAndOpenFile(
        context: context,
        bytes: bytes,
        filename: fileName,
        successMessage: 'PDF laporan tahunan berhasil disimpan.',
      );
      await FileHelper.saveAndOpenFile(context: context, bytes: bytes, filename: 'Laporan_Tahunan_$_selectedYear.pdf');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal export PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal export PDF: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      if (mounted) setState(() => _isLoading = false);
    }
  }

    try {
      final api = context.read<AuthProvider>().api;
      final bytes = await api.getAnnualReportExcel(year: _selectedYear);
      final fileName =
          'Revenue-Cost_${_selectedYear}_${FileHelper.formatTimestamp()}.xlsx';
      if (!mounted) return;
      await FileHelper.saveAndOpenFile(
        context: context,
        bytes: bytes,
        filename: fileName,
        successMessage: 'Excel laporan tahunan berhasil disimpan.',
      );
      await FileHelper.saveAndOpenFile(context: context, bytes: bytes, filename: 'Revenue-Cost_$_selectedYear.xlsx');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal export Excel: $e'),
          backgroundColor: Colors.red,
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _asListMap(dynamic data) {
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '').toString().replaceAll(',', '')) ?? 0;
  }

  String _fmtNumber(dynamic value, {int decimals = 0}) {
    final v = _toDouble(value);
    return v.toStringAsFixed(decimals);
  }

  String _fmtMoney(dynamic value) {
    final s = _fmtNumber(value, decimals: 0);
    final parts = s.split('.');
    final whole = parts[0];
    final buffer = StringBuffer();
    for (int i = 0; i < whole.length; i++) {
      final reverseIndex = whole.length - i;
      buffer.write(whole[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write('.');
      }
    }
    return 'Rp $buffer';
    final v = _toDouble(value);
    return 'Rp ${_currencyFormat.format(v)}';
  }

  String _fmtDate(dynamic value) {
    final text = (value ?? '').toString();
    if (text.isEmpty) return '';
    try {
      final dt = DateTime.tryParse(text);
      if (dt == null) return text;
      return DateFormat('dd-MMM-yy').format(dt);
    } catch (_) {
      return text;
    }
      return dt == null ? text : DateFormat('dd-MMM-yy').format(dt);
    } catch (_) { return text; }
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
    if (m == null) return null;
    return int.tryParse(m.group(1) ?? '');
    final m = RegExp(r'Imported from row\s+(\d+)', caseSensitive: false).firstMatch(raw);
    return m == null ? null : int.tryParse(m.group(1) ?? '');
  }

  int _extractBatchNumber(String text) {
    final match = RegExp(
      r'\bbatch\s*#?\s*(\d+)\b',
      caseSensitive: false,
    ).firstMatch(text);
    if (match == null) return 1 << 30;
    return int.tryParse(match.group(1) ?? '') ?? (1 << 30);
    final match = RegExp(r'\bbatch\s*#?\s*(\d+)\b', caseSensitive: false).firstMatch(text);
    return match == null ? (1 << 30) : (int.tryParse(match.group(1) ?? '') ?? (1 << 30));
  }

  bool _isBatchSettlement(Map<String, dynamic> item) {
    final stype = (item['settlement_type'] ?? '')
        .toString()
        .toLowerCase()
        .trim();
    final stype = (item['settlement_type'] ?? '').toString().toLowerCase().trim();
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
    text = text.trim();
    return text.isEmpty ? 'Tanpa Settlement' : text;
    text = text.replaceFirst(RegExp(r'^\s*single\s*[-:]\s*', caseSensitive: false), '');
    text = text.replaceFirst(RegExp(r'^\s*batch\s*#?\s*\d+\s*[-:]\s*', caseSensitive: false), '');
    text = text.replaceFirst(RegExp(r'^\s*batch\s*[-:]\s*', caseSensitive: false), '');
    return text.trim().isEmpty ? 'Tanpa Settlement' : text.trim();
  }

  String _extractNoteSubcategory(Map<String, dynamic> item) {
    final notes = (item['notes'] ?? '').toString().trim();
    if (notes.isEmpty) return '';
    final match = RegExp(
      r'\bSubcategory:\s*([^|]+)',
      caseSensitive: false,
    ).firstMatch(notes);
    final match = RegExp(r'\bSubcategory:\s*([^|]+)', caseSensitive: false).firstMatch(notes);
    return match?.group(1)?.trim() ?? '';
  }

  int _subcategorySortBucket(String label) {
    final text = label.trim();
    if (text.isEmpty || text == '-') return 1;
    return 0;
    return (text.isEmpty || text == '-') ? 1 : 0;
  }

  List<List<Map<String, dynamic>>> _groupAnnualExpenses(
    List<Map<String, dynamic>> expenses,
  ) {
  List<List<Map<String, dynamic>>> _groupAnnualExpenses(List<Map<String, dynamic>> expenses) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final e in expenses) {
      final sid = (e['settlement_id'] ?? '').toString();
      final key = sid.isNotEmpty
          ? 'id:$sid'
          : 'title:${(e['settlement_title'] ?? '').toString()}';
      final key = sid.isNotEmpty ? 'id:$sid' : 'title:${(e['settlement_title'] ?? '').toString()}';
      grouped.putIfAbsent(key, () => <Map<String, dynamic>>[]).add(e);
    }

    final groups = grouped.values.toList();
    for (final g in groups) {
      g.sort((a, b) {
        final aSub = _expenseSubcategoryLabel(a).toLowerCase();
        final bSub = _expenseSubcategoryLabel(b).toLowerCase();
        final bucketCmp = _subcategorySortBucket(
          _expenseSubcategoryLabel(a),
        ).compareTo(_subcategorySortBucket(_expenseSubcategoryLabel(b)));
        final bucketCmp = _subcategorySortBucket(aSub).compareTo(_subcategorySortBucket(bSub));
        if (bucketCmp != 0) return bucketCmp;
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
        final dateCmp = da.compareTo(db);
        if (dateCmp != 0) return dateCmp;
        final aid = int.tryParse((a['id'] ?? '0').toString()) ?? 0;
        final bid = int.tryParse((b['id'] ?? '0').toString()) ?? 0;
        return aid.compareTo(bid);
        return (int.tryParse((a['id'] ?? '0').toString()) ?? 0).compareTo(int.tryParse((b['id'] ?? '0').toString()) ?? 0);
      });
    }

    groups.sort((a, b) {
      final af = a.first;
      final bf = b.first;
      final aSub = _expenseSubcategoryLabel(af);
      final bSub = _expenseSubcategoryLabel(bf);
      final subBucketCmp = _subcategorySortBucket(aSub).compareTo(
        _subcategorySortBucket(bSub),
      );
      final af = a.first; final bf = b.first;
      final aSub = _expenseSubcategoryLabel(af); final bSub = _expenseSubcategoryLabel(bf);
      final subBucketCmp = _subcategorySortBucket(aSub).compareTo(_subcategorySortBucket(bSub));
      if (subBucketCmp != 0) return subBucketCmp;
      final aSubLower = aSub.toLowerCase();
      final bSubLower = bSub.toLowerCase();
      if (aSubLower != bSubLower) return aSubLower.compareTo(bSubLower);

      final aBatch = _isBatchSettlement(af);
      final bBatch = _isBatchSettlement(bf);
      if (aSub.toLowerCase() != bSub.toLowerCase()) return aSub.toLowerCase().compareTo(bSub.toLowerCase());
      final aBatch = _isBatchSettlement(af); final bBatch = _isBatchSettlement(bf);
      if (aBatch != bBatch) return aBatch ? 1 : -1;

      final aDate = a
          .map((x) => _parseDate(x['date']))
          .reduce((x, y) => x.isBefore(y) ? x : y);
      final bDate = b
          .map((x) => _parseDate(x['date']))
          .reduce((x, y) => x.isBefore(y) ? x : y);
      final aId = int.tryParse((af['settlement_id'] ?? '0').toString()) ?? 0;
      final bId = int.tryParse((bf['settlement_id'] ?? '0').toString()) ?? 0;

      final aDate = a.map((x) => _parseDate(x['date'])).reduce((x, y) => x.isBefore(y) ? x : y);
      final bDate = b.map((x) => _parseDate(x['date'])).reduce((x, y) => x.isBefore(y) ? x : y);
      if (aBatch && bBatch) {
        final aNum = _extractBatchNumber(
          (af['settlement_title'] ?? '').toString(),
        );
        final bNum = _extractBatchNumber(
          (bf['settlement_title'] ?? '').toString(),
        );
        final aNum = _extractBatchNumber((af['settlement_title'] ?? '').toString());
        final bNum = _extractBatchNumber((bf['settlement_title'] ?? '').toString());
        if (aNum != bNum) return aNum.compareTo(bNum);

        if (aId != bId) return aId.compareTo(bId);
        return aDate.compareTo(bDate);
      } else {
        final dateCmp = aDate.compareTo(bDate);
        if (dateCmp != 0) return dateCmp;
        return aId.compareTo(bId);
      }
      final dateCmp = aDate.compareTo(bDate);
      return dateCmp != 0 ? dateCmp : (int.tryParse((af['settlement_id'] ?? '0').toString()) ?? 0).compareTo(int.tryParse((bf['settlement_id'] ?? '0').toString()) ?? 0);
    });

    return groups;
  }

  int _expenseCategoryIndex(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('operasi') ||
        name.contains('operasional') ||
        name.contains('gaji') ||
        name.contains('transport') ||
        name.contains('meal') ||
        name.contains('hotel') ||
        name.contains('laundry')) {
      return 0;
    }
    if (name.contains('research') ||
        name.contains('riset') ||
        name.contains('r&d')) {
      return 1;
    }
    if (name.contains('peralatan') ||
        name.contains('rental') ||
        name.contains('alat')) {
      return 2;
    }
    if (name.contains('interpretasi') ||
        name.contains('log data') ||
        name.contains('teknologi')) {
      return 3;
    }
    if (name.contains('administrasi') ||
        name.contains('keuangan') ||
        name.contains('legal')) {
      return 4;
    }
    if (name.contains('pembelian') ||
        name.contains('barang') ||
        name.contains('logistik')) {
      return 5;
    }
    if (name.contains('kantor') || name.contains('sewa')) {
      return 6;
    }
    if (name.contains('kesehatan') || name.contains('medical')) {
      return 7;
    }
    if (name.contains('bisnis') ||
        name.contains('marketing') ||
        name.contains('hiburan')) {
      return 8;
    }
    return 0;
  }

  int _getCategoryIndexFromDynamic(String categoryName) {
    // Jika kategori belum di-fetch, gunakan fallback hardcoded
    if (_categories.isEmpty) {
      return _expenseCategoryIndex(categoryName);
    }
    // Cari kategori yang match dengan name
    final targetName = categoryName.toLowerCase().trim();
    for (int i = 0; i < _categories.length; i++) {
      final catName = (_categories[i]['name'] ?? '').toString().toLowerCase();
      // Check if category name matches or contains keywords
      if (catName == targetName || catName.contains(targetName) || targetName.contains(catName)) {
        return i;
      }
      if (catName == targetName || catName.contains(targetName) || targetName.contains(catName)) return i;
    }
    // Fallback: cari berdasarkan keyword matching seperti _expenseCategoryIndex
    return _expenseCategoryIndex(categoryName);
    return 0;
  }

  String _expenseSubcategoryLabel(Map<String, dynamic> item) {
    // ✅ FIX: Prioritaskan label dari backend karena sudah diformat dengan suffix (A, B, dll)
    final backendSub = (item['subcategory_name'] ?? '').toString().trim();
    if (backendSub.isNotEmpty && backendSub != '-') {
      return backendSub;
    }

    if (backendSub.isNotEmpty && backendSub != '-') return backendSub;
    final rawDesc = (item['description'] ?? '').toString();
    final extracted = RegExp(r'^\[(.*?)\]\s*(.*)$').firstMatch(rawDesc);
    final prefixed = extracted?.group(1)?.trim() ?? '';
    if (prefixed.isNotEmpty) return prefixed;

    final noteSubcategory = _extractNoteSubcategory(item);
    if (noteSubcategory.isNotEmpty) return noteSubcategory;

    final desc = rawDesc.toLowerCase();
    if (desc.contains('rental tool')) return 'Rental Tool';
    if (desc.contains('sales')) return 'Sales';
    if (desc.contains('gaji') || desc.contains('bonus')) return 'Gaji';
    if (desc.contains('pembuatan alat') || desc.contains('mesin retort')) {
      return 'Pembuatan Alat';
    }
    if (desc.contains('thr') || desc.contains('allowance')) return 'Allowance';
    if (desc.contains('data processing')) return 'Data Processing';
    if (desc.contains('moving slickline') || desc.contains('project lampu')) {
      return 'Project Operation';
    }
    if (desc.contains('sampling tool') ||
        desc.contains('sparepart') ||
        desc.contains('ups biaya import')) {
      return 'Sparepart';
    }
    if (desc.contains('repair esor')) return 'Maintenance';
    if (desc.contains('licence') || desc.contains('license')) {
      return 'Software License';
    }
    if (desc.contains('handphone operational')) return 'Operation';
    if (desc.contains('sewa ruangan') || desc.contains('virtual office')) {
      return 'Sewa Ruangan';
    }
    if (desc.contains('modal kerja')) return 'Modal Kerja';
    if (desc.contains('team building')) return 'Team Building';
    if (desc.contains('biaya transaksi bank')) return 'Biaya Bank';
    if (extracted?.group(1) != null) return extracted!.group(1)!.trim();
    final noteSub = _extractNoteSubcategory(item);
    if (noteSub.isNotEmpty) return noteSub;
    return backendSub;
  }
  bool _isNumericHeader(String header) {
    final h = header.toLowerCase().trim();
    return h.contains('value') ||
        h.contains('amount') ||
        h.contains('rate') ||
        h.contains('ppn') ||
        h.contains('pph') ||
        h.contains('fee') ||
        h.contains('total') ||
        h.contains('jumlah') ||
        h.contains('nilai') ||
        h.contains('biaya') ||
        h.contains('received');
  }

  bool _isCenterColumn(String header, int index) {
    final h = header.toLowerCase().trim();
    return index == 0 || h == '#' || h == 'no';
  }

  Alignment _columnAlignment(String header, int index) {
    if (_isCenterColumn(header, index)) return Alignment.center;
    if (_isNumericHeader(header)) return Alignment.centerRight;
    return Alignment.centerLeft;
  }

  Widget _buildTableCard({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
    Set<int> boldRows = const {},
  }) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        color: _cardColor(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: _titleColor(context),
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _dividerColor(context).withValues(alpha: 0.8),
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      _surfaceColor(context),
                    ),
                    dataRowMinHeight: 40,
                    dataRowMaxHeight: 48,
                    columns: headers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final h = entry.value;
                      final align = _columnAlignment(h, index);
                      return DataColumn(
                        numeric:
                            !_isCenterColumn(h, index) && _isNumericHeader(h),
                        label: Align(
                          alignment: align,
                          child: Text(
                            h,
                            style: TextStyle(
                              color: _titleColor(context),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    rows: rows.asMap().entries.map((rowEntry) {
                      final rowIdx = rowEntry.key;
                      final row = rowEntry.value;
                      final isBold = boldRows.contains(rowIdx);
                      final normalized = List<String>.from(row);
                      while (normalized.length < headers.length) {
                        normalized.add('');
                      }
                      return DataRow(
                        cells: normalized.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final value = entry.value;
                          final align = _columnAlignment(headers[idx], idx);
                          return DataCell(
                            Align(
                              alignment: align,
                              child: Text(
                                value,
                                style: TextStyle(
                                  color: isBold
                                      ? _titleColor(context)
                                      : _bodyColor(context),
                                  fontWeight: isBold
                                      ? FontWeight.w700
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    }).toList(),
                  ),
  Widget _buildTableCard({required String title, required List<String> headers, required List<List<String>> rows, Set<int> boldRows = const {}, bool useCompact = false}) {
    return Card(
      color: _cardColor(context),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(useCompact ? 10 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: _titleColor(context), fontWeight: FontWeight.bold, fontSize: useCompact ? 14 : 15)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(border: Border.all(color: _dividerColor(context).withValues(alpha: 0.5)), borderRadius: BorderRadius.circular(8)),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(_surfaceColor(context)),
                  headingRowHeight: useCompact ? 40 : 56,
                  dataRowMinHeight: useCompact ? 32 : 48,
                  columnSpacing: useCompact ? 12 : 24,
                  horizontalMargin: useCompact ? 8 : 16,
                  columns: headers.map((h) => DataColumn(label: Text(h, style: TextStyle(fontWeight: FontWeight.bold, fontSize: useCompact ? 12 : 14)))).toList(),
                  rows: rows.asMap().entries.map((entry) {
                    final isBold = boldRows.contains(entry.key);
                    return DataRow(cells: entry.value.map((cell) => DataCell(Text(cell, style: TextStyle(fontSize: useCompact ? 11 : 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: isBold ? _titleColor(context) : _primaryText(context))))).toList());
                  }).toList(),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 2,
                width: double.infinity,
                color: _dividerColor(context).withValues(alpha: 0.6),
              ),
            ],
          ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCacheInfo() {
  Widget _buildCacheInfo(bool useCompact) {
    final source = (_reportData?['cache_source'] ?? '').toString();
    final generated =
        (_reportData?['cache_generated_at'] ??
                _reportData?['generated_at'] ??
                '')
            .toString();
    String sourceLabel = 'N/A';
    if (source == 'cache') sourceLabel = 'CACHE (tidak hit DB)';
    if (source == 'refresh') sourceLabel = 'REFRESH (DB terbaru)';
    if (source == 'bootstrap') sourceLabel = 'INIT CACHE';

    final generated = (_reportData?['cache_generated_at'] ?? _reportData?['generated_at'] ?? '').toString();
    String label = (source == 'cache') ? 'CACHE (tidak hit DB)' : (source == 'refresh' ? 'REFRESH (DB terbaru)' : 'INIT');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _surfaceColor(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _dividerColor(context)),
      ),
      child: Text(
        'Display Source: $sourceLabel | Generated: ${_fmtDate(generated)} ${generated.length > 10 ? generated.substring(11, 19) : ''}',
        style: TextStyle(color: _bodyColor(context), fontSize: 12),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: useCompact ? 8 : 10),
      decoration: BoxDecoration(color: _surfaceColor(context), borderRadius: BorderRadius.circular(10), border: Border.all(color: _dividerColor(context))),
      child: Text('Display Source: $label | Generated: ${_fmtDate(generated)}', style: TextStyle(color: _bodyColor(context), fontSize: useCompact ? 10 : 12)),
    );
  }

  Widget _buildInputButtons() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ElevatedButton.icon(
          onPressed: _isLoading
              ? null
              : () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          RevenueManagementScreen(initialYear: _selectedYear),
                    ),
                  );
                  if (!mounted) return;
                  await _fetchReport();
                },
          icon: const Icon(Icons.receipt_long_rounded, size: 18),
          label: const Text('Input Revenue'),
        ),
        ElevatedButton.icon(
          onPressed: _isLoading
              ? null
              : () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          TaxManagementScreen(initialYear: _selectedYear),
                    ),
                  );
                  if (!mounted) return;
                  await _fetchReport();
                },
          icon: const Icon(Icons.account_balance_rounded, size: 18),
          label: const Text('Input Pajak'),
        ),
        ElevatedButton.icon(
          onPressed: _isLoading
              ? null
              : () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          DividendManagementScreen(initialYear: _selectedYear),
                    ),
                  );
                  if (!mounted) return;
                  await _fetchReport();
                },
          icon: const Icon(Icons.wallet_rounded, size: 18),
          label: const Text('Input Dividen'),
        ),
        ElevatedButton.icon(
          onPressed: _isLoading
              ? null
              : () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BalanceSheetSettingsScreen(
                        initialYear: _selectedYear,
                      ),
                    ),
                  );
                  if (!mounted) return;
                  await _fetchReport();
                },
          icon: const Icon(Icons.assessment_outlined, size: 18),
          label: const Text('Input Neraca'),
        ),
      ],
    );
  }

  Widget _buildDisplayTables() {
  Widget _buildDisplayTables(bool useCompact) {
    final revenueData = _asListMap(_reportData?['revenue']?['data']);
    final taxData = _asListMap(_reportData?['tax']?['data']);
    final dividendData = _asListMap(_reportData?['dividend']?['data']);
    final expenseData = _asListMap(_reportData?['operation_cost']?['data']);

    final revenueRows = <List<String>>[];
    for (int i = 0; i < revenueData.length; i++) {
      final r = revenueData[i];
      revenueRows.add([
        _fmtDate(r['invoice_date']),
        '${i + 1}',
        (r['description'] ?? '').toString(),
        _fmtMoney(r['invoice_value']),
        (r['currency'] ?? 'IDR').toString(),
        _fmtNumber(r['currency_exchange'] ?? 1, decimals: 0),
        (r['invoice_number'] ?? '').toString(),
        (r['client'] ?? '').toString(),
        _fmtDate(r['receive_date']),
        _fmtMoney(r['amount_received']),
        _fmtMoney(r['ppn']),
        _fmtMoney(r['pph_23']),
        _fmtMoney(r['transfer_fee']),
        (r['remark'] ?? '').toString(),
      ]);
    }
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

    final taxRows = <List<String>>[];
    for (int i = 0; i < taxData.length; i++) {
      final t = taxData[i];
      final val = _toDouble(t['transaction_value']);
      taxRows.add([
        _fmtDate(t['date']),
        '${i + 1}',
        (t['description'] ?? '').toString(),
        _fmtMoney(val),
        (t['currency'] ?? 'IDR').toString(),
        _fmtNumber(t['currency_exchange'] ?? 1, decimals: 0),
        _toDouble(t['ppn']) > 0 ? _fmtMoney(val) : '0',
        _fmtMoney(t['ppn']),
        _toDouble(t['pph_21']) > 0 ? _fmtMoney(val) : '0',
        _fmtMoney(t['pph_21']),
        _toDouble(t['pph_23']) > 0 ? _fmtMoney(val) : '0',
        _fmtMoney(t['pph_23']),
        _toDouble(t['pph_26']) > 0 ? _fmtMoney(val) : '0',
        _fmtMoney(t['pph_26']),
      ]);
    }
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

    final dividendRows = <List<String>>[];
    for (int i = 0; i < dividendData.length; i++) {
      final d = dividendData[i];
      dividendRows.add([
        _fmtDate(d['date']),
        '${i + 1}',
        (d['name'] ?? '-').toString(),
        _fmtMoney(_reportData?['dividend']?['profit_retained'] ?? 0),
        _fmtMoney(_reportData?['dividend']?['total_amount'] ?? 0),
        _fmtMoney(_reportData?['dividend']?['dividend_per_person'] ?? 0),
      ]);
    }
    dividendRows.add([
      'TOTAL',
      '',
      '',
    final List<List<String>> revenueRows = revenueData.asMap().entries.map((e) => [
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
      e.value['remark']?.toString() ?? ''
    ]).toList();
    revenueRows.add(['TOTAL', '', '', _fmtMoney(_reportData?['revenue']?['total_amount_received'] ?? 0), '', '', '', '', '', _fmtMoney(_reportData?['revenue']?['total_amount_received'] ?? 0), _fmtMoney(_reportData?['revenue']?['total_ppn'] ?? 0), _fmtMoney(_reportData?['revenue']?['total_pph23'] ?? 0), '', '']);

    final List<List<String>> taxRows = taxData.asMap().entries.map((e) => [
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
      _fmtMoney(e.value['pph_26'])
    ]).toList();
    taxRows.add(['TOTAL', '', '', '', '', '', '', _fmtMoney(_reportData?['tax']?['total_ppn'] ?? 0), '', _fmtMoney(_reportData?['tax']?['total_pph21'] ?? 0), '', _fmtMoney(_reportData?['tax']?['total_pph23'] ?? 0), '', _fmtMoney(_reportData?['tax']?['total_pph26'] ?? 0)]);

    final List<List<String>> dividendRows = dividendData.asMap().entries.map((e) => [
      _fmtDate(e.value['date']),
      '${e.key + 1}',
      e.value['name']?.toString() ?? '-',
      _fmtMoney(_reportData?['dividend']?['profit_retained'] ?? 0),
      _fmtMoney(_reportData?['dividend']?['total_amount'] ?? 0),
      _fmtMoney(_reportData?['dividend']?['dividend_per_person'] ?? 0),
    ]);
      _fmtMoney(_reportData?['dividend']?['dividend_per_person'] ?? 0)
    ]).toList();
    dividendRows.add(['TOTAL', '', '', _fmtMoney(_reportData?['dividend']?['profit_retained'] ?? 0), _fmtMoney(_reportData?['dividend']?['total_amount'] ?? 0), _fmtMoney(_reportData?['dividend']?['dividend_per_person'] ?? 0)]);

    // Gunakan kategori dinamis dari API (urut sesuai Kategori Tabular)
    // Fallback ke hardcoded jika kategori belum di-fetch
    final catHeaders = _categories.isNotEmpty
        ? _categories.map((c) => (c['name'] ?? '').toString()).toList()
        : [
            'Biaya Operasi',
            'Research',
            'Sewa Alat',
            'Interpretasi',
            'Administrasi',
            'Pembelian',
            'Sewa Kantor',
            'Kesehatan',
            'Bisnis Dev',
          ];
    final catHeaders = _categories.isNotEmpty ? _categories.map((c) => (c['name'] ?? '').toString()).toList() : ['Expenses'];
    final catTotals = List<double>.filled(catHeaders.length, 0);
    final expenseRows = <List<String>>[];
    final List<List<String>> expenseRows = <List<String>>[];
    final expenseBoldRows = <int>{};
    final expenseGroups = _groupAnnualExpenses(expenseData);
    int singleCounter = 0;

    final singleGroupsBySubcategory = <String, List<Map<String, dynamic>>>{};
    final uncategorizedSingles = <Map<String, dynamic>>[];
    for (int g = 0; g < expenseGroups.length; g++) {
      final group = expenseGroups[g];
      if (_isBatchSettlement(group.first)) continue;
      for (final e in group) {
        final subcategory = _expenseSubcategoryLabel(e);
        if (subcategory.isEmpty) {
          uncategorizedSingles.add(e);
        } else {
          singleGroupsBySubcategory.putIfAbsent(subcategory, () => []).add(e);
        }
      }
    }
    final orderedSingleSubcategories = singleGroupsBySubcategory.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    for (final subcategory in orderedSingleSubcategories) {
      expenseBoldRows.add(expenseRows.length);
      expenseRows.add([
        '',
        '',
        subcategory,
        '',
        '',
        '',
        '',
        ...List<String>.filled(catHeaders.length, ''),
      ]);
      final groupItems = singleGroupsBySubcategory[subcategory] ?? const [];
      for (final e in groupItems) {
        final rawDesc = (e['description'] ?? '').toString();
        final cleanDesc = rawDesc.replaceFirst(RegExp(r'^\[.*?\]\s*'), '');
        final rowCats = List<String>.filled(catHeaders.length, '-');
        final amount = _toDouble(e['idr_amount'] ?? e['amount']);
        final idx = _getCategoryIndexFromDynamic(
          (e['category_name'] ?? '').toString(),
        );
        rowCats[idx] = _fmtMoney(amount);
        catTotals[idx] += amount;
        singleCounter++;
        expenseRows.add([
          _fmtDate(e['date']),
          '$singleCounter',
          cleanDesc,
          (e['source'] ?? '').toString(),
          _fmtMoney(amount),
          (e['currency'] ?? 'IDR').toString(),
          _fmtNumber(e['currency_exchange'] ?? 1, decimals: 0),
          ...rowCats,
        ]);
      }
    }

    for (final e in uncategorizedSingles) {
      final rawDesc = (e['description'] ?? '').toString();
      final cleanDesc = rawDesc.replaceFirst(RegExp(r'^\[.*?\]\s*'), '');
      final rowCats = List<String>.filled(catHeaders.length, '-');
      final amount = _toDouble(e['idr_amount'] ?? e['amount']);
      final idx = _getCategoryIndexFromDynamic((e['category_name'] ?? '').toString());
      rowCats[idx] = _fmtMoney(amount);
      catTotals[idx] += amount;
      singleCounter++;
      expenseRows.add([
        _fmtDate(e['date']),
        '$singleCounter',
        cleanDesc,
        (e['source'] ?? '').toString(),
        _fmtMoney(amount),
        (e['currency'] ?? 'IDR').toString(),
        _fmtNumber(e['currency_exchange'] ?? 1, decimals: 0),
        ...rowCats,
      ]);
    }

    // grup batch
    int batchCounter = 0;
    for (int g = 0; g < expenseGroups.length; g++) {
      final group = expenseGroups[g];
      final isBatch = _isBatchSettlement(group.first);
      if (!isBatch) continue;

      batchCounter++;
      final batchTitle = _cleanSettlementTitle(
        (group.first['settlement_title'] ?? '').toString(),
      );
    int itemCounter = 0;
    for (final group in expenseGroups) {
      expenseBoldRows.add(expenseRows.length);
      expenseRows.add([
        'Expense#$batchCounter',
        ':',
        batchTitle,
        '',
        '',
        '',
        '',
        ...List<String>.filled(catHeaders.length, ''),
      ]);

      // Kelompokkan item dalam batch berdasarkan sub-kategori
      final batchGroupsBySubcategory = <String, List<Map<String, dynamic>>>{};
      final batchUncategorized = <Map<String, dynamic>>[];
      expenseRows.add(['', '', _cleanSettlementTitle(group.first['settlement_title'] ?? ''), '', '', '', '', ...List.filled(catHeaders.length, '')]);
      for (final e in group) {
        final subcategory = _expenseSubcategoryLabel(e).trim();
        if (subcategory.isEmpty) {
          batchUncategorized.add(e);
        } else {
          batchGroupsBySubcategory.putIfAbsent(subcategory, () => []).add(e);
        }
      }
      // Urutkan sub-kategori secara alfabetis A-Z
      final orderedBatchSubcategories = batchGroupsBySubcategory.keys.toList()
        ..sort((a, b) {
          final bucketCmp = _subcategorySortBucket(a).compareTo(
            _subcategorySortBucket(b),
          );
          if (bucketCmp != 0) return bucketCmp;
          return a.toLowerCase().compareTo(b.toLowerCase());
        });

      int itemIndex = 0;

      // Tampilkan item per sub-kategori yang sudah diurutkan
      for (final subcategory in orderedBatchSubcategories) {
        expenseBoldRows.add(expenseRows.length);
        expenseRows.add([
          '', // Date
          '', // #
          subcategory, // Activity
          '', // Source
          '', // Jumlah
          '', // Curr
          '', // Rate
          ...List<String>.filled(catHeaders.length, ''),
        ]);
        final groupItems = batchGroupsBySubcategory[subcategory] ?? const [];
        // Urutkan item dalam sub-kategori berdasarkan imported row lalu tanggal
        final sortedItems = List<Map<String, dynamic>>.from(groupItems)
          ..sort((a, b) {
            final aImported = _extractImportedRow(a['notes']);
            final bImported = _extractImportedRow(b['notes']);
            if (aImported != null || bImported != null) {
              final ai = aImported ?? (1 << 30);
              final bi = bImported ?? (1 << 30);
              if (ai != bi) return ai.compareTo(bi);
            }
            final da = _parseDate(a['date']);
            final db = _parseDate(b['date']);
            final dateCmp = da.compareTo(db);
            if (dateCmp != 0) return dateCmp;
            final aid = int.tryParse((a['id'] ?? '0').toString()) ?? 0;
            final bid = int.tryParse((b['id'] ?? '0').toString()) ?? 0;
            return aid.compareTo(bid);
          });
        for (final e in sortedItems) {
          itemIndex++;
          final rawDesc = (e['description'] ?? '').toString();
          // Hapus prefix [subcategory] jika ada
          final cleanDesc = rawDesc.replaceFirst(RegExp(r'^\[.*?\]\s*'), '');
          final rowCats = List<String>.filled(catHeaders.length, '-');
          final amount = _toDouble(e['idr_amount'] ?? e['amount']);
          final idx = _getCategoryIndexFromDynamic(
            (e['category_name'] ?? '').toString(),
          );
          rowCats[idx] = _fmtMoney(amount);
          catTotals[idx] += amount;
          expenseRows.add([
            _fmtDate(e['date']),
            '$itemIndex',
            cleanDesc,
            (e['source'] ?? '').toString(),
            _fmtMoney(amount),
            (e['currency'] ?? 'IDR').toString(),
            _fmtNumber(e['currency_exchange'] ?? 1, decimals: 0),
            ...rowCats,
          ]);
        }
      }

      // Tampilkan item tanpa sub-kategori (jika ada)
      for (final e in batchUncategorized) {
        itemIndex++;
        final rawDesc = (e['description'] ?? '').toString();
        final cleanDesc = rawDesc.replaceFirst(RegExp(r'^\[.*?\]\s*'), '');
        final rowCats = List<String>.filled(catHeaders.length, '-');
        itemCounter++;
        final amount = _toDouble(e['idr_amount'] ?? e['amount']);
        final idx = _getCategoryIndexFromDynamic((e['category_name'] ?? '').toString());
        rowCats[idx] = _fmtMoney(amount);
        catTotals[idx] += amount;
        expenseRows.add([
          _fmtDate(e['date']),
          '$itemIndex',
          cleanDesc,
          (e['source'] ?? '').toString(),
          _fmtMoney(amount),
          (e['currency'] ?? 'IDR').toString(),
          _fmtNumber(e['currency_exchange'] ?? 1, decimals: 0),
          ...rowCats,
        ]);
        final idx = _getCategoryIndexFromDynamic(e['category_name'] ?? '');
        final rowCats = List<String>.filled(catHeaders.length, '-');
        if (idx < catHeaders.length) { rowCats[idx] = _fmtMoney(amount); catTotals[idx] += amount; }
        expenseRows.add([_fmtDate(e['date']), '$itemCounter', e['description']?.toString() ?? '', e['source']?.toString() ?? '', _fmtMoney(amount), e['currency']?.toString() ?? 'IDR', _toDouble(e['currency_exchange'] ?? 1).toStringAsFixed(0), ...rowCats]);
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
    expenseRows.add(['TOTAL', '', '', '', _fmtMoney(_reportData?['operation_cost']?['total_expenses'] ?? 0), '', '', ...catTotals.map(_fmtMoney)]);

    final settings = (_reportData?['dividend']?['settings'] as Map?) ?? <String, dynamic>{};
    final neracaRows = <List<String>>[
      ['Kas Tahun Sebelumnya', _fmtMoney(settings['opening_cash_balance'] ?? 0)],
    final settings = (_reportData?['dividend']?['settings'] as Map?) ?? {};
    final List<List<String>> neracaRows = [
      ['Kas Sebelumnya', _fmtMoney(settings['opening_cash_balance'] ?? 0)],
      ['Piutang Usaha', _fmtMoney(settings['accounts_receivable'] ?? 0)],
      ['Pajak Bayar di Muka (pph23)', _fmtMoney(settings['prepaid_tax_pph23'] ?? 0)],
      ['Biaya Bayar di Muka', _fmtMoney(settings['prepaid_expenses'] ?? 0)],
      ['Piutang Lain Lain', _fmtMoney(settings['other_receivables'] ?? 0)],
      ['Inventaris Kantor', _fmtMoney(settings['office_inventory'] ?? 0)],
      ['Aktiva Lain Lain', _fmtMoney(settings['other_assets'] ?? 0)],
      ['Pajak di Muka', _fmtMoney(settings['prepaid_tax_pph23'] ?? 0)],
      ['Hutang Usaha', _fmtMoney(settings['accounts_payable'] ?? 0)],
      ['Hutang Gaji', _fmtMoney(settings['salary_payable'] ?? 0)],
      ['Hutang Pemegang Saham', _fmtMoney(settings['shareholder_payable'] ?? 0)],
      ['Biaya Masih Harus Dibayar', _fmtMoney(settings['accrued_expenses'] ?? 0)],
      ['Modal Saham', _fmtMoney(settings['share_capital'] ?? 0)],
      ['Laba Ditahan Awal', _fmtMoney(settings['retained_earnings_balance'] ?? 0)],
      ['Modal Saham', _fmtMoney(settings['share_capital'] ?? 0)]
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTableCard(
          title: 'Tabel 1: REVENUE & TAX',
          headers: const [
            'Invoice Date',
            '#',
            'Description',
            'Invoice Value',
            'Curr',
            'Rate',
            'Invoice No',
            'Client',
            'Receive Date',
            'Amt Received',
            'PPN',
            'PPH 23',
            'Transfer Fee',
            'Remark',
          ],
          rows: revenueRows,
        ),
        const SizedBox(height: 12),
        _buildTableCard(
          title: 'Tabel 2: PAJAK PENGELUARAN',
          headers: const [
            'Date',
            '#',
            'Description',
            'Trans Value',
            'Curr',
            'Rate',
            'DPP PPN',
            'PPN',
            'DPP PPH 21',
            'PPH 21',
            'DPP PPH 23',
            'PPH 23',
            'DPP PPH 26',
            'PPH 26',
          ],
          rows: taxRows,
        ),
        const SizedBox(height: 12),
        _buildTableCard(
          title: 'Tabel 3: DIVIDEN',
          headers: const [
            'Date',
            '#',
            'Nama Penerima',
            'Profit Ditahan',
            'Dividen Dibagi',
            'Dibagi per Orang',
          ],
          rows: dividendRows,
        ),
        const SizedBox(height: 12),
        _buildTableCard(
          title: 'Tabel 4: PENGELUARAN & OPERATION COST',
          headers: [
            'Date',
            '#',
            'Activity',
            'Source',
            'Jumlah',
            'Curr',
            'Rate',
            ...catHeaders,
          ],
          rows: expenseRows,
          boldRows: expenseBoldRows,
        ),
        const SizedBox(height: 12),
        _buildTableCard(
          title: 'Tabel 5: NERACA',
          headers: const ['Parameter', 'Nilai'],
          rows: neracaRows,
        ),
      ],
    );
    return Column(children: [
      _buildTableCard(title: 'Tabel 1: REVENUE & TAX', headers: const ['Date', '#', 'Desc', 'Value', 'Curr', 'Rate', 'Inv No', 'Client', 'Rec Date', 'Amt', 'PPN', 'PPH23', 'Fee', 'Rem'], rows: revenueRows, useCompact: useCompact),
      _buildTableCard(title: 'Tabel 2: PAJAK', headers: const ['Date', '#', 'Desc', 'Val', 'Cur', 'Rate', 'DPP1', 'PPN', 'DPP2', 'PPH21', 'DPP3', 'PPH23', 'DPP4', 'PPH26'], rows: taxRows, useCompact: useCompact),
      _buildTableCard(title: 'Tabel 3: DIVIDEN', headers: const ['Date', '#', 'Nama', 'Profit', 'Dividen', 'Per Person'], rows: dividendRows, useCompact: useCompact),
      _buildTableCard(title: 'Tabel 4: OPERATION COST', headers: ['Date', '#', 'Activity', 'Src', 'Amt', 'Cur', 'Rate', ...catHeaders], rows: expenseRows, boldRows: expenseBoldRows, useCompact: useCompact),
      _buildTableCard(title: 'Tabel 5: NERACA', headers: const ['Parameter', 'Nilai'], rows: neracaRows, useCompact: useCompact)
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final useCompact = screenWidth < 550;

    return Scaffold(
      backgroundColor: _surfaceColor(context),
      appBar: AppBar(
        titleSpacing: isMobile ? 8 : null,
        title: Text(
          isMobile ? 'Lap. Tahunan' : 'Laporan Tahunan',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 16 : 18),
        ),
        title: Text(useCompact ? 'Lap. Tahunan' : 'Laporan Tahunan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: useCompact ? 17 : 18)),
        backgroundColor: _cardColor(context),
        actions: [
          DropdownButtonHideUnderline(
              value: _selectedYear,
              dropdownColor: _cardColor(context),
              style: TextStyle(color: _titleColor(context), fontSize: 13, fontWeight: FontWeight.w600),
              items: {
                ...List.generate(21, (index) => 2020 + index),
                _selectedYear
              }.where((y) => y != 0).map((y) => DropdownMenuItem(
                        value: y,
                        child: Text(isMobile ? '$y' : 'Laporan $y'),
                      )).toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedYear = value);
                _fetchReport();
              },
              style: TextStyle(color: _titleColor(context), fontSize: 13, fontWeight: FontWeight.bold),
              items: { ...List.generate(21, (i) => 2020 + i), _selectedYear }.where((y) => y != 0).toSet().map((y) => DropdownMenuItem(value: y, child: Text(useCompact ? '$y' : 'Laporan $y'))).toList(),
              onChanged: (v) { if (v != null) { setState(() => _selectedYear = v); _fetchReport(); } },
            ),
          ),

          // Button Kategori Tabular - Icon only on mobile
          IconButton(
            onPressed: _isLoading
                ? null
                : () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CategoryTabularScreen()),
                    );
                    if (mounted) { _fetchCategories(); _fetchReport(); }
                  },
            icon: const Icon(Icons.sort, size: 22, color: AppTheme.primary),
            tooltip: 'Kategori Tabular',
            visualDensity: isMobile ? VisualDensity.compact : null,
          ),

          if (!isMobile) const SizedBox(width: 4),

          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 22),
            tooltip: 'Export PDF',
            onPressed: _isLoading ? null : _exportPdf,
            visualDensity: isMobile ? VisualDensity.compact : null,
          ),
          IconButton(
            icon: const Icon(Icons.table_view, color: Colors.green, size: 22),
            tooltip: 'Export Excel',
            onPressed: _isLoading ? null : _exportExcel,
            visualDensity: isMobile ? VisualDensity.compact : null,
          ),
          SizedBox(width: isMobile ? 4 : 8),
          IconButton(icon: const Icon(Icons.sort, color: AppTheme.primary), onPressed: () => _navTo(const CategoryTabularScreen())),
          IconButton(icon: const Icon(Icons.picture_as_pdf, color: Colors.red), onPressed: _isLoading ? null : _exportPdf),
          IconButton(icon: const Icon(Icons.table_view, color: Colors.green), onPressed: _isLoading ? null : _exportExcel),
        ],
      ),      body: _isLoading
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
          : Scrollbar(
          : _reportData == null ? Center(child: Text('Tidak ada data.', style: TextStyle(color: _titleColor(context))))
          : SingleChildScrollView(
              controller: _scrollController,
              thumbVisibility: true,
              trackVisibility: true,
              thickness: 8,
              interactive: true,
              radius: const Radius.circular(4),
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCards(),
                    const SizedBox(height: 16),
                    _buildCacheInfo(),
                    const SizedBox(height: 12),
                    _buildInputButtons(),
                    const SizedBox(height: 12),
                    _buildDisplayTables(),
                  ],
                ),
              padding: EdgeInsets.fromLTRB(useCompact ? 12 : 16, 16, useCompact ? 12 : 16, 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
    );
  }

  Widget _buildSummaryCards() {
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 1100;
        final isVeryNarrow = constraints.maxWidth < 600;
        final cards = [
          _buildCard('Total Received', revTotal, Colors.green),
          _buildCard('Total Tax Out', taxTotal, Colors.orange),
          _buildCard('Operation Cost', opTotal, Colors.blue),
        ];

        if (isVeryNarrow) {
          return Column(
            children: [
              cards[0],
              const SizedBox(height: 12),
              cards[1],
              const SizedBox(height: 12),
              cards[2],
            ],
          );
        }

        if (isNarrow) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 12),
                  Expanded(child: cards[1]),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: cards[2]),
                  const SizedBox(width: 12),
                  const Spacer(),
                ],
              ),
            ],
          );
        }
  Widget _buildSummaryCards(bool useCompact) {
    final revTotal = _toDouble(_reportData?['revenue']?['total_amount_received'] ?? 0);
    final taxTotal = _toDouble(_reportData?['tax']?['total_ppn'] ?? 0) + _toDouble(_reportData?['tax']?['total_pph21'] ?? 0) + _toDouble(_reportData?['tax']?['total_pph23'] ?? 0) + _toDouble(_reportData?['tax']?['total_pph26'] ?? 0);
    final opTotal = _toDouble(_reportData?['operation_cost']?['total_expenses'] ?? 0);
    final cards = [_buildCard('Received', revTotal, Colors.green, useCompact), _buildCard('Tax Out', taxTotal, Colors.orange, useCompact), _buildCard('Op. Cost', opTotal, AppTheme.primary, useCompact)];
    return useCompact ? Column(children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 8), child: c)).toList()) : Row(children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: c))).toList());
  }

        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 16),
            Expanded(child: cards[1]),
            const SizedBox(width: 16),
            Expanded(child: cards[2]),
          ],
        );
      },
    );
  Widget _buildCard(String title, double amount, Color color, bool useCompact) {
    return Container(padding: EdgeInsets.all(useCompact ? 12 : 16), decoration: BoxDecoration(color: _cardColor(context), borderRadius: BorderRadius.circular(12), border: Border.all(color: _dividerColor(context))), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(color: _bodyColor(context), fontSize: useCompact ? 10 : 12)), Text(_fmtMoney(amount), style: TextStyle(color: color, fontSize: useCompact ? 15 : 18, fontWeight: FontWeight.bold))]), Icon(Icons.trending_up_rounded, color: color.withValues(alpha: 0.3), size: useCompact ? 20 : 24)]));
  }

  Widget _buildCard(String title, double amount, Color color) {
    return Card(
      color: _cardColor(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(color: _bodyColor(context), fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              _fmtMoney(amount),
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  Widget _buildInputButtons(bool useCompact) {
    final style = ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: useCompact ? 8 : 16, vertical: useCompact ? 8 : 12), minimumSize: Size(0, useCompact ? 36 : 44), textStyle: TextStyle(fontSize: useCompact ? 11 : 13, fontWeight: FontWeight.bold));
    return Wrap(spacing: 8, runSpacing: 8, children: [ElevatedButton.icon(style: style, onPressed: () => _navTo(RevenueManagementScreen(initialYear: _selectedYear)), icon: const Icon(Icons.receipt, size: 16), label: const Text('Revenue')), ElevatedButton.icon(style: style, onPressed: () => _navTo(TaxManagementScreen(initialYear: _selectedYear)), icon: const Icon(Icons.account_balance, size: 16), label: const Text('Pajak')), ElevatedButton.icon(style: style, onPressed: () => _navTo(DividendManagementScreen(initialYear: _selectedYear)), icon: const Icon(Icons.wallet, size: 16), label: const Text('Dividen')), ElevatedButton.icon(style: style, onPressed: () => _navTo(BalanceSheetSettingsScreen(initialYear: _selectedYear)), icon: const Icon(Icons.assessment, size: 16), label: const Text('Neraca'))]);
  }

  void _navTo(Widget screen) async { await Navigator.push(context, MaterialPageRoute(builder: (_) => screen)); _fetchReport(); }
}

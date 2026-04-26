import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_scrollbar.dart';

class CategoryTabularScreen extends StatefulWidget {
  const CategoryTabularScreen({super.key});

  @override
  State<CategoryTabularScreen> createState() => _CategoryTabularScreenState();
}

class _CategoryTabularScreenState extends State<CategoryTabularScreen> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  bool _isSaving = false;
  final ScrollController _scrollController = ScrollController();
  final ScrollController _langsungController = ScrollController();
  final ScrollController _adminController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    _langsungController.dispose();
    _adminController.dispose();
    super.dispose();
  }

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
  Color _surfaceColor(BuildContext context) =>
      _isDark(context) ? AppTheme.surface : AppTheme.lightSurface;
  Color _cardColor(BuildContext context) =>
      _isDark(context) ? AppTheme.card : AppTheme.lightCard;
  Color _dividerColor(BuildContext context) =>
      _isDark(context) ? AppTheme.divider : AppTheme.lightDivider;
  Color _titleColor(BuildContext context) =>
      _isDark(context) ? AppTheme.cream : AppTheme.lightTextPrimary;
  Color _primaryText(BuildContext context) =>
      _isDark(context) ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
  Color _bodyText(BuildContext context) =>
      _isDark(context) ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      _api.setToken(auth.token!);
      final res = await _api.getCategories();
      final cats = List<Map<String, dynamic>>.from(res['categories'] ?? []);

      cats.sort(
        (a, b) => (a['sort_order'] ?? 0).compareTo(b['sort_order'] ?? 0),
      );

      setState(() {
        _categories = cats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Gagal memuat kategori: $e', isError: true);
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    try {
      final auth = context.read<AuthProvider>();
      _api.setToken(auth.token!);

      final List<Map<String, dynamic>> payload = [];
      for (int i = 0; i < _categories.length; i++) {
        payload.add({
          'id': _categories[i]['id'],
          'sort_order': i + 1,
          'main_group':
              _categories[i]['main_group'] ?? 'BIAYA ADMINISTRASI DAN UMUM',
        });
      }

      await _api.reorderCategories(payload);
      _showSnackBar('Data berhasil disimpan ✓');
    } catch (e) {
      _showSnackBar('Gagal menyimpan: $e', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppTheme.danger : AppTheme.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceColor(context),
      appBar: AppBar(
        title: const Text('Kategori Tabular'),
        elevation: 0,
        backgroundColor: _surfaceColor(context),
        actions: [
          // Tombol Simpan Global
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveChanges,
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text('Simpan Perubahan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Info & Button Atur Grup
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Urutan Kolom Sheet 1',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _titleColor(context),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Geser item untuk mengatur urutan kolom di Excel Tahunan.',
                              style: TextStyle(
                                fontSize: 13,
                                color: _bodyText(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // TOMBOL BARU: Atur Grup & Urutan (Membuka Dialog)
                      TextButton.icon(
                        onPressed: () => _showGroupManagementDialog(context),
                        icon: const Icon(Icons.swap_horiz_rounded),
                        label: const Text('Atur Grup & Urutan'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.accent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          backgroundColor: AppTheme.accent.withValues(
                            alpha: 0.1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Single Reorderable List
                Expanded(
                  child: AppScrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    interactive: true,
                    child: ReorderableListView.builder(
                      scrollController: _scrollController,
                      buildDefaultDragHandles:
                          false, // Matikan handle bawaan agar tidak double
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      itemCount: _categories.length,
                      onReorder: (oldIdx, newIdx) {
                        if (newIdx > oldIdx) newIdx--;
                        setState(() {
                          final item = _categories.removeAt(oldIdx);
                          _categories.insert(newIdx, item);
                        });
                      },
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        return _buildSimpleCategoryCard(
                          cat,
                          index,
                          index + 1,
                          key: ValueKey('row_${cat['id']}'),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSimpleCategoryCard(
    Map<String, dynamic> cat,
    int index,
    int displayIndex, {
    required Key key,
  }) {
    final childrenCount = (cat['children'] as List?)?.length ?? 0;
    final isLangsung = cat['main_group'] == 'BEBAN LANGSUNG';

    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _cardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _dividerColor(context)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              displayIndex.toString().padLeft(2, '0'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        title: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Text(
              cat['name'] ?? '',
              style: TextStyle(
                color: _primaryText(context),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            // Tag kecil untuk grup
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (isLangsung ? AppTheme.accent : Colors.grey).withValues(
                  alpha: 0.1,
                ),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isLangsung ? AppTheme.accent : Colors.grey,
                  width: 0.5,
                ),
              ),
              child: Text(
                isLangsung ? 'Beban Langsung' : 'Administrasi',
                style: TextStyle(
                  fontSize: 9,
                  color: isLangsung ? AppTheme.accent : Colors.grey,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          '$childrenCount sub-kategori',
          style: TextStyle(
            color: _bodyText(context),
            fontSize: 11,
            fontStyle: FontStyle.italic,
          ),
        ),
        trailing: ReorderableDragStartListener(
          index: index,
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(
              Icons.drag_handle_rounded,
              color: Colors.grey,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  void _showGroupManagementDialog(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;
    // Clone data untuk dialog
    List<Map<String, dynamic>> tempCats = List<Map<String, dynamic>>.from(
      _categories.map((c) => {...c}),
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final langsung = tempCats
              .where((c) => c['main_group'] == 'BEBAN LANGSUNG')
              .toList();
          final admin = tempCats
              .where((c) => c['main_group'] != 'BEBAN LANGSUNG')
              .toList();

          return AlertDialog(
            backgroundColor: _cardColor(context),
            title: const Text('Atur Grup & Urutan'),
            content: SizedBox(
              width: screenWidth * 0.95,
              height: isMobile ? 600 : 500,
              child: isMobile
                  ? Column(
                      children: [
                        Expanded(
                          child: _buildKanbanColumn(
                            'BEBAN LANGSUNG',
                            langsung,
                            AppTheme.accent,
                            _langsungController,
                            (cat) => setDialogState(
                              () => cat['main_group'] =
                                  'BIAYA ADMINISTRASI DAN UMUM',
                            ),
                            (oldIdx, newIdx) => setDialogState(() {
                              if (newIdx > oldIdx) newIdx--;
                              langsung.insert(
                                newIdx,
                                langsung.removeAt(oldIdx),
                              );
                              _syncTempCatsOrder(tempCats, langsung, admin);
                            }),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: _buildKanbanColumn(
                            'ADMINISTRASI',
                            admin,
                            AppTheme.primary,
                            _adminController,
                            (cat) => setDialogState(
                              () => cat['main_group'] = 'BEBAN LANGSUNG',
                            ),
                            (oldIdx, newIdx) => setDialogState(() {
                              if (newIdx > oldIdx) newIdx--;
                              admin.insert(newIdx, admin.removeAt(oldIdx));
                              _syncTempCatsOrder(tempCats, langsung, admin);
                            }),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: _buildKanbanColumn(
                            'BEBAN LANGSUNG',
                            langsung,
                            AppTheme.accent,
                            _langsungController,
                            (cat) => setDialogState(
                              () => cat['main_group'] =
                                  'BIAYA ADMINISTRASI DAN UMUM',
                            ),
                            (oldIdx, newIdx) => setDialogState(() {
                              if (newIdx > oldIdx) newIdx--;
                              langsung.insert(
                                newIdx,
                                langsung.removeAt(oldIdx),
                              );
                              _syncTempCatsOrder(tempCats, langsung, admin);
                            }),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildKanbanColumn(
                            'ADMINISTRASI DAN UMUM',
                            admin,
                            AppTheme.primary,
                            _adminController,
                            (cat) => setDialogState(
                              () => cat['main_group'] = 'BEBAN LANGSUNG',
                            ),
                            (oldIdx, newIdx) => setDialogState(() {
                              if (newIdx > oldIdx) newIdx--;
                              admin.insert(newIdx, admin.removeAt(oldIdx));
                              _syncTempCatsOrder(tempCats, langsung, admin);
                            }),
                          ),
                        ),
                      ],
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _categories = tempCats;
                  });
                  Navigator.pop(ctx);
                  _saveChanges();
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Helper untuk sinkronisasi urutan list temporary
  void _syncTempCatsOrder(
    List<Map<String, dynamic>> source,
    List<Map<String, dynamic>> langsung,
    List<Map<String, dynamic>> admin,
  ) {
    source.clear();
    source.addAll(langsung);
    source.addAll(admin);
    for (int i = 0; i < source.length; i++) {
      source[i]['sort_order'] = i + 1;
    }
  }

  Widget _buildKanbanColumn(
    String title,
    List<Map<String, dynamic>> items,
    Color color,
    ScrollController controller,
    Function(Map<String, dynamic>) onMove,
    Function(int, int) onReorder,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                '${items.length}',
                style: TextStyle(color: color, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: AppScrollbar(
            controller: controller,
            thumbVisibility: true,
            interactive: true,
            scrollbarOrientation: ScrollbarOrientation.left,
            child: ReorderableListView.builder(
              scrollController: controller,
              onReorder: onReorder,
              buildDefaultDragHandles: false,
              padding: const EdgeInsets.only(left: 12, right: 8),
              itemCount: items.length,
              itemBuilder: (ctx, idx) {
                final cat = items[idx];
                return Card(
                  key: ValueKey('kanban_${cat['id']}'),
                  color: _surfaceColor(context),
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: _dividerColor(context).withValues(alpha: 0.5),
                    ),
                  ),
                  child: ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    leading: ReorderableDragStartListener(
                      index: idx,
                      child: const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(
                          Icons.drag_handle_rounded,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ),
                    ),
                    title: Text(
                      cat['name'],
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                      ),
                      onPressed: () => onMove(cat),
                      tooltip: 'Pindah grup',
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

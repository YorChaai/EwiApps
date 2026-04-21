import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settlement_provider.dart';
import '../../theme/app_theme.dart';

// kelola kategori
class CategoryManagementView extends StatefulWidget {
  const CategoryManagementView({super.key});

  @override
  State<CategoryManagementView> createState() => _CategoryManagementViewState();
}

class _CategoryManagementViewState extends State<CategoryManagementView> {
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
    final prov = context.read<SettlementProvider>();
    prov.loadCategories();
    prov.loadPendingCategories();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<SettlementProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final useCompact = screenWidth < 500;

    return Container(
      color: _surfaceColor(context),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(useCompact ? 16 : 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // header
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 750;
                final headerInfo = Text(
                  'Manajemen Kategori',
                  style: TextStyle(
                    fontSize: useCompact ? 18 : (isNarrow ? 20 : 24),
                    fontWeight: FontWeight.w700,
                    color: _titleColor(context),
                  ),
                );
                final action = ElevatedButton.icon(
                  onPressed: () => _showAddCategoryDialog(context),
                  icon: Icon(Icons.add_rounded, size: useCompact ? 16 : 18),
                  label: Text(isNarrow ? 'Tambah' : 'Tambah Kategori', style: TextStyle(fontSize: useCompact ? 12 : 14)),
                  style: ElevatedButton.styleFrom(
                    padding: useCompact ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8) : null,
                    minimumSize: useCompact ? const Size(0, 36) : null,
                  ),
                );

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      headerInfo,
                      const SizedBox(height: 12),
                      SizedBox(width: double.infinity, child: action),
                    ],
                  );
                }

                return Row(children: [Expanded(child: headerInfo), action]);
              },
            ),
            SizedBox(height: useCompact ? 16 : 24),
            // kategori pending
            if (prov.pendingCategories.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.pending_actions,
                          color: AppTheme.warning,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Kategori Pending',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.warning,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...(() {
                      final List<Widget> treeItems = [];

                      // Semua kategori pending (baik induk maupun anak)
                      final pending = prov.pendingCategories;
                      if (pending.isEmpty) return <Widget>[];

                      // Pisahkan induk pending dan anak pending
                      final pendingParents = pending
                          .where((c) => c['parent_id'] == null)
                          .toList();
                      final pendingChildren = pending
                          .where((c) => c['parent_id'] != null)
                          .toList();

                      // 1. Tampilkan Induk Pending dan anak-anaknya yang juga pending
                      for (var p in pendingParents) {
                        treeItems.add(_buildPendingItem(p, isSub: false));
                        final subs = pendingChildren
                            .where((c) => c['parent_id'] == p['id'])
                            .toList();
                        for (var s in subs) {
                          treeItems.add(_buildPendingItem(s, isSub: true));
                          pendingChildren.remove(s);
                        }
                      }

                      // 2. Tampilkan Sisa anak pending (yang induknya sudah approved)
                      // Kelompokkan berdasarkan parentId agar tidak duplikat header parentnya
                      final orphansByParent =
                          <int, List<Map<String, dynamic>>>{};
                      for (var s in pendingChildren) {
                        final pid = s['parent_id'] as int;
                        orphansByParent.putIfAbsent(pid, () => []).add(s);
                      }

                      for (var entry in orphansByParent.entries) {
                        final parentId = entry.key;
                        final subs = entry.value;

                        // Cari info parent di list categories
                        final parent = prov.categories.firstWhere(
                          (c) => c['id'] == parentId,
                          orElse: () => {'name': 'Kategori Induk', 'code': '?'},
                        );

                        // Tampilkan header parent (versi kecil/berbeda)
                        treeItems.add(
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 4),
                            child: Text(
                              '${parent['code']} - ${parent['name']} (Sudah Approved)',
                              style: TextStyle(
                                color: _bodyText(context),
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        );

                        for (var s in subs) {
                          treeItems.add(_buildPendingItem(s, isSub: true));
                        }
                      }

                      return treeItems;
                    })(),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            Container(
              width: double.infinity,
              padding: EdgeInsets.all(useCompact ? 12 : 20),
              decoration: BoxDecoration(
                color: _cardColor(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _dividerColor(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Semua Kategori',
                          style: TextStyle(
                            fontSize: useCompact ? 14 : 16,
                            fontWeight: FontWeight.w600,
                            color: _titleColor(context),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _showGroupManagementDialog(context),
                        icon: Icon(Icons.swap_horiz_rounded, size: useCompact ? 16 : 18),
                        label: Text('Atur Grup', style: TextStyle(fontSize: useCompact ? 11 : 13)),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.accent,
                          padding: useCompact ? const EdgeInsets.symmetric(horizontal: 8) : null,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: useCompact ? 8 : 16),
                  ...prov.categories.map((cat) => _buildCategoryTile(cat)),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }

  void _showGroupManagementDialog(BuildContext context) {
    final prov = context.read<SettlementProvider>();
    // Clone categories to avoid direct modification before save
    List<Map<String, dynamic>> localCats =
        List<Map<String, dynamic>>.from(prov.categories.map((c) => {...c}));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final langsung = localCats
              .where((c) => c['main_group'] == 'BEBAN LANGSUNG')
              .toList()
            ..sort((a, b) =>
                (a['sort_order'] ?? 0).compareTo(b['sort_order'] ?? 0));
          final admin = localCats
              .where((c) => c['main_group'] != 'BEBAN LANGSUNG')
              .toList()
            ..sort((a, b) =>
                (a['sort_order'] ?? 0).compareTo(b['sort_order'] ?? 0));

          return AlertDialog(
            backgroundColor: _cardColor(context),
            title: Text(
              'Atur Grup & Urutan',
              style: TextStyle(color: _titleColor(context)),
            ),
            content: SizedBox(
              width: 800,
              height: 500,
              child: Row(
                children: [
                  // Column 1: Beban Langsung
                  Expanded(
                    child: _buildGroupColumn(
                      'BEBAN LANGSUNG',
                      langsung,
                      AppTheme.accent,
                      (cat) {
                        setDialogState(() {
                          cat['main_group'] = 'BIAYA ADMINISTRASI DAN UMUM';
                        });
                      },
                      (list) {
                        setDialogState(() {
                          // No-op here, reorder is handled by ReorderableListView
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Column 2: Administrasi
                  Expanded(
                    child: _buildGroupColumn(
                      'BIAYA ADMINISTRASI DAN UMUM',
                      admin,
                      AppTheme.primary,
                      (cat) {
                        setDialogState(() {
                          cat['main_group'] = 'BEBAN LANGSUNG';
                        });
                      },
                      (list) {
                        setDialogState(() {
                          // No-op here
                        });
                      },
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
                onPressed: () async {
                  // Re-calculate sort orders globally before saving
                  int order = 0;
                  for (var cat in langsung) {
                    cat['sort_order'] = order++;
                  }
                  for (var cat in admin) {
                    cat['sort_order'] = order++;
                  }

                  final success = await prov.reorderCategories(localCats);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Urutan & grup disimpan âœ“'),
                        backgroundColor: AppTheme.success,
                      ),
                    );
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGroupColumn(
    String title,
    List<Map<String, dynamic>> items,
    Color color,
    Function(Map<String, dynamic>) onMove,
    Function(List<Map<String, dynamic>>) onReorder,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
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
              const SizedBox(width: 8),
              Text(
                '${items.length}',
                style: TextStyle(color: color, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ReorderableListView(
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) newIndex--;
              final item = items.removeAt(oldIndex);
              items.insert(newIndex, item);
              onReorder(items);
            },
            children: items
                .map((cat) => Card(
                      key: ValueKey(cat['id']),
                      color: _surfaceColor(context),
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        dense: true,
                        title: Text(
                          cat['name'],
                          style: TextStyle(
                            color: _primaryText(context),
                            fontSize: 13,
                          ),
                        ),
                        trailing: IconButton(
                          icon:
                              const Icon(Icons.arrow_forward_rounded, size: 16),
                          onPressed: () => onMove(cat),
                          tooltip: 'Pindah ke grup lain',
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTile(Map<String, dynamic> cat) {
    final children = (cat['children'] as List?) ?? [];
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 700;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _surfaceColor(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        initiallyExpanded: children.isNotEmpty,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Text(
          '${cat['code']} - ${cat['name']}',
          style: TextStyle(
            color: _primaryText(context),
            fontWeight: FontWeight.w600,
            fontSize: isNarrow ? 13 : 16,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: SizedBox(
          width: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                padding: EdgeInsets.zero,
                icon: Icon(Icons.edit_rounded, size: 18, color: AppTheme.accent),
                tooltip: 'Edit',
                onPressed: () => _showEditCategoryDialog(context, cat),
              ),
              IconButton(
                constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: AppTheme.danger,
                ),
                tooltip: 'Hapus',
                onPressed: () => _deleteCategory(cat['id']),
              ),
            ],
          ),
        ),
        children: children
            .map<Widget>(
              (child) => ListTile(
                minVerticalPadding: 8,
                contentPadding: const EdgeInsets.only(left: 48, right: 16),
                title: Text(
                  '${child['code']} - ${child['name']}',
                  style: TextStyle(
                    color: _bodyText(context),
                    fontSize: isNarrow ? 11 : 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: SizedBox(
                  width: 80,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        constraints: const BoxConstraints.tightFor(
                          width: 32,
                          height: 32,
                        ),
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.edit_rounded,
                          size: 16,
                          color: AppTheme.accent,
                        ),
                        onPressed: () => _showEditCategoryDialog(context, child),
                      ),
                      IconButton(
                        constraints: const BoxConstraints.tightFor(
                          width: 32,
                          height: 32,
                        ),
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: AppTheme.danger,
                        ),
                        onPressed: () => _deleteCategory(child['id']),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildPendingItem(Map<String, dynamic> cat, {required bool isSub}) {
    final prov = context.watch<SettlementProvider>();
    final parentId = cat['parent_id'];
    bool canApprove = true;
    String? reason;

    if (isSub) {
      // Cari parent di list categories (yang berisi data lengkap)
      // Cek apakah ada parent dengan ID tsb yang statusnya 'approved'
      final isParentApproved = prov.categories.any(
        (c) => c['id'] == parentId && c['status'] == 'approved',
      );
      if (!isParentApproved) {
        canApprove = false;
        reason = 'Approve kategori utama dulu';
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: 8, left: isSub ? 32 : 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _cardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: !canApprove
            ? Border.all(color: AppTheme.danger.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        children: [
          if (isSub) ...[
            Text(
              '|- ',
              style: TextStyle(
                color: _bodyText(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cat['name'] ?? '',
                  style: TextStyle(
                    color: canApprove
                        ? _primaryText(context)
                        : _bodyText(context),
                    fontWeight: FontWeight.bold,
                    fontSize: isSub ? 14 : 16,
                  ),
                ),
                Text(
                  'Kode: ${cat['code']}${reason != null ? " • $reason" : ""}',
                  style: TextStyle(
                    color: reason != null
                        ? AppTheme.danger
                        : _bodyText(context),
                    fontSize: 12,
                    fontWeight: reason != null
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.check_circle,
              color: canApprove
                  ? AppTheme.success
                  : _bodyText(context).withValues(alpha: 0.3),
              size: 24,
            ),
            tooltip: canApprove ? 'Approve' : reason,
            onPressed: canApprove
                ? () => _approveCategory(cat['id'], 'approve')
                : null,
          ),
          IconButton(
            icon: Icon(
              Icons.cancel,
              color: canApprove
                  ? AppTheme.danger
                  : _bodyText(context).withValues(alpha: 0.3),
              size: 24,
            ),
            tooltip: canApprove ? 'Reject' : reason,
            onPressed: canApprove
                ? () => _approveCategory(cat['id'], 'reject')
                : null,
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final prov = context.read<SettlementProvider>();
    bool isSubCategory = false;
    int? selectedParentId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: _cardColor(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Tambah Kategori',
            style: TextStyle(color: _titleColor(context)),
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<bool>(
                        title: Text(
                          'Kategori Utama',
                          style: TextStyle(
                            color: _primaryText(context),
                            fontSize: 13,
                          ),
                        ),
                        value: false,
                        // ignore: deprecated_member_use
                        groupValue: isSubCategory,
                        activeColor: AppTheme.primary,
                        contentPadding: EdgeInsets.zero,
                        // ignore: deprecated_member_use
                        onChanged: (v) => setDialogState(() {
                          isSubCategory = v!;
                          selectedParentId = null;
                        }),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<bool>(
                        title: Text(
                          'Sub Kategori',
                          style: TextStyle(
                            color: _primaryText(context),
                            fontSize: 13,
                          ),
                        ),
                        value: true,
                        // ignore: deprecated_member_use
                        groupValue: isSubCategory,
                        activeColor: AppTheme.primary,
                        contentPadding: EdgeInsets.zero,
                        // ignore: deprecated_member_use
                        onChanged: (v) {
                          setDialogState(() => isSubCategory = v!);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama Kategori'),
                  style: TextStyle(color: _primaryText(context)),
                  autofocus: true,
                ),
                if (isSubCategory) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int?>(
                    decoration: InputDecoration(
                      labelText: 'Pilih Kategori Utama',
                    ),
                    dropdownColor: _cardColor(context),
                    style: TextStyle(color: _primaryText(context)),
                    initialValue: selectedParentId,
                    items: prov.categories
                        .where(
                          (c) =>
                              c['parent_id'] == null &&
                              (c['status'] ?? 'approved')
                                      .toString()
                                      .toLowerCase() ==
                                  'approved',
                        )
                        .map(
                          (c) => DropdownMenuItem(
                            value: c['id'] as int,
                            child: Text(c['name']),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => selectedParentId = v),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (isSubCategory && selectedParentId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Pilih Kategori Utama terlebih dahulu'),
                      backgroundColor: AppTheme.warning,
                    ),
                  );
                  return;
                }
                final success = await prov.createCategory(
                  nameCtrl.text.trim(),
                  parentId: selectedParentId,
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Kategori ditambahkan ✓'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                }
              },
              child: const Text('Tambah'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCategoryDialog(BuildContext context, Map<String, dynamic> cat) {
    final nameCtrl = TextEditingController(text: cat['name'] ?? '');
    final prov = context.read<SettlementProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Edit Kategori',
          style: TextStyle(color: _titleColor(context)),
        ),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(labelText: 'Nama Kategori'),
            style: TextStyle(color: _primaryText(context)),
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final success = await prov.updateCategory(
                cat['id'],
                nameCtrl.text.trim(),
              );
              if (ctx.mounted) Navigator.pop(ctx);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Kategori diupdate ✓'),
                    backgroundColor: AppTheme.success,
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

  Future<void> _deleteCategory(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardColor(context),
        title: Text(
          'Hapus Kategori?',
          style: TextStyle(color: _titleColor(context)),
        ),
        content: Text(
          'Kategori akan dihapus permanen. Pastikan tidak ada expense yang terkait.',
          style: TextStyle(color: _bodyText(context)),
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
    if (confirmed == true && mounted) {
      final prov = context.read<SettlementProvider>();
      final success = await prov.deleteCategory(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Kategori dihapus ✓' : prov.error ?? 'Gagal hapus',
            ),
            backgroundColor: success ? AppTheme.success : AppTheme.danger,
          ),
        );
      }
    }
  }

  Future<void> _approveCategory(int id, String action) async {
    final prov = context.read<SettlementProvider>();
    // Mengirim body {"action": action} ke backend via provider
    final success = await prov.approveCategory(id, action);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Kategori ${action}d ✓' : prov.error ?? 'Gagal',
          ),
          backgroundColor: success ? AppTheme.success : AppTheme.danger,
        ),
      );
    }
  }
}

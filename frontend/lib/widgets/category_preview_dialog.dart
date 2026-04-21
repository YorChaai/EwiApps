import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/context_extensions.dart';

class CategoryPreviewDialog extends StatelessWidget {
  final List<Map<String, dynamic>> categories;

  const CategoryPreviewDialog({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final surfaceColor = isDark ? AppTheme.surface : AppTheme.lightSurface;
    final cardColor = isDark ? AppTheme.card : AppTheme.lightCard;
    final textPrimary = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final infoColor = isDark ? AppTheme.accent : AppTheme.primary;

    return AlertDialog(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.category_rounded, color: infoColor, size: 24),
          const SizedBox(width: 12),
          Text(
            'Pratinjau Kategori',
            style: TextStyle(
              color: isDark ? AppTheme.cream : AppTheme.lightTextPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
            color: textSecondary,
          ),
        ],
      ),
      content: SizedBox(
        width: 600,
        height: 650,
        child: categories.isEmpty
            ? Center(
                child: Text(
                  'Belum ada kategori tersedia',
                  style: TextStyle(color: textSecondary),
                ),
              )
            : Scrollbar(
                thumbVisibility: true,
                child: ListView.separated(
                  itemCount: categories.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final children = (cat['children'] as List?) ?? [];
                    final isPending = cat['status'] == 'pending';

                    return Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isPending
                                ? AppTheme.warning.withValues(alpha: 0.3)
                                : Colors.transparent,
                          ),
                        ),
                        child: ExpansionTile(
                          initiallyExpanded: false,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: infoColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.folder_rounded,
                              size: 18,
                              color: infoColor,
                            ),
                          ),
                          title: Text(
                            '${cat['code']} - ${cat['name']}',
                            style: TextStyle(
                              color: isPending ? AppTheme.warning : textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          children: children.isEmpty
                              ? [
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text(
                                      'Tidak ada sub-kategori',
                                      style: TextStyle(
                                        color: textSecondary,
                                        fontSize: 13,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  )
                                ]
                              : children.map((child) {
                                  final isChildPending = child['status'] == 'pending';
                                  return ListTile(
                                    contentPadding: const EdgeInsets.only(left: 56, right: 16),
                                    leading: const Icon(
                                      Icons.subdirectory_arrow_right_rounded,
                                      size: 16,
                                      color: AppTheme.primary,
                                    ),
                                    title: Text(
                                      '${child['code']} - ${child['name']}',
                                      style: TextStyle(
                                        color: isChildPending
                                            ? AppTheme.warning
                                            : textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  );
                                }).toList(),
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
      ],
    );
  }
}

void showCategoryPreviewDialog(BuildContext context, List<Map<String, dynamic>> categories) {
  showDialog(
    context: context,
    builder: (context) => CategoryPreviewDialog(categories: categories),
  );
}

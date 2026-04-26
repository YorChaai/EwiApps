import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../utils/context_extensions.dart';
import 'app_scrollbar.dart';

class ItemDetailPreviewDialog extends StatefulWidget {
  final Map<String, dynamic> item;
  final String title;
  final Function(String path, String? name)? onViewEvidence;

  const ItemDetailPreviewDialog({
    super.key,
    required this.item,
    this.title = 'Pratinjau Item',
    this.onViewEvidence,
  });

  @override
  State<ItemDetailPreviewDialog> createState() =>
      _ItemDetailPreviewDialogState();
}

class _ItemDetailPreviewDialogState extends State<ItemDetailPreviewDialog> {
  final ScrollController _scrollController = ScrollController();
  final _currencyFormat = NumberFormat('#,##0', 'id_ID');

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _formatAmount(dynamic amount, String? currency) {
    if (amount == null) return '-';
    final val = double.tryParse(amount.toString()) ?? 0;
    if (currency == 'IDR' || currency == null) {
      return 'Rp ${_currencyFormat.format(val)}';
    }
    return '$currency ${NumberFormat('#,##0.##', 'en_US').format(val)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final cardColor = isDark ? AppTheme.card : AppTheme.lightCard;
    final textSecondary = isDark
        ? AppTheme.textSecondary
        : AppTheme.lightTextSecondary;
    final infoColor = isDark ? AppTheme.accent : AppTheme.primary;
    final screenWidth = MediaQuery.of(context).size.width;

    // Extract fields based on whether it's settlement or advance
    final item = widget.item;
    final List<Map<String, dynamic>> fields = [];

    if (item['title'] != null && item['title'].toString().isNotEmpty) {
      fields.add({
        'label': 'Judul',
        'value': item['title'],
        'icon': Icons.title_rounded,
      });
    }

    fields.addAll([
      {
        'label': 'Tanggal',
        'value': item['date'] ?? '-',
        'icon': Icons.calendar_today_rounded,
      },
      {
        'label': 'Kategori',
        'value': item['category_name'] ?? '-',
        'icon': Icons.category_rounded,
      },
      {
        'label': 'Amount',
        'value': _formatAmount(
          item['amount'] ?? item['estimated_amount'],
          item['currency'],
        ),
        'icon': Icons.payments_rounded,
        'color': AppTheme.primary,
      },
    ]);

    if (item['source'] != null) {
      fields.add({
        'label': 'Sumber',
        'value': item['source'],
        'icon': Icons.account_balance_wallet_rounded,
      });
    }

    // Clean description if it contains system info
    String cleanDescription = (item['description'] ?? '-').toString();
    if (cleanDescription.contains('Imported from')) {
      cleanDescription = cleanDescription.split('Imported from').first.trim();
    }
    if (cleanDescription.isEmpty) cleanDescription = '-';

    fields.add({
      'label': 'Deskripsi',
      'value': cleanDescription,
      'icon': Icons.description_rounded,
    });

    // Add IDR Amount if it's a foreign currency
    if (item['currency'] != null &&
        item['currency'] != 'IDR' &&
        item['idr_amount'] != null) {
      fields.add({
        'label': 'Amount (IDR)',
        'value': 'Rp ${_currencyFormat.format(item['idr_amount'])}',
        'icon': Icons.currency_exchange_rounded,
      });
    }

    if (item['notes'] != null && item['notes'].toString().isNotEmpty) {
      fields.add({
        'label': 'Catatan / Komentar',
        'value': item['notes'],
        'icon': Icons.comment_rounded,
        'isNotes': true,
      });
    }

    if (item['batch_notes'] != null && item['batch_notes'].toString().isNotEmpty) {
      fields.add({
        'label': 'Catatan Batch',
        'value': item['batch_notes'],
        'icon': Icons.assignment_rounded,
        'color': AppTheme.warning,
      });
    }

    final status = (item['status'] ?? 'pending').toString().toLowerCase();

    return AlertDialog(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: infoColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.title,
              style: TextStyle(
                color: isDark ? AppTheme.cream : AppTheme.lightTextPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
            color: textSecondary,
          ),
        ],
      ),
      content: SizedBox(
        width: screenWidth > 600 ? 500 : screenWidth * 0.9,
        child: AppScrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getStatusColor(status).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(status),
                          color: _getStatusColor(status),
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(status),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Field List
                  ...fields.map((f) => _buildFieldRow(context, f, isDark)),

                  // Evidence Section
                  if (item['evidence_path'] != null) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(),
                    ),
                    Text(
                      'Evidence / Bukti:',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () {
                        if (widget.onViewEvidence != null) {
                          widget.onViewEvidence!(
                            item['evidence_path'],
                            item['evidence_filename'],
                          );
                        }
                      },
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.black26
                              : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.divider),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              const Center(
                                child: Icon(
                                  Icons.image_rounded,
                                  size: 40,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: 40),
                                    Text(
                                      'Klik untuk melihat bukti',
                                      style: TextStyle(
                                        color: textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
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

  Widget _buildFieldRow(
    BuildContext context,
    Map<String, dynamic> field,
    bool isDark,
  ) {
    final textSecondary = isDark
        ? AppTheme.textSecondary
        : AppTheme.lightTextSecondary;
    final textPrimary = isDark
        ? AppTheme.textPrimary
        : AppTheme.lightTextPrimary;
    final isNotes = field['isNotes'] == true;

    if (isNotes) {
      final comments = _getCommentsFromNotes(field['value'].toString());

      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(field['icon'] as IconData, size: 14, color: textSecondary),
                const SizedBox(width: 8),
                Text(
                  'Komentar Penolakan',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (comments.isEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 22, top: 4),
                child: Text(
                  'Tidak ada komentar',
                  style: TextStyle(
                    color: textSecondary.withValues(alpha: 0.5),
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(left: 22),
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _showCommentsDialog(context, comments, isDark),
                      icon: const Icon(Icons.comment_rounded, size: 16),
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Lihat Komentar'),
                          const SizedBox(width: 4),
                          Transform.translate(
                            offset: const Offset(0, -5),
                            child: Text(
                              comments.length.toString(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                        foregroundColor: AppTheme.primary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.2)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(field['icon'] as IconData, size: 14, color: textSecondary),
              const SizedBox(width: 8),
              Text(
                field['label'].toString(),
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.divider.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.subdirectory_arrow_right_rounded,
                  size: 14,
                  color: AppTheme.primary.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SelectableText(
                    field['value']?.toString() ?? '-',
                    style: TextStyle(
                      color: field['color'] as Color? ?? textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getCommentsFromNotes(String notes) {
    if (notes.isEmpty) return [];

    final systemPrefixes = [
      'Disetujui oleh',
      'Imported from',
      'Subcategory:',
      'Approved by',
      'System:',
    ];

    try {
      final decoded = json.decode(notes);
      if (decoded is List) {
        final List<String> comments = [];
        for (var item in decoded) {
          final text = (item is Map ? item['text'] : item).toString();

          bool isSystem = false;
          for (var prefix in systemPrefixes) {
            if (text.trim().startsWith(prefix)) {
              isSystem = true;
              break;
            }
          }

          if (!isSystem && text.trim().isNotEmpty) {
            comments.add(text.trim());
          }
        }
        return comments;
      }
      return [];
    } catch (_) {
      bool isSystem = false;
      for (var prefix in systemPrefixes) {
        if (notes.trim().startsWith(prefix)) {
          isSystem = true;
          break;
        }
      }
      return isSystem || notes.trim().isEmpty ? [] : [notes.trim()];
    }
  }

  void _showCommentsDialog(BuildContext context, List<String> comments, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.card : AppTheme.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.comment_rounded, color: AppTheme.accent),
            const SizedBox(width: 10),
            const Text('Riwayat Komentar'),
            const Spacer(),
            IconButton(
              onPressed: () => Navigator.pop(ctx),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: comments.length,
            separatorBuilder: (c, i) => const Divider(),
            itemBuilder: (c, i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      (i + 1).toString(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SelectableText(
                      comments[i],
                      style: TextStyle(
                        color: isDark ? AppTheme.cream : AppTheme.lightTextPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
      case 'completed':
        return AppTheme.success;
      case 'rejected':
        return AppTheme.danger;
      case 'submitted':
      case 'pending':
        return AppTheme.warning;
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'approved':
      case 'completed':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      case 'submitted':
      case 'pending':
        return Icons.access_time_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }
}

void showItemDetailPreviewDialog({
  required BuildContext context,
  required Map<String, dynamic> item,
  String title = 'Pratinjau Item',
  Function(String path, String? name)? onViewEvidence,
}) {
  showDialog(
    context: context,
    builder: (context) => ItemDetailPreviewDialog(
      item: item,
      title: title,
      onViewEvidence: onViewEvidence,
    ),
  );
}

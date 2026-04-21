import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class EvidenceViewer extends StatelessWidget {
  final String? imageUrl;
  final String? fileName;
  final VoidCallback? onDelete;
  final bool canDelete;

  const EvidenceViewer({
    super.key,
    this.imageUrl,
    this.fileName,
    this.onDelete,
    this.canDelete = false,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 40),
            SizedBox(height: 8),
            Text('Tidak ada lampiran', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    final isPdf = fileName?.toLowerCase().endsWith('.pdf') ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: isPdf
                    ? _buildPdfPlaceholder()
                    : _buildImage(context),
              ),
            ),
            if (canDelete && onDelete != null)
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  backgroundColor: AppTheme.danger,
                  radius: 18,
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white, size: 18),
                    onPressed: onDelete,
                    tooltip: 'Hapus Lampiran',
                  ),
                ),
              ),
          ],
        ),
        if (fileName != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              'File: $fileName',
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  Widget _buildPdfPlaceholder() {
    return Container(
      color: Colors.red.withValues(alpha: 0.05),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.picture_as_pdf, color: Colors.red, size: 50),
          SizedBox(height: 8),
          Text('Dokumen PDF', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    return Image.network(
      imageUrl!,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image_outlined, color: Colors.red, size: 40),
              SizedBox(height: 8),
              Text('Gagal memuat gambar', style: TextStyle(color: Colors.red, fontSize: 12)),
            ],
          ),
        );
      },
    );
  }
}

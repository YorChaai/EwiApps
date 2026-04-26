import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart'; // Ganti ke file_picker
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/settlement_provider.dart';
import '../../providers/advance_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/account_list_dialog.dart';
import '../../widgets/image_cropper_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ApiService _api = ApiService();
  bool _loading = true;
  String _currentDir = '';
  int _currentReportYear = 2024;
  final _dirController = TextEditingController();
  bool _showManagerSection = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _dirController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) return;
    _api.setToken(auth.token!);
    try {
      final res = await _api.getStorageSettings();
      final reportYearRes = await _api.getReportYearSettings();
      if (mounted) {
        final parsedYear = int.tryParse(
          (reportYearRes['default_report_year'] ?? 2024).toString(),
        );
        setState(() {
          _currentDir = res['current_directory'] ?? '';
          _dirController.text = _currentDir;
          _currentReportYear = parsedYear ?? 2024;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveSettings() async {
    final newDir = _dirController.text.trim();
    if (newDir.isEmpty) return;
    setState(() => _loading = true);
    try {
      final res = await _api.updateStorageSettings(newDir);
      if (mounted) {
        setState(() {
          _loading = false;
          _currentDir = res['new_directory'] ?? newDir;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res['message'] ?? 'Berhasil memindahkan penyimpanan.',
            ),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  Future<void> _saveReportYearSettings() async {
    final year = _currentReportYear;
    setState(() => _loading = true);
    try {
      final res = await _api.updateReportYearSettings(year);
      if (mounted) {
        setState(() {
          _loading = false;
          _currentReportYear =
              int.tryParse((res['default_report_year'] ?? year).toString()) ??
              year;
        });
        context.read<SettlementProvider>().setReportYear(year, reload: true);
        context.read<AdvanceProvider>().setReportYear(year, reload: true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Default tahun laporan berhasil disimpan.'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  Future<void> _exportDatabase() async {
    setState(() => _loading = true);
    try {
      final res = await _api.exportDatabase();
      if (mounted) {
        setState(() => _loading = false);
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: AppTheme.success),
                SizedBox(width: 8),
                Text('Export Berhasil'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Database telah berhasil dicadangkan.'),
                const SizedBox(height: 12),
                const Text(
                  'Lokasi Folder:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                Text(
                  res['path'] ?? '-',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Nama Folder: ${res['folder']}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  Future<void> _importDatabase() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any, // SQLite .db biasanya dideteksi as any/binary
        allowMultiple: false,
      );

      if (result == null || result.files.single.path == null) return;
      final filePath = result.files.single.path!;
      final fileName = result.files.single.name.toLowerCase();

      if (!fileName.endsWith('.sql')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Hanya file .sql (Postgres) yang diperbolehkan.'),
              backgroundColor: AppTheme.danger,
            ),
          );
        }
        return;
      }
      setState(() => _loading = true);
      final preview = await _api.importDatabasePreview(filePath);

      if (mounted) {
        setState(() => _loading = false);
        _showImportPreviewDialog(preview);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  void _showImportPreviewDialog(Map<String, dynamic> preview) {
    final summary = (preview['summary'] as List? ?? []);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Preview Data Import'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'File: ${preview['filename']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ringkasan Isi Database:',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  border: Border.all(color: _dividerColor(context)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: summary.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (c, i) => ListTile(
                    dense: true,
                    title: Text(
                      summary[i]['table'].toString().toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    trailing: Text(
                      '${summary[i]['rows']} baris',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.danger.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: AppTheme.danger,
                      size: 28,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'PERHATIAN: Database saat ini akan DIHAPUS dan diganti dengan data dari file ini. Pastikan Anda sudah melakukan Export untuk cadangan.',
                        style: TextStyle(
                          color: AppTheme.danger,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              _confirmImport();
            },
            child: const Text('YA, GANTI DATABASE'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmImport() async {
    setState(() => _loading = true);
    try {
      final res = await _api.confirmImportDatabase();
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Database berhasil dipulihkan.'),
            backgroundColor: AppTheme.success,
          ),
        );
        // Opsional: Reload data atau minta restart
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  void _showAccountList() async {
    showDialog(context: context, builder: (ctx) => const AccountListDialog());
  }

  void _toggleManagerSection() {
    setState(() => _showManagerSection = !_showManagerSection);
  }

  void _showEditProfileDialog() async {
    final auth = context.read<AuthProvider>();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => EditProfileDialog(user: auth.user!),
    );

    if (result != null && result['success'] == true && mounted) {
      auth.updateUserData(result['user']);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil diperbarui'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
  Color _cardColor(BuildContext context) =>
      _isDark(context) ? AppTheme.card : AppTheme.lightCard;
  Color _surfaceColor(BuildContext context) =>
      _isDark(context) ? AppTheme.surface : AppTheme.lightSurface;
  Color _dividerColor(BuildContext context) =>
      _isDark(context) ? AppTheme.divider : AppTheme.lightDivider;
  Color _titleColor(BuildContext context) =>
      _isDark(context) ? AppTheme.cream : AppTheme.lightTextPrimary;
  Color _bodyColor(BuildContext context) =>
      _isDark(context) ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

  Widget _buildProfileCard() {
    final auth = context.watch<AuthProvider>();
    final user = auth.user ?? {};
    final isGoogleLinked = user['google_id'] != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _cardColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _dividerColor(context)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.black.withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: AppTheme.primary,
                  backgroundImage: auth.profileImageUrl != null
                      ? NetworkImage(auth.profileImageUrl!)
                      : null,
                  child: auth.profileImageUrl == null
                      ? Text(
                          (auth.fullName.isNotEmpty ? auth.fullName[0] : 'U')
                              .toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: _showEditProfileDialog,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            auth.fullName,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _titleColor(context),
            ),
          ),
          Text(
            '@${user['username'] ?? '-'}',
            style: TextStyle(fontSize: 14, color: _bodyColor(context)),
          ),
          const SizedBox(height: 12),
          // Google Link Status Button
          SizedBox(
            height: 36,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isGoogleLinked ? AppTheme.success : AppTheme.danger,
                ),
                foregroundColor:
                    isGoogleLinked ? AppTheme.success : AppTheme.danger,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () async {
                if (isGoogleLinked) {
                  // Tampilkan dialog konfirmasi Unlink
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: _cardColor(context),
                      title: const Text('Putuskan Google'),
                      content: const Text(
                        'Apakah Anda yakin ingin memutuskan hubungan akun Google dari aplikasi ini?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Batal'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.danger,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Ya, Putuskan'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && mounted) {
                    final ok = await auth.unlinkGoogleAccount();
                    if (mounted) {
                      if (ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Koneksi Google telah dihapus'),
                            backgroundColor: AppTheme.success,
                          ),
                        );
                      }
                    }
                  }
                } else {
                  // Cek dukungan platform saat diklik
                  if (!auth.isGoogleSignInSupported) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Fitur Google Sign-In belum tersedia di Windows. Silakan coba di HP Android.',
                        ),
                        backgroundColor: AppTheme.danger,
                      ),
                    );
                    return;
                  }

                  final ok = await auth.linkGoogleAccount();
                  if (mounted) {
                    if (ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Berhasil menghubungkan Google'),
                          backgroundColor: AppTheme.success,
                        ),
                      );
                    } else if (auth.error != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(auth.error!),
                          backgroundColor: AppTheme.danger,
                        ),
                      );
                    }
                  }
                }
              },
              icon: Icon(
                isGoogleLinked ? Icons.check_circle : Icons.link_rounded,
                size: 18,
              ),
              label: Text(
                isGoogleLinked ? 'Google Terhubung' : 'Hubungkan Google',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          Wrap(
            spacing: 40,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: [
              _profileColumn(
                'Role',
                auth.roleDisplayName,
                Icons.badge_outlined,
              ),
              _profileColumn(
                'No HP',
                user['phone_number'] ?? '-',
                Icons.phone_outlined,
              ),
              _profileColumn(
                'Tempat Kerja',
                user['workplace'] ?? '-',
                Icons.work_outline,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _profileColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppTheme.primary.withValues(alpha: 0.7)),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: _bodyColor(context), fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: _titleColor(context),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeSettingsCard(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(24),
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
              const Icon(Icons.palette_rounded, color: AppTheme.primary),
              const SizedBox(width: 12),
              Text(
                'Tema Aplikasi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _titleColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment<ThemeMode>(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode_rounded),
                label: Text('Light'),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode_rounded),
                label: Text('Dark'),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.system,
                icon: Icon(Icons.settings_suggest_rounded),
                label: Text('System'),
              ),
            ],
            selected: {themeProvider.themeMode},
            onSelectionChanged: (selection) =>
                themeProvider.setThemeMode(selection.first),
          ),
        ],
      ),
    );
  }

  Widget _buildManagerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.5)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.admin_panel_settings_rounded,
                color: AppTheme.primary,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'MANAGER ONLY',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
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
                  const Icon(
                    Icons.people_outline_rounded,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Manage User (Account List)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _titleColor(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _showAccountList,
                  icon: const Icon(Icons.list_rounded),
                  label: const Text(
                    'Lihat Account List',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildReportYearSettingsCard(),
        const SizedBox(height: 16),
        _buildStorageSettingsCard(),
        const SizedBox(height: 16),
        _buildDatabaseSettingsCard(),
      ],
    );
  }

  Widget _buildDatabaseSettingsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
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
              const Icon(Icons.storage_rounded, color: AppTheme.primary),
              const SizedBox(width: 12),
              Text(
                'Manajemen Database',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _titleColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Cadangkan atau pulihkan seluruh database aplikasi.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                      foregroundColor: AppTheme.primary,
                      elevation: 0,
                      side: const BorderSide(color: AppTheme.primary),
                    ),
                    onPressed: _loading ? null : _exportDatabase,
                    icon: const Icon(Icons.cloud_upload_rounded),
                    label: const Text(
                      'Export Data',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _loading ? null : _importDatabase,
                    icon: const Icon(Icons.cloud_download_rounded),
                    label: const Text(
                      'Import Data',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStorageSettingsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
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
              const Icon(Icons.folder_rounded, color: AppTheme.primary),
              const SizedBox(width: 12),
              Text(
                'Penyimpanan Data',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _titleColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _dirController,
            decoration: const InputDecoration(
              hintText: 'Direktori penyimpanan',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: _loading ? null : _saveSettings,
              icon: const Icon(Icons.save_rounded),
              label: const Text(
                'Simpan & Pindahkan Data',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportYearSettingsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
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
              const Icon(Icons.calendar_month_rounded, color: AppTheme.primary),
              const SizedBox(width: 12),
              Text(
                'Default Tahun Laporan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _titleColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: _surfaceColor(context),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _dividerColor(context)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _currentReportYear,
                isExpanded: true,
                dropdownColor: _cardColor(context),
                style: TextStyle(color: _titleColor(context)),
                items: List.generate(10, (index) => 2022 + index)
                    .map(
                      (y) =>
                          DropdownMenuItem(value: y, child: Text('Laporan $y')),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _currentReportYear = value);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: _loading ? null : _saveReportYearSettings,
              icon: const Icon(Icons.save_rounded),
              label: const Text(
                'Simpan Default Tahun',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Sistem'),
        actions: [
          if (auth.isManager)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton.icon(
                onPressed: _toggleManagerSection,
                icon: Icon(
                  Icons.admin_panel_settings_rounded,
                  color: _showManagerSection
                      ? AppTheme.primary
                      : _bodyColor(context),
                  size: 20,
                ),
                label: Text(
                  'Manager Panel',
                  style: TextStyle(
                    color: _showManagerSection
                        ? AppTheme.primary
                        : _bodyColor(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileCard(),
                  const SizedBox(height: 16),
                  _buildThemeSettingsCard(themeProvider),
                  if (auth.isManager && _showManagerSection)
                    _buildManagerSection(),
                ],
              ),
            ),
    );
  }
}

class EditProfileDialog extends StatefulWidget {
  final Map<String, dynamic> user;
  const EditProfileDialog({super.key, required this.user});
  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _workplaceController;
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _showPasswordFields = false;

  String? _selectedImagePath; // Simpan path string
  bool _removeImage = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user['full_name']);
    _phoneController = TextEditingController(
      text: widget.user['phone_number'] == '-'
          ? ''
          : widget.user['phone_number'],
    );
    _workplaceController = TextEditingController(
      text: widget.user['workplace'] == '-' ? '' : widget.user['workplace'],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _workplaceController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final pickedFile = File(result.files.single.path!);
        if (!mounted) return;

        // Buka dialog "Pencocokan" (Cropper)
        final croppedPath = await showDialog<String>(
          context: context,
          barrierColor: Colors.black54,
          builder: (ctx) => ImageCropperDialog(imageFile: pickedFile),
        );

        if (croppedPath != null) {
          setState(() {
            _selectedImagePath = croppedPath;
            _removeImage = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      final success = await auth.updateProfile(
        {
          'full_name': _nameController.text.trim(),
          'phone_number': _phoneController.text.trim().isEmpty
              ? '-'
              : _phoneController.text.trim(),
          'workplace': _workplaceController.text.trim().isEmpty
              ? '-'
              : _workplaceController.text.trim(),
          'old_password': _showPasswordFields
              ? _oldPasswordController.text
              : null,
          'new_password': _showPasswordFields
              ? _newPasswordController.text
              : null,
        },
        imagePath: _selectedImagePath,
        removeImage: _removeImage,
      );
      if (success && mounted) {
        Navigator.pop(context, {'success': true, 'user': auth.user});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();

    return AlertDialog(
      backgroundColor: isDark ? AppTheme.card : AppTheme.lightCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Center(
        child: Text(
          'Edit Profil Saya',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image Picker UI - Centered with floating buttons
            Center(
              child: SizedBox(
                width: 220, // Lebar cukup untuk avatar + tombol di kanan (dan dummy di kiri agar center)
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Avatar Utama
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                      backgroundImage: _removeImage
                          ? null
                          : (_selectedImagePath != null
                                ? FileImage(File(_selectedImagePath!))
                                : (auth.profileImageUrl != null
                                          ? NetworkImage(auth.profileImageUrl!)
                                          : null)
                                      as ImageProvider?),
                      child: (_removeImage || (auth.profileImageUrl == null && _selectedImagePath == null))
                          ? const Icon(Icons.person, size: 48, color: AppTheme.primary)
                          : null,
                    ),
                    
                    // Overlay Hapus (Notifikasi visual saat akan dihapus)
                    if (_removeImage)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.delete_forever, color: Colors.white, size: 32),
                                Text(
                                  'Dihapus',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Tombol Aksi di Samping Kanan
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Button Ganti Foto
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.card, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Button Hapus Foto
                          if (auth.profileImageUrl != null ||
                              _selectedImagePath != null)
                            GestureDetector(
                              onTap: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Hapus Foto Profil?'),
                                    content: const Text(
                                        'Apakah Anda yakin ingin menghapus foto profil ini?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text('Batal'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        style: TextButton.styleFrom(
                                            foregroundColor: AppTheme.danger),
                                        child: const Text('Hapus'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  setState(() {
                                    _selectedImagePath = null;
                                    _removeImage = true;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.danger,
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: AppTheme.card, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.delete_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'No HP',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _workplaceController,
              decoration: const InputDecoration(
                labelText: 'Tempat Kerja',
                prefixIcon: Icon(Icons.work_outline),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            ListTile(
              onTap: () =>
                  setState(() => _showPasswordFields = !_showPasswordFields),
              title: const Text(
                'Ganti Password',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              trailing: Icon(
                _showPasswordFields
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
              ),
              contentPadding: EdgeInsets.zero,
            ),
            if (_showPasswordFields) ...[
              TextField(
                controller: _oldPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password Saat Ini',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password Baru',
                  prefixIcon: Icon(Icons.lock_reset_rounded),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Password minimal 6 karakter',
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Simpan Perubahan'),
        ),
      ],
    );
  }
}

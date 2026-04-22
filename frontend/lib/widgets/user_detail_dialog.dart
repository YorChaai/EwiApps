import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class UserDetailDialog extends StatefulWidget {
  final Map<String, dynamic>? user;
  final int? userId;

  const UserDetailDialog({super.key, this.user, this.userId})
      : assert(user != null || userId != null, 'Harus sedia data user atau userId');

  @override
  State<UserDetailDialog> createState() => _UserDetailDialogState();
}

class _UserDetailDialogState extends State<UserDetailDialog> {
  Map<String, dynamic>? _userData;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _userData = widget.user;
    } else {
      _fetchUserData();
    }
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      final users = await auth.getUsers();
      final found = users.firstWhere(
        (u) => u['id'] == widget.userId,
        orElse: () => throw Exception('User tidak ditemukan'),
      );
      if (mounted) setState(() => _userData = found);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;
  Color _cardColor(BuildContext context) => _isDark(context) ? AppTheme.card : AppTheme.lightCard;
  Color _creamColor(BuildContext context) => _isDark(context) ? AppTheme.cream : AppTheme.lightTextPrimary;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: screenWidth > 450 ? 400 : screenWidth * 0.9,
        decoration: BoxDecoration(
          color: _cardColor(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _isDark(context) ? AppTheme.divider : AppTheme.lightDivider),
        ),
        child: _loading
            ? _buildLoading()
            : _error != null
                ? _buildError()
                : _buildContent(context),
      ),
    );
  }

  Widget _buildLoading() => const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()));

  Widget _buildError() => Padding(
    padding: const EdgeInsets.all(40),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, size: 48, color: AppTheme.danger),
        const SizedBox(height: 16),
        Text(_error ?? 'Terjadi kesalahan', textAlign: TextAlign.center),
        const SizedBox(height: 16),
        TextButton(onPressed: _fetchUserData, child: const Text('Coba Lagi')),
      ],
    ),
  );

  Widget _buildContent(BuildContext context) {
    if (_userData == null) return const SizedBox.shrink();
    final user = _userData!;
    final isOnline = user['is_online'] as bool? ?? false;
    final lastLogin = user['last_login_formatted'] as String? ?? '-';
    final workplace = user['workplace']?.toString() ?? '-';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppTheme.primary,
                    backgroundImage: user['profile_image'] != null
                        ? NetworkImage('${ApiService.baseUrl}/uploads/${user['profile_image']}')
                        : null,
                    child: user['profile_image'] == null
                        ? Text(((user['full_name'] as String?)?.isNotEmpty == true ? user['full_name'][0] : 'U').toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))
                        : null,
                  ),
                  Positioned(
                    right: 0, bottom: 0,
                    child: Container(width: 16, height: 16, decoration: BoxDecoration(color: isOnline ? AppTheme.success : AppTheme.textSecondary, shape: BoxShape.circle, border: Border.all(color: _cardColor(context), width: 2))),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user['full_name'] ?? '-', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _creamColor(context))),
                    Text('@${user['username']}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.work_outline, size: 14, color: AppTheme.primary),
                        const SizedBox(width: 4),
                        Expanded(child: Text(workplace, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ],
                ),
              ),
              _badge(isOnline ? 'Online' : 'Offline', isOnline ? AppTheme.success : AppTheme.textSecondary),
            ],
          ),
        ),

        // Info List
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _detailItem(Icons.badge_outlined, 'Role', _getRoleName(user['role'] ?? 'staff')),
              const SizedBox(height: 12),
              _detailItem(Icons.phone_outlined, 'No HP', user['phone_number'] ?? '-'),
              const SizedBox(height: 12),
              _detailItem(Icons.access_time, 'Last Login', lastLogin),
              const SizedBox(height: 12),
              _detailItem(Icons.calendar_today_outlined, 'Member Since', _formatDate(user['created_at'])),
            ],
          ),
        ),

        // Close Button
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Tutup'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
    child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
  );

  Widget _detailItem(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  String _getRoleName(String role) {
    if (role == 'manager') return 'Manager';
    if (role == 'mitra_eks') return 'Mitra';
    return 'Staff';
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr.toString());
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) { return '-'; }
  }
}

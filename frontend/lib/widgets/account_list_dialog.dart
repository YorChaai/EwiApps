import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import 'user_detail_dialog.dart';

class AccountListDialog extends StatefulWidget {
  const AccountListDialog({super.key});

  @override
  State<AccountListDialog> createState() => _AccountListDialogState();
}

class _AccountListDialogState extends State<AccountListDialog> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = false;

  bool _isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;
  Color _cardColor(BuildContext context) => _isDark(context) ? AppTheme.card : AppTheme.lightCard;
  Color _surfaceColor(BuildContext context) => _isDark(context) ? AppTheme.surface : AppTheme.lightSurface;
  Color _textColor(BuildContext context) => _isDark(context) ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
  Color _secondaryTextColor(BuildContext context) => _isDark(context) ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
  Color _creamColor(BuildContext context) => _isDark(context) ? AppTheme.cream : AppTheme.lightTextPrimary;
  Color _dividerColor(BuildContext context) => _isDark(context) ? AppTheme.divider : AppTheme.lightDivider;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      final users = await auth.getUsers();
      if (mounted) setState(() => _users = users);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCreateUserDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => const CreateUserDialog(),
    );
    if (result == true) _loadUsers();
  }

  void _showEditUserByManager(Map<String, dynamic> user) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => EditUserByManagerDialog(user: user),
    );
    if (result == true) _loadUsers();
  }

  void _showUserDetail(Map<String, dynamic> user) {
    showDialog(context: context, builder: (ctx) => UserDetailDialog(user: user));
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: isDesktop ? 1100 : double.infinity,
        height: isDesktop ? 750 : double.infinity,
        margin: EdgeInsets.all(isDesktop ? 24 : 16),
        decoration: BoxDecoration(color: _cardColor(context), borderRadius: BorderRadius.circular(24), border: Border.all(color: _dividerColor(context))),
        child: Column(
          children: [
            _buildHeader(context),
            const Divider(height: 1),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _users.isEmpty
                      ? Center(child: Text('Belum ada user', style: TextStyle(color: _secondaryTextColor(context))))
                      : isDesktop ? _buildDesktopTable() : _buildMobileListWithRefresh(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (!isMobile) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.people_outline_rounded, color: AppTheme.primary, size: 24),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Account List',
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    color: _creamColor(context),
                  ),
                ),
                Text(
                  '${_users.length} user',
                  style: TextStyle(fontSize: 11, color: _secondaryTextColor(context)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            color: _secondaryTextColor(context),
            onPressed: _loadUsers,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(8),
          ),
          const SizedBox(width: 4),
          if (isMobile)
            IconButton(
              onPressed: _showCreateUserDialog,
              icon: const Icon(Icons.add_box_rounded, color: AppTheme.primary, size: 28),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            )
          else
            ElevatedButton.icon(
              onPressed: _showCreateUserDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Tambah Akun'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.close, color: _secondaryTextColor(context), size: 20),
            onPressed: () => Navigator.pop(context),
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(8),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(border: Border.all(color: _dividerColor(context))),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppTheme.primary.withValues(alpha: 0.1)),
              columns: const [
                DataColumn(label: Text('User', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('No HP', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Kantor', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Last Login', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: _users.map((user) {
                return DataRow(cells: [
                  DataCell(Row(children: [
                    GestureDetector(onTap: () => _showUserDetail(user), child: MouseRegion(cursor: SystemMouseCursors.click, child: CircleAvatar(radius: 16, backgroundColor: AppTheme.primary, child: Text(((user['full_name'] as String?)?.isNotEmpty == true ? user['full_name'][0] : 'U').toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12))))),
                    const SizedBox(width: 8),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(user['full_name'] ?? '-', style: TextStyle(fontWeight: FontWeight.w600, color: _creamColor(context))),
                      Text('@${user['username']}', style: TextStyle(fontSize: 11, color: _secondaryTextColor(context))),
                    ]),
                  ])),
                  DataCell(Text(user['phone_number'] ?? '-', style: TextStyle(color: _textColor(context)))),
                  DataCell(Text(user['workplace'] ?? '-', style: TextStyle(color: _textColor(context)))),
                  DataCell(_buildRoleBadge(user['role'] ?? 'staff')),
                  DataCell(Text(user['last_login_formatted'] ?? '-', style: TextStyle(color: _textColor(context), fontSize: 12))),
                  DataCell(_buildStatusIndicator(user['is_online'] ?? false)),
                  DataCell(IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.primary), onPressed: () => _showEditUserByManager(user))),
                ]);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileListWithRefresh() => RefreshIndicator(onRefresh: _loadUsers, child: ListView.separated(
    padding: const EdgeInsets.all(16),
    itemCount: _users.length,
    separatorBuilder: (context, index) => const SizedBox(height: 12),
    itemBuilder: (context, index) {
      final user = _users[index];
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _surfaceColor(context), borderRadius: BorderRadius.circular(12), border: Border.all(color: _dividerColor(context))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              GestureDetector(onTap: () => _showUserDetail(user), child: CircleAvatar(backgroundColor: AppTheme.primary, child: Text(((user['full_name'] as String?)?.isNotEmpty == true ? user['full_name'][0] : 'U').toUpperCase(), style: const TextStyle(color: Colors.white)))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user['full_name'] ?? '-', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _creamColor(context)), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('@${user['username']}', style: TextStyle(fontSize: 12, color: _secondaryTextColor(context)), maxLines: 1, overflow: TextOverflow.ellipsis),
              ])),
              const SizedBox(width: 4),
              _buildStatusIndicator(user['is_online'] ?? false),
              IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.primary), onPressed: () => _showEditUserByManager(user)),
            ]),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _InfoChip(icon: Icons.badge_outlined, label: 'Role', value: _getRoleName(user['role'] ?? 'staff')),
            _InfoChip(icon: Icons.phone_outlined, label: 'No HP', value: user['phone_number'] ?? '-'),
            _InfoChip(icon: Icons.work_outline, label: 'Kantor', value: user['workplace'] ?? '-'),
          ]),
        ]),
      );
    },
  ));

  Widget _buildRoleBadge(String role) {
    Color color = role == 'manager' ? AppTheme.primary : (role == 'staff' ? AppTheme.success : AppTheme.warning);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Text(_getRoleName(role), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStatusIndicator(bool isOnline, {bool showLabel = false}) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: isOnline ? AppTheme.success : AppTheme.textSecondary, shape: BoxShape.circle)),
      if (showLabel) ...[const SizedBox(width: 4), Text(isOnline ? 'Online' : 'Offline', style: TextStyle(fontSize: 11, color: isOnline ? AppTheme.success : AppTheme.textSecondary))],
    ]);
  }

  String _getRoleName(String role) {
    if (role == 'manager') return 'Manager';
    if (role == 'mitra_eks') return 'Mitra';
    return 'Staff';
  }
}

class CreateUserDialog extends StatefulWidget {
  const CreateUserDialog({super.key});
  @override
  State<CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<CreateUserDialog> {
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _workplaceController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _selectedRole = 'staff';
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose(); _fullNameController.dispose(); _phoneController.dispose();
    _workplaceController.dispose(); _passwordController.dispose(); _confirmPasswordController.dispose();
    super.dispose();
  }

  InputDecoration _inputDeco(String label, IconData icon) => InputDecoration(
    labelText: label, prefixIcon: Icon(icon, size: 20),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );

  Future<void> _submit() async {
    final username = _usernameController.text.trim();
    final fullName = _fullNameController.text.trim();
    final password = _passwordController.text;
    if (username.isEmpty || fullName.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Field utama wajib diisi'), backgroundColor: AppTheme.danger));
      return;
    }
    if (password != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password tidak cocok'), backgroundColor: AppTheme.danger));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final success = await context.read<AuthProvider>().createUser(
        username: username, password: password, fullName: fullName, role: _selectedRole,
        phoneNumber: _phoneController.text.trim().isEmpty ? '-' : _phoneController.text.trim(),
        workplace: _workplaceController.text.trim().isEmpty ? '-' : _workplaceController.text.trim(),
      );
      if (success && mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    return AlertDialog(
      backgroundColor: isDark ? AppTheme.card : AppTheme.lightCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Tambah Akun Baru', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(width: screenWidth > 450 ? 400 : screenWidth * 0.9, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 8),
        TextField(controller: _usernameController, decoration: _inputDeco('Username', Icons.person_outline)),
        const SizedBox(height: 16),
        TextField(controller: _fullNameController, decoration: _inputDeco('Nama Lengkap', Icons.badge_outlined)),
        const SizedBox(height: 16),
        TextField(controller: _phoneController, decoration: _inputDeco('No HP', Icons.phone_outlined), keyboardType: TextInputType.phone, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
        const SizedBox(height: 16),
        TextField(controller: _workplaceController, decoration: _inputDeco('Tempat Kerja', Icons.work_outline)),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _selectedRole, dropdownColor: isDark ? AppTheme.card : AppTheme.lightCard,
          items: const [DropdownMenuItem(value: 'staff', child: Text('Staff')), DropdownMenuItem(value: 'mitra_eks', child: Text('Mitra')), DropdownMenuItem(value: 'manager', child: Text('Manager'))],
          onChanged: (v) => setState(() => _selectedRole = v!), decoration: _inputDeco('Role', Icons.admin_panel_settings_outlined),
        ),
        const SizedBox(height: 16),
        TextField(controller: _passwordController, obscureText: _obscurePassword, decoration: _inputDeco('Password', Icons.lock_outline).copyWith(suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)))),
        const SizedBox(height: 16),
        TextField(controller: _confirmPasswordController, obscureText: _obscurePassword, decoration: _inputDeco('Konfirmasi Password', Icons.lock_rounded)),
      ]))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(onPressed: _isLoading ? null : _submit, child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Buat Akun')),
      ],
    );
  }
}

class EditUserByManagerDialog extends StatefulWidget {
  final Map<String, dynamic> user;
  const EditUserByManagerDialog({super.key, required this.user});
  @override
  State<EditUserByManagerDialog> createState() => _EditUserByManagerDialogState();
}

class _EditUserByManagerDialogState extends State<EditUserByManagerDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _workplaceController;
  final _passwordController = TextEditingController();
  late String _selectedRole;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user['full_name']);
    _phoneController = TextEditingController(text: widget.user['phone_number'] == '-' ? '' : widget.user['phone_number']);
    _workplaceController = TextEditingController(text: widget.user['workplace'] == '-' ? '' : widget.user['workplace']);
    _selectedRole = widget.user['role'] ?? 'staff';
  }

  @override
  void dispose() {
    _nameController.dispose(); _phoneController.dispose(); _workplaceController.dispose(); _passwordController.dispose();
    super.dispose();
  }

  InputDecoration _inputDeco(String label, IconData icon) => InputDecoration(
    labelText: label, prefixIcon: Icon(icon, size: 20),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    return AlertDialog(
      backgroundColor: isDark ? AppTheme.card : AppTheme.lightCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Manage User: @${widget.user['username']}', style: const TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(width: screenWidth > 450 ? 400 : screenWidth * 0.9, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 8),
        TextField(controller: _nameController, decoration: _inputDeco('Nama Lengkap', Icons.badge_outlined)),
        const SizedBox(height: 16),
        TextField(controller: _phoneController, decoration: _inputDeco('No HP', Icons.phone_outlined), keyboardType: TextInputType.phone, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
        const SizedBox(height: 16),
        TextField(controller: _workplaceController, decoration: _inputDeco('Tempat Kerja', Icons.work_outline)),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _selectedRole, dropdownColor: isDark ? AppTheme.card : AppTheme.lightCard,
          items: const [DropdownMenuItem(value: 'staff', child: Text('Staff')), DropdownMenuItem(value: 'mitra_eks', child: Text('Mitra')), DropdownMenuItem(value: 'manager', child: Text('Manager'))],
          onChanged: (v) => setState(() => _selectedRole = v!), decoration: _inputDeco('Role', Icons.admin_panel_settings_outlined),
        ),
        const SizedBox(height: 16),
        TextField(controller: _passwordController, decoration: _inputDeco('Reset Password', Icons.lock_reset_rounded).copyWith(hintText: 'Kosongkan jika tidak ubah')),
      ]))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(onPressed: _isLoading ? null : () async {
          final auth = context.read<AuthProvider>();
          final messenger = ScaffoldMessenger.of(context);
          final navigator = Navigator.of(context);
          setState(() => _isLoading = true);
          try {
            final success = await auth.updateUser(widget.user['id'], {
              'full_name': _nameController.text.trim(),
              'phone_number': _phoneController.text.trim().isEmpty ? '-' : _phoneController.text.trim(),
              'workplace': _workplaceController.text.trim().isEmpty ? '-' : _workplaceController.text.trim(),
              'role': _selectedRole,
              'password': _passwordController.text.trim().isEmpty ? null : _passwordController.text.trim(),
            });
            if (!mounted) return;
            if (success) {
              navigator.pop(true);
            }
          } catch (e) {
            messenger.showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger));
          } finally { if (mounted) setState(() => _isLoading = false); }
        }, child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Simpan Perubahan')),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon; final String label; final String value;
  const _InfoChip({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: isDark ? AppTheme.card : AppTheme.lightCard, borderRadius: BorderRadius.circular(8), border: Border.all(color: isDark ? AppTheme.divider : AppTheme.lightDivider)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, size: 12, color: AppTheme.textSecondary), const SizedBox(width: 4), Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary))]),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_layout.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _workplaceController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedRole = 'staff';
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  // Helper untuk theme-aware colors
  bool _isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;
  Color _cardColor(BuildContext context) => _isDark(context) ? AppTheme.card : AppTheme.lightCard;
  Color _creamColor(BuildContext context) => _isDark(context) ? AppTheme.cream : AppTheme.lightTextPrimary;
  Color _dividerColor(BuildContext context) => _isDark(context) ? AppTheme.divider : AppTheme.lightDivider;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _workplaceController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();

    final username = _usernameController.text.trim();
    final fullName = _fullNameController.text.trim();
    final phone = _phoneController.text.trim();
    final workplace = _workplaceController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Validasi
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username tidak boleh kosong'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    if (fullName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama lengkap tidak boleh kosong'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password tidak boleh kosong'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password minimal 6 karakter'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password dan konfirmasi password tidak sama'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      username,
      password,
      fullName,
      _selectedRole,
      phoneNumber: phone.isEmpty ? '-' : phone,
      workplace: workplace.isEmpty ? '-' : workplace,
    );

    if (success && mounted) {
      // Show success dialog
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: _cardColor(ctx),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          icon: const Icon(Icons.check_circle, color: AppTheme.success, size: 64),
          contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Akun Berhasil Dibuat!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _creamColor(ctx),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Silakan login dengan akun yang baru dibuat.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx, true);
                  Navigator.pop(context); // Back to login
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'OK, Login Sekarang',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        Navigator.pop(context); // Back to login
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Registrasi gagal'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isMobile = ResponsiveLayout.isMobile(context);
    final isPhoneLandscape = ResponsiveLayout.isPhoneLandscape(context);
    final isCompact = ResponsiveLayout.shouldUseCompactControls(context);

    final horizontalPadding = ResponsiveLayout.horizontalPadding(context);
    final verticalPadding = ResponsiveLayout.verticalPadding(context);
    final safeWidth = ResponsiveLayout.safeWidth(context);

    final cardMaxWidth = isPhoneLandscape
        ? 780.0
        : isMobile
            ? 440.0
            : 520.0;

    final cardPadding = EdgeInsets.symmetric(
      horizontal: isCompact ? 18 : 28,
      vertical: isCompact ? 18 : 28,
    );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                verticalPadding,
                horizontalPadding,
                verticalPadding +
                    MediaQuery.of(context).viewInsets.bottom +
                    8,
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: cardMaxWidth,
                    minWidth: safeWidth > 8 && safeWidth < 340
                        ? safeWidth - 8
                        : 0,
                  ),
                  child: Container(
                    padding: cardPadding,
                    decoration: BoxDecoration(
                      color: _cardColor(context),
                      borderRadius: BorderRadius.circular(isCompact ? 20 : 24),
                      border: Border.all(color: _dividerColor(context)),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.08),
                          blurRadius: isCompact ? 24 : 36,
                          spreadRadius: 0,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: isPhoneLandscape
                        ? _LandscapeRegisterContent(
                            usernameController: _usernameController,
                            fullNameController: _fullNameController,
                            phoneController: _phoneController,
                            workplaceController: _workplaceController,
                            passwordController: _passwordController,
                            confirmPasswordController: _confirmPasswordController,
                            obscurePassword: _obscurePassword,
                            obscureConfirmPassword: _obscureConfirmPassword,
                            selectedRole: _selectedRole,
                            loading: auth.loading,
                            onToggleObscurePassword: () =>
                                setState(() => _obscurePassword = !_obscurePassword),
                            onToggleObscureConfirmPassword: () =>
                                setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                            onRoleChanged: (value) =>
                                setState(() => _selectedRole = value),
                            onRegister: _register,
                            onBack: () => Navigator.pop(context),
                          )
                        : _PortraitRegisterContent(                            usernameController: _usernameController,
                            fullNameController: _fullNameController,
                            phoneController: _phoneController,
                            workplaceController: _workplaceController,
                            passwordController: _passwordController,
                            confirmPasswordController: _confirmPasswordController,
                            obscurePassword: _obscurePassword,
                            obscureConfirmPassword: _obscureConfirmPassword,
                            selectedRole: _selectedRole,
                            loading: auth.loading,
                            compact: isCompact,
                            onToggleObscurePassword: () =>
                                setState(() => _obscurePassword = !_obscurePassword),
                            onToggleObscureConfirmPassword: () =>
                                setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                            onRoleChanged: (value) =>
                                setState(() => _selectedRole = value),
                            onRegister: _register,
                            onBack: () => Navigator.pop(context),
                          ),
                        ),
                        ),
                        ),
                        ),
                        ),
                        ),
                        ),
                        );
                        }
                        }

                        class _PortraitRegisterContent extends StatelessWidget {
                        final TextEditingController usernameController;
                        final TextEditingController fullNameController;
                        final TextEditingController phoneController;
                        final TextEditingController workplaceController;
                        final TextEditingController passwordController;
                        final TextEditingController confirmPasswordController;
                        final bool obscurePassword;
                        final bool obscureConfirmPassword;
                        final String selectedRole;
                        final bool loading;
                        final bool compact;
                        final VoidCallback onToggleObscurePassword;
                        final VoidCallback onToggleObscureConfirmPassword;
                        final ValueChanged<String> onRoleChanged;
                        final VoidCallback onRegister;
                        final VoidCallback onBack;

                        const _PortraitRegisterContent({
                        required this.usernameController,
                        required this.fullNameController,
                        required this.phoneController,
                        required this.workplaceController,
                        required this.passwordController,
                        required this.confirmPasswordController,
                        required this.obscurePassword,
                        required this.obscureConfirmPassword,
                        required this.selectedRole,
                        required this.loading,
                        required this.compact,
                        required this.onToggleObscurePassword,
                        required this.onToggleObscureConfirmPassword,
                        required this.onRoleChanged,
                        required this.onRegister,
                        required this.onBack,
                        });
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppTheme.cream : AppTheme.lightTextPrimary;
    final subtitleColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final subtitleSize = compact ? 13.0 : 14.0;
    final iconBox = compact ? 72.0 : 84.0;
    final iconSize = compact ? 34.0 : 40.0;
    final spacingLarge = compact ? 20.0 : 24.0;
    final spacingMedium = compact ? 12.0 : 14.0;
    final spacingXL = compact ? 24.0 : 32.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RegisterBrandIcon(size: iconBox, iconSize: iconSize),
        SizedBox(height: spacingLarge),
        Text(
          'Daftar Akun Baru',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Isi form di bawah untuk membuat akun',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: subtitleColor,
            fontSize: subtitleSize,
          ),
        ),
        SizedBox(height: spacingXL),
        _UsernameField(controller: usernameController),
        SizedBox(height: spacingMedium),
        _FullNameField(controller: fullNameController),
        SizedBox(height: spacingMedium),
        _PhoneField(controller: phoneController),
        SizedBox(height: spacingMedium),
        _WorkplaceField(controller: workplaceController),
        SizedBox(height: spacingMedium),
        _PasswordField(
          controller: passwordController,
          obscure: obscurePassword,
          onToggleObscure: onToggleObscurePassword,
        ),
        SizedBox(height: spacingMedium),
        _ConfirmPasswordField(
          controller: confirmPasswordController,
          obscure: obscureConfirmPassword,
          onToggleObscure: onToggleObscureConfirmPassword,
        ),
        SizedBox(height: spacingMedium),
        _RoleDropdown(
          selectedRole: selectedRole,
          onRoleChanged: onRoleChanged,
        ),
        SizedBox(height: spacingXL),
        _RegisterButton(
          loading: loading,
          onPressed: loading ? null : onRegister,
        ),
        SizedBox(height: spacingMedium),
        _BackButton(onBack: onBack),
      ],
    );
  }
}

class _LandscapeRegisterContent extends StatelessWidget {
  final TextEditingController usernameController;
  final TextEditingController fullNameController;
  final TextEditingController phoneController;
  final TextEditingController workplaceController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final String selectedRole;
  final bool loading;
  final VoidCallback onToggleObscurePassword;
  final VoidCallback onToggleObscureConfirmPassword;
  final ValueChanged<String> onRoleChanged;
  final VoidCallback onRegister;
  final VoidCallback onBack;

  const _LandscapeRegisterContent({
    required this.usernameController,
    required this.fullNameController,
    required this.phoneController,
    required this.workplaceController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.selectedRole,
    required this.loading,
    required this.onToggleObscurePassword,
    required this.onToggleObscureConfirmPassword,
    required this.onRoleChanged,
    required this.onRegister,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 9,
          child: Padding(
            padding: EdgeInsets.only(right: 20),
            child: _LandscapeIntroPanel(),
          ),
        ),
        Container(
          width: 1,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          color: AppTheme.divider,
        ),
        Expanded(
          flex: 13,
          child: Padding(
            padding: const EdgeInsets.only(left: 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _UsernameField(controller: usernameController),
                  const SizedBox(height: 12),
                  _FullNameField(controller: fullNameController),
                  const SizedBox(height: 12),
                  _PhoneField(controller: phoneController),
                  const SizedBox(height: 12),
                  _WorkplaceField(controller: workplaceController),
                  const SizedBox(height: 12),
                  _PasswordField(
                    controller: passwordController,
                    obscure: obscurePassword,
                    onToggleObscure: onToggleObscurePassword,
                  ),
                  const SizedBox(height: 12),
                  _ConfirmPasswordField(
                    controller: confirmPasswordController,
                    obscure: obscureConfirmPassword,
                    onToggleObscure: onToggleObscureConfirmPassword,
                  ),
                  const SizedBox(height: 12),
                  _RoleDropdown(
                    selectedRole: selectedRole,
                    onRoleChanged: onRoleChanged,
                  ),
                  const SizedBox(height: 20),
                  _RegisterButton(
                    loading: loading,
                    onPressed: loading ? null : onRegister,
                  ),
                  const SizedBox(height: 12),
                  _BackButton(onBack: onBack, compact: true),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LandscapeIntroPanel extends StatelessWidget {
  const _LandscapeIntroPanel();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const _RegisterBrandIcon(size: 58, iconSize: 30),
        const SizedBox(height: 18),
        const Text(
          'Daftar Akun Baru',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.cream,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Buat akun baru untuk mengakses aplikasi Exspan. Isi form dengan benar dan pilih role sesuai kebutuhan.',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.primary, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Setelah daftar, kamu akan diarahkan ke halaman login.',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RegisterBrandIcon extends StatelessWidget {
  final double size;
  final double iconSize;

  const _RegisterBrandIcon({
    required this.size,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: Center(
        child: Icon(
          Icons.person_add_rounded,
          size: iconSize,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _UsernameField extends StatelessWidget {
  final TextEditingController controller;

  const _UsernameField({required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final iconColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final hintColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;

    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Username',
        labelStyle: TextStyle(color: labelColor),
        prefixIcon: Icon(Icons.person_outline, color: iconColor),
        hintText: 'nama_pengguna',
        hintStyle: TextStyle(color: hintColor),
      ),
      style: TextStyle(color: textColor),
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.username],
    );
  }
}

class _FullNameField extends StatelessWidget {
  final TextEditingController controller;

  const _FullNameField({required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final iconColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final hintColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;

    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Nama Lengkap',
        labelStyle: TextStyle(color: labelColor),
        prefixIcon: Icon(Icons.badge_outlined, color: iconColor),
        hintText: 'Nama Lengkap Anda',
        hintStyle: TextStyle(color: hintColor),
      ),
      style: TextStyle(color: textColor),
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.name],
    );
  }
}

class _PhoneField extends StatelessWidget {
  final TextEditingController controller;

  const _PhoneField({required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final iconColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final hintColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;

    return TextField(
      controller: controller,
      keyboardType: TextInputType.phone,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: 'No HP',
        labelStyle: TextStyle(color: labelColor),
        prefixIcon: Icon(Icons.phone_outlined, color: iconColor),
        hintText: '08xxxxxxxxxx',
        hintStyle: TextStyle(color: hintColor),
      ),
      style: TextStyle(color: textColor),
      textInputAction: TextInputAction.next,
    );
  }
}

class _WorkplaceField extends StatelessWidget {
  final TextEditingController controller;

  const _WorkplaceField({required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final iconColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final hintColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;

    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Tempat Kerja',
        labelStyle: TextStyle(color: labelColor),
        prefixIcon: Icon(Icons.work_outline, color: iconColor),
        hintText: 'Nama Kantor/Instansi',
        hintStyle: TextStyle(color: hintColor),
      ),
      style: TextStyle(color: textColor),
      textInputAction: TextInputAction.next,
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggleObscure;

  const _PasswordField({
    required this.controller,
    required this.obscure,
    required this.onToggleObscure,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final iconColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final hintColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;

    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: 'Password',
        labelStyle: TextStyle(color: labelColor),
        prefixIcon: Icon(Icons.lock_outline, color: iconColor),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
            color: iconColor,
          ),
          onPressed: onToggleObscure,
        ),
        hintText: 'Minimal 6 karakter',
        hintStyle: TextStyle(color: hintColor),
      ),
      style: TextStyle(color: textColor),
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.newPassword],
    );
  }
}

class _ConfirmPasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggleObscure;

  const _ConfirmPasswordField({
    required this.controller,
    required this.obscure,
    required this.onToggleObscure,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final iconColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final hintColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;

    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: 'Konfirmasi Password',
        labelStyle: TextStyle(color: labelColor),
        prefixIcon: Icon(Icons.lock_rounded, color: iconColor),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
            color: iconColor,
          ),
          onPressed: onToggleObscure,
        ),
        hintText: 'Ulangi password',
        hintStyle: TextStyle(color: hintColor),
      ),
      style: TextStyle(color: textColor),
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.newPassword],
      onSubmitted: (_) => onToggleObscure(),
    );
  }
}

class _RoleDropdown extends StatelessWidget {
  final String selectedRole;
  final ValueChanged<String> onRoleChanged;

  const _RoleDropdown({
    required this.selectedRole,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.card : AppTheme.lightCard;
    final surfaceColor = isDark ? AppTheme.surface : AppTheme.lightSurface;
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final secondaryTextColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final dividerColor = isDark ? AppTheme.divider : AppTheme.lightDivider;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: dividerColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedRole,
          isExpanded: true,
          dropdownColor: cardColor,
          style: TextStyle(color: textColor),
          icon: Icon(Icons.arrow_drop_down, color: secondaryTextColor),
          items: const [
            DropdownMenuItem(value: 'staff', child: Text('Staff')),
            DropdownMenuItem(value: 'mitra_eks', child: Text('Mitra')),
          ],
          onChanged: (value) {
            if (value != null) {
              onRoleChanged(value);
            }
          },
        ),
      ),
    );
  }
}

class _RegisterButton extends StatelessWidget {
  final bool loading;
  final VoidCallback? onPressed;

  const _RegisterButton({
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Daftar',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onBack;
  final bool compact;

  const _BackButton({
    required this.onBack,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: onBack,
        icon: const Icon(Icons.arrow_back, size: 18),
        label: Text(
          compact ? 'Kembali ke Login' : 'Sudah punya akun? Kembali ke Login',
          style: const TextStyle(fontSize: 14),
        ),
        style: TextButton.styleFrom(
          foregroundColor: AppTheme.textSecondary,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_layout.dart';
import '../../widgets/app_brand_logo.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _serverUrlController = TextEditingController();

  bool _obscure = true;
  String _currentServerUrl = ApiService.baseUrl;
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
    _loadServerUrl();
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
    _passwordController.dispose();
    _serverUrlController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadServerUrl() async {
    await ApiService.loadSavedBaseUrl();
    if (!mounted) return;
    setState(() {
      _currentServerUrl = ApiService.baseUrl;
      _serverUrlController.text = _currentServerUrl;
    });
  }

  Future<void> _showServerUrlDialog() async {
    _serverUrlController.text = _currentServerUrl;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Server URL',
          style: TextStyle(color: _creamColor(context)),
        ),
        content: TextField(
          controller: _serverUrlController,
          decoration: const InputDecoration(
            labelText: 'API Base URL',
            hintText: 'http://192.168.1.8:5000/api',
          ),
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await ApiService.saveBaseUrl('');
              if (!mounted) return;
              setState(() => _currentServerUrl = ApiService.baseUrl);
              Navigator.of(this.context).pop();
            },
            child: const Text('Default'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ApiService.saveBaseUrl(_serverUrlController.text);
              if (!mounted) return;
              setState(() => _currentServerUrl = ApiService.baseUrl);
              Navigator.of(this.context).pop();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    // Validate input
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username tidak boleh kosong'),
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

    final auth = context.read<AuthProvider>();
    final success = await auth.login(username, password);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Login gagal'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  void _navigateToRegister(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
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
        ? 680.0
        : isMobile
            ? 440.0
            : 480.0;

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
                        ? _LandscapeLoginContent(
                            usernameController: _usernameController,
                            passwordController: _passwordController,
                            obscure: _obscure,
                            loading: auth.loading,
                            onToggleObscure: () =>
                                setState(() => _obscure = !_obscure),
                            onLogin: _login,
                            onRegister: () => _navigateToRegister(context),
                            serverUrl: _currentServerUrl,
                            onConfigureServer: _showServerUrlDialog,
                          )
                        : _PortraitLoginContent(
                            usernameController: _usernameController,
                            passwordController: _passwordController,
                            obscure: _obscure,
                            loading: auth.loading,
                            compact: isCompact,
                            onToggleObscure: () =>
                                setState(() => _obscure = !_obscure),
                            onLogin: _login,
                            onRegister: () => _navigateToRegister(context),
                            serverUrl: _currentServerUrl,
                            onConfigureServer: _showServerUrlDialog,
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

class _PortraitLoginContent extends StatelessWidget {
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool obscure;
  final bool loading;
  final bool compact;
  final VoidCallback onToggleObscure;
  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final String serverUrl;
  final VoidCallback onConfigureServer;

  const _PortraitLoginContent({
    required this.usernameController,
    required this.passwordController,
    required this.obscure,
    required this.loading,
    required this.compact,
    required this.onToggleObscure,
    required this.onLogin,
    required this.onRegister,
    required this.serverUrl,
    required this.onConfigureServer,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleSize = compact ? 21.0 : 24.0;
    final subtitleSize = compact ? 13.0 : 14.0;
    final iconBox = compact ? 72.0 : 84.0;
    final iconSize = compact ? 34.0 : 40.0;
    final spacingLarge = compact ? 20.0 : 24.0;
    final spacingMedium = compact ? 14.0 : 16.0;
    final spacingXL = compact ? 24.0 : 32.0;
    // Warna teks yang jelas untuk Light & Dark mode
    final titleColor = isDark ? AppTheme.cream : AppTheme.lightTextPrimary;
    final subtitleColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LoginBrandIcon(size: iconBox, iconSize: iconSize),
        SizedBox(height: spacingLarge),
        Text(
          'ExspanApp',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.w700,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Masuk untuk melanjutkan',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: subtitleColor,
            fontSize: subtitleSize,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onConfigureServer,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              _serverLabel(serverUrl),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.accent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(height: spacingXL),
        _UsernameField(controller: usernameController),
        SizedBox(height: spacingMedium),
        _PasswordField(
          controller: passwordController,
          obscure: obscure,
          onToggleObscure: onToggleObscure,
          onSubmitted: onLogin,
        ),
        SizedBox(height: compact ? 24 : 28),
        _LoginButton(
          loading: loading,
          onPressed: loading ? null : onLogin,
        ),
        SizedBox(height: spacingMedium),
        _RegisterLink(onTap: onRegister),
        SizedBox(height: spacingMedium),
        const _LoginHintCard(),
      ],
    );
  }
}

class _LandscapeLoginContent extends StatelessWidget {
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool obscure;
  final bool loading;
  final VoidCallback onToggleObscure;
  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final String serverUrl;
  final VoidCallback onConfigureServer;

  const _LandscapeLoginContent({
    required this.usernameController,
    required this.passwordController,
    required this.obscure,
    required this.loading,
    required this.onToggleObscure,
    required this.onLogin,
    required this.onRegister,
    required this.serverUrl,
    required this.onConfigureServer,
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
            child: _LandscapeIntroPanel(
              serverUrl: serverUrl,
              onConfigureServer: onConfigureServer,
            ),
          ),
        ),
        Container(
          width: 1,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          color: AppTheme.divider,
        ),
        Expanded(
          flex: 11,
          child: Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _UsernameField(controller: usernameController),
                const SizedBox(height: 14),
                _PasswordField(
                  controller: passwordController,
                  obscure: obscure,
                  onToggleObscure: onToggleObscure,
                  onSubmitted: onLogin,
                ),
                const SizedBox(height: 24),
                _LoginButton(
                  loading: loading,
                  onPressed: loading ? null : onLogin,
                ),
                const SizedBox(height: 14),
                _RegisterLink(onTap: onRegister, compact: true),
                const SizedBox(height: 14),
                const _LoginHintCard(compact: true),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LandscapeIntroPanel extends StatelessWidget {
  final String serverUrl;
  final VoidCallback onConfigureServer;

  const _LandscapeIntroPanel({
    required this.serverUrl,
    required this.onConfigureServer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const _LoginBrandIcon(size: 58, iconSize: 30),
        const SizedBox(height: 18),
        const Text(
          'ExspanApp',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.cream,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Masuk untuk mengelola settlement, kasbon, laporan, dan pengaturan dengan tampilan yang aman untuk Android portrait maupun landscape.',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: onConfigureServer,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              _serverLabel(serverUrl),
              style: const TextStyle(
                color: AppTheme.accent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

String _serverLabel(String serverUrl) => 'Server: $serverUrl (tap untuk ubah)';

class _LoginBrandIcon extends StatelessWidget {
  final double size;
  final double iconSize;

  const _LoginBrandIcon({
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
        child: AppBrandLogo(size: iconSize + 10),
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
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;

    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Username',
        labelStyle: TextStyle(color: labelColor),
        prefixIcon: Icon(
          Icons.person_outline,
          color: iconColor,
        ),
      ),
      style: TextStyle(color: textColor),
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.username],
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmitted;

  const _PasswordField({
    required this.controller,
    required this.obscure,
    required this.onToggleObscure,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final iconColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;

    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: 'Password',
        labelStyle: TextStyle(color: labelColor),
        prefixIcon: Icon(
          Icons.lock_outline,
          color: iconColor,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
            color: iconColor,
          ),
          onPressed: onToggleObscure,
        ),
      ),
      style: TextStyle(color: textColor),
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.password],
      onSubmitted: (_) => onSubmitted(),
    );
  }
}

class _LoginButton extends StatelessWidget {
  final bool loading;
  final VoidCallback? onPressed;

  const _LoginButton({
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
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text('Masuk'),
      ),
    );
  }
}

class _RegisterLink extends StatelessWidget {
  final VoidCallback onTap;
  final bool compact;

  const _RegisterLink({
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(
          compact ? 'Daftar Akun Baru' : 'Belum punya akun? Daftar sekarang',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.accent,
          ),
        ),
      ),
    );
  }
}

class _LoginHintCard extends StatelessWidget {
  final bool compact;

  const _LoginHintCard({this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: AppTheme.accent,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'EWIAPPS',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

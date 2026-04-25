import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool _rememberMe = false;
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
    _loadSavedCredentials();
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

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('saved_username');
    final savedPassword = prefs.getString('saved_password');
    final remember = prefs.getBool('remember_me') ?? false;

    if (remember && mounted) {
      setState(() {
        _rememberMe = true;
        if (savedUsername != null) _usernameController.text = savedUsername;
        if (savedPassword != null) _passwordController.text = savedPassword;
      });
    }
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
          style: TextStyle(color: _isDark(context) ? AppTheme.textPrimary : AppTheme.lightTextPrimary),
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

    if (success) {
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setBool('remember_me', true);
        await prefs.setString('saved_username', username);
        await prefs.setString('saved_password', password);
      } else {
        await prefs.setBool('remember_me', false);
        await prefs.remove('saved_username');
        await prefs.remove('saved_password');
      }
    } else if (mounted) {
      String errorMessage = auth.error ?? 'Login gagal';

      // Jika error mengandung indikasi kegagalan jaringan
      if (errorMessage.toLowerCase().contains('timeout') ||
          errorMessage.toLowerCase().contains('semaphore') ||
          errorMessage.toLowerCase().contains('socket') ||
          errorMessage.toLowerCase().contains('refused')) {
        errorMessage = "Gagal terhubung ke Server. Pastikan Alamat Server (IP) sudah benar.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppTheme.danger,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'CEK IP',
            textColor: Colors.white,
            onPressed: () {
              // Scroll ke widget server setting jika ada
            },
          ),
        ),
      );
    }
  }

  void _navigateToRegister(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }

  void _showMessage(
    String message, {
    Color backgroundColor = AppTheme.danger,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  Future<void> _handleGoogleLogin() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isGoogleSignInSupported) {
      _showMessage(
        'Login Gmail belum tersedia di perangkat ini. Gunakan username dan password.',
      );
      return;
    }

    final result = await auth.loginWithGoogle();
    if (!mounted) return;

    if (result != null && result['new_user'] == true) {
      // User belum terdaftar, tanya dulu mau daftar atau tidak
      if (!mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: _cardColor(ctx),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Akun Tidak Ditemukan'),
          content: Text(
            'Email ${result['email']} belum terdaftar di aplikasi. Apakah Anda ingin membuat akun baru menggunakan Gmail ini?',
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Ya, Daftar Sekarang'),
            ),
          ],
        ),
      );

      if (confirm == true && mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RegisterScreen(
              initialEmail: result['email']?.toString(),
              initialFullName: result['full_name']?.toString(),
              initialGoogleId: result['google_id']?.toString(),
              lockEmail: true,
            ),
          ),
        );
      }
      return;
    }

    if (result == null && auth.error != null) {
      _showMessage(auth.error!);
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final auth = context.read<AuthProvider>();
    final emailController = TextEditingController();
    final otpController = TextEditingController();
    final newPasswordController = TextEditingController();

    var otpSent = false;
    var obscureNewPassword = true;
    var busy = false;

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (dialogContext, setModalState) {
              Future<void> submit() async {
                final navigator = Navigator.of(dialogContext);
                final email = emailController.text.trim();
                final otp = otpController.text.trim();
                final newPassword = newPasswordController.text;

                if (email.isEmpty) {
                  _showMessage('Email wajib diisi.');
                  return;
                }

                if (!email.contains('@')) {
                  _showMessage('Masukkan email yang valid.');
                  return;
                }

                if (otpSent) {
                  if (otp.isEmpty) {
                    _showMessage('Kode OTP wajib diisi.');
                    return;
                  }
                  if (newPassword.length < 6) {
                    _showMessage('Password baru minimal 6 karakter.');
                    return;
                  }
                }

                setModalState(() => busy = true);

                if (!otpSent) {
                  final success = await auth.forgotPassword(email);
                  if (!mounted) return;

                  setModalState(() {
                    busy = false;
                    if (success) {
                      otpSent = true;
                    }
                  });

                  if (success) {
                    _showMessage(
                      'Jika email terdaftar, kode OTP akan dikirim ke email tersebut.',
                      backgroundColor: AppTheme.accent,
                    );
                  } else {
                    _showMessage(auth.error ?? 'Gagal mengirim kode OTP.');
                  }
                  return;
                }

                final success = await auth.resetPassword(
                  email: email,
                  otp: otp,
                  newPassword: newPassword,
                );
                if (!mounted) return;

                setModalState(() => busy = false);

                if (success) {
                  navigator.pop();
                  _showMessage(
                    'Password berhasil diganti. Silakan login kembali.',
                    backgroundColor: AppTheme.success,
                  );
                } else {
                  _showMessage(auth.error ?? 'Reset password gagal.');
                }
              }

              return AlertDialog(
                backgroundColor: _cardColor(dialogContext),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                title: Text(
                  otpSent ? 'Reset Password' : 'Lupa Password',
                  style: TextStyle(color: _creamColor(dialogContext)),
                ),
                content: SizedBox(
                  width: 380,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        otpSent
                            ? 'Masukkan OTP dari email dan password baru Anda.'
                            : 'Masukkan email yang terdaftar pada akun Anda untuk menerima OTP.',
                        style: TextStyle(
                          color: _isDark(dialogContext)
                              ? AppTheme.textSecondary
                              : AppTheme.lightTextSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: emailController,
                        enabled: !busy,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction:
                            otpSent ? TextInputAction.next : TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      if (otpSent) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: otpController,
                          enabled: !busy,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Kode OTP',
                            prefixIcon: Icon(Icons.verified_user_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: newPasswordController,
                          enabled: !busy,
                          obscureText: obscureNewPassword,
                          decoration: InputDecoration(
                            labelText: 'Password Baru',
                            prefixIcon: const Icon(Icons.lock_reset_outlined),
                            suffixIcon: IconButton(
                              onPressed: busy
                                  ? null
                                  : () => setModalState(
                                        () => obscureNewPassword =
                                            !obscureNewPassword,
                                      ),
                              icon: Icon(
                                obscureNewPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                            ),
                          ),
                          onSubmitted: (_) => submit(),
                        ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: busy
                        ? null
                        : () => Navigator.of(dialogContext).pop(),
                    child: const Text('Batal'),
                  ),
                  ElevatedButton(
                    onPressed: busy ? null : submit,
                    child: busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(otpSent ? 'Reset Password' : 'Kirim OTP'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      emailController.dispose();
      otpController.dispose();
      newPasswordController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isMobile = ResponsiveLayout.isMobile(context);
    final isCompact = ResponsiveLayout.shouldUseCompactControls(context);
    final screenHeight = MediaQuery.of(context).size.height;

    final horizontalPadding = ResponsiveLayout.horizontalPadding(context);

    final cardMaxWidth = isMobile
        ? 440.0
        : 760.0; // Izinkan lebih lebar di Desktop/Tablet agar dua kolom muat

    final cardPadding = EdgeInsets.symmetric(
      horizontal: isCompact ? 18 : 32,
      vertical: isCompact ? 18 : 32,
    );

    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 16,
                ).add(EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom)),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: cardMaxWidth,
                    minWidth: 300,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _cardColor(context),
                      borderRadius: BorderRadius.circular(isCompact ? 20 : 28),
                      border: Border.all(color: _dividerColor(context).withValues(alpha: 0.8)),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.12),
                          blurRadius: isCompact ? 24 : 40,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: cardPadding.copyWith(bottom: 0),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // LOGIKA PINTAR:
                              // Jika Lebar > 500 ATAU Tinggi Layar < 600, gunakan mode Samping-sampingan (Tab)
                              // Ini agar footer tidak terpotong saat jendela pendek.
                              if (constraints.maxWidth > 500 || screenHeight < 600) {
                                return _LandscapeLoginContent(
                                  usernameController: _usernameController,
                                  passwordController: _passwordController,
                                  obscure: _obscure,
                                  loading: auth.loading,
                                  rememberMe: _rememberMe,
                                  onRememberMeChanged: (v) => setState(() => _rememberMe = v ?? false),
                                  onToggleObscure: () => setState(() => _obscure = !_obscure),
                                  onLogin: _login,
                                  onForgotPassword: _showForgotPasswordDialog,
                                  onRegister: () => _navigateToRegister(context),
                                  serverUrl: _currentServerUrl,
                                  onConfigureServer: _showServerUrlDialog,
                                );
                              }
                              // Mode Portrait Standar untuk layar HP yang tinggi
                              return _PortraitLoginContent(
                                usernameController: _usernameController,
                                passwordController: _passwordController,
                                obscure: _obscure,
                                loading: auth.loading,
                                compact: isCompact || screenHeight < 700,
                                rememberMe: _rememberMe,
                                onRememberMeChanged: (v) => setState(() => _rememberMe = v ?? false),
                                onToggleObscure: () => setState(() => _obscure = !_obscure),
                                onLogin: _login,
                                onForgotPassword: _showForgotPasswordDialog,
                                onRegister: () => _navigateToRegister(context),
                                serverUrl: _currentServerUrl,
                                onConfigureServer: _showServerUrlDialog,
                              );
                            },
                          ),
                        ),
                        // Tidak ada Divider di sini
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Atau masuk dengan",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _isDark(context) ? AppTheme.textSecondary : Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _GmailLoginButton(
                                onPressed: _handleGoogleLogin,
                                enabled: auth.isGoogleSignInSupported,
                              ),
                              const SizedBox(height: 14),
                              const _LoginHintCard(),
                            ],
                          ),
                        ),
                      ],
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

class _LoginHintCard extends StatelessWidget {
  const _LoginHintCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? Colors.transparent : AppTheme.lightDivider),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 14, color: AppTheme.accent.withValues(alpha: 0.9)),
          const SizedBox(width: 8),
          Text(
            'EWIAPPS',
            style: TextStyle(
              fontSize: 10,
              color: isDark ? AppTheme.textPrimary : Colors.black87,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
        ],
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
  final bool rememberMe;
  final ValueChanged<bool?> onRememberMeChanged;
  final VoidCallback onToggleObscure;
  final VoidCallback onLogin;
  final VoidCallback onForgotPassword;
  final VoidCallback onRegister;
  final String serverUrl;
  final VoidCallback onConfigureServer;

  const _PortraitLoginContent({
    required this.usernameController,
    required this.passwordController,
    required this.obscure,
    required this.loading,
    required this.compact,
    required this.rememberMe,
    required this.onRememberMeChanged,
    required this.onToggleObscure,
    required this.onLogin,
    required this.onForgotPassword,
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Remember Me
            InkWell(
              onTap: () => onRememberMeChanged(!rememberMe),
              borderRadius: BorderRadius.circular(8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: rememberMe,
                      onChanged: onRememberMeChanged,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Ingat Saya',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Forgot Password
            TextButton(
              onPressed: onForgotPassword,
              child: const Text(
                'Lupa password?',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.accent,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 12 : 16),
        _LoginButton(
          loading: loading,
          onPressed: loading ? null : onLogin,
        ),
        SizedBox(height: spacingMedium),
        _RegisterLink(onTap: onRegister),
      ],
    );
  }
}

class _GmailLoginButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool enabled;

  const _GmailLoginButton({
    required this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        customBorder: const CircleBorder(),
        child: Opacity(
          opacity: enabled ? 1.0 : 0.5,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? AppTheme.divider : AppTheme.lightDivider,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Image.network(
                'https://www.gstatic.com/images/branding/product/2x/googleg_96dp.png',
                width: 24,
                height: 24,
                fit: BoxFit.contain,
                errorBuilder: (ctx, _, error) => Icon(
                  Icons.g_mobiledata_rounded,
                  size: 30,
                  color: enabled ? AppTheme.primary : AppTheme.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _serverLabel(String serverUrl) => 'Server: $serverUrl (tap untuk ubah)';

class _LandscapeLoginContent extends StatelessWidget {
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool obscure;
  final bool loading;
  final bool rememberMe;
  final ValueChanged<bool?> onRememberMeChanged;
  final VoidCallback onToggleObscure;
  final VoidCallback onLogin;
  final VoidCallback onForgotPassword;
  final VoidCallback onRegister;
  final String serverUrl;
  final VoidCallback onConfigureServer;

  const _LandscapeLoginContent({
    required this.usernameController,
    required this.passwordController,
    required this.obscure,
    required this.loading,
    required this.rememberMe,
    required this.onRememberMeChanged,
    required this.onToggleObscure,
    required this.onLogin,
    required this.onForgotPassword,
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
            padding: const EdgeInsets.only(right: 20),
            child: _LandscapeIntroPanel(
              serverUrl: serverUrl,
              onConfigureServer: onConfigureServer,
            ),
          ),
        ),
        Container(
          width: 1,
          height: 300,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          color: AppTheme.divider.withValues(alpha: 0.5),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Remember Me
                    InkWell(
                      onTap: () => onRememberMeChanged(!rememberMe),
                      borderRadius: BorderRadius.circular(8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: Checkbox(
                              value: rememberMe,
                              onChanged: onRememberMeChanged,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text('Ingat Saya', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    // Forgot Password
                    TextButton(
                      onPressed: onForgotPassword,
                      child: const Text('Lupa password?', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _LoginButton(
                  loading: loading,
                  onPressed: loading ? null : onLogin,
                ),
                const SizedBox(height: 14),
                _RegisterLink(onTap: onRegister),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const _LoginBrandIcon(size: 58, iconSize: 30),
        const SizedBox(height: 18),
        Text(
          'ExspanApp',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: isDark ? AppTheme.cream : AppTheme.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Masuk untuk mengelola settlement, kasbon, laporan, dan pengaturan dengan tampilan yang aman dan responsif.',
          style: TextStyle(
            color: isDark ? AppTheme.textSecondary : Colors.black87,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
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
    final hintColor = isDark
        ? AppTheme.textSecondary.withValues(alpha: 0.6)
        : AppTheme.lightTextSecondary.withValues(alpha: 0.6);

    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Username atau Email',
        labelStyle: TextStyle(color: labelColor),
        prefixIcon: Icon(
          Icons.person_outline,
          color: iconColor,
        ),
        hintText: 'user_atau_email@gmail.com',
        hintStyle: TextStyle(color: hintColor),
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

  const _RegisterLink({
    required this.onTap,
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
        child: const Text(
          'Belum punya akun? Daftar sekarang',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.accent,
          ),
        ),
      ),
    );
  }
}

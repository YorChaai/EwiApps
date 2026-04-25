import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  String? _token;
  Map<String, dynamic>? _user;
  bool _loading = false;
  String? _error;

  ApiService get api => _api;
  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isLoggedIn => _token != null;
  bool get isManager => _user?['role'] == 'manager';
  bool get isStaff => _user?['role'] == 'staff';
  bool get isMitraEks => _user?['role'] == 'mitra_eks';
  String get fullName => _user?['full_name'] ?? '';
  String get role => _user?['role'] ?? '';
  String? get profileImageUrl {
    if (_user?['profile_image'] == null) return null;
    return '${ApiService.baseUrl}/uploads/${_user?['profile_image']}';
  }
  String get roleDisplayName {
    switch (_user?['role']) {
      case 'manager':
        return 'Manager';
      case 'staff':
        return 'Staff';
      case 'mitra_eks':
        return 'Mitra Eksternal';
      default:
        return _user?['role'] ?? '';
    }
  }

  bool _disposed = false;
  bool get disposed => _disposed;

  bool get loading => _loading;
  String? get error => _error;
  bool get isGoogleSignInSupported {
    if (kIsWeb) return true;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android || TargetPlatform.iOS || TargetPlatform.macOS => true,
      _ => false,
    };
  }

  AuthProvider() {
    _loadToken();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _loadToken() async {
    await ApiService.loadSavedBaseUrl();
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');

    if (_token != null && !_disposed) {
      // refresh user dari api
      try {
        _api.setToken(_token);
        final res = await _api.getMe();
        if (!_disposed) {  // Check again after async
          _user = res['user'];
        }
      } catch (_) {
      // token expired atau koneksi gagal
        if (!_disposed) {
          await logout();
        }
        return;
      }
      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  Future<bool> login(String username, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.login(username, password);
      _token = res['token'];
      _user = res['user'];
      _api.setToken(_token);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);

      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>?> loginWithGoogle() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      if (!isGoogleSignInSupported) {
        throw Exception(
          'Login Gmail belum didukung di perangkat ini. Gunakan login username/password.',
        );
      }

      // 1. Sign in with Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _loading = false;
        notifyListeners();
        return null; // User cancelled
      }

      // 2. Get ID Token
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Gagal mendapatkan ID Token dari Google');
      }

      // 3. Send token to backend
      final res = await _api.googleLogin(idToken);

      if (res['new_user'] == true) {
        _loading = false;
        notifyListeners();
        return res; // Registration info for new user
      }

      // 4. Handle successful login
      _token = res['token'];
      _user = res['user'];
      _api.setToken(_token);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);

      _loading = false;
      notifyListeners();
      return {'success': true};
    } on MissingPluginException {
      _error =
          'Login Gmail belum tersedia di platform ini. Gunakan login username/password.';
      _loading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _loading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> forgotPassword(String email) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.forgotPassword(email);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.resetPassword(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(
    String username,
    String password,
    String fullName,
    String role, {
    String? email,
    String? googleId,
    String? phoneNumber,
    String? workplace,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.register(
        username,
        password,
        fullName,
        role,
        email: email,
        googleId: googleId,
        phoneNumber: phoneNumber,
        workplace: workplace,
      );
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _loading = false;
      notifyListeners();
      return false;
    }
  }
  Future<bool> createUser({
    required String username,
    required String password,
    required String fullName,
    required String role,
    String? phoneNumber,
    String? workplace,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.createUser(
        username: username,
        password: password,
        fullName: fullName,
        role: role,
        phoneNumber: phoneNumber,
        workplace: workplace,
      );
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final res = await _api.getUsers();
      return List<Map<String, dynamic>>.from(res['users'] ?? []);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return [];
    }
  }

  Future<bool> updateUser(int userId, Map<String, dynamic> data) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.updateUser(
        userId,
        fullName: data['full_name'],
        phoneNumber: data['phone_number'],
        workplace: data['workplace'],
        role: data['role'],
        password: data['password'],
      );
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data, {String? imagePath, bool removeImage = false}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.updateProfile(
        fullName: data['full_name'],
        phoneNumber: data['phone_number'],
        workplace: data['workplace'],
        oldPassword: data['old_password'],
        newPassword: data['new_password'],
        profileImagePath: imagePath,
        removeProfileImage: removeImage,
      );
      _user = res['user'];
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  void updateUserData(Map<String, dynamic> userData) {
    _user = userData;
    notifyListeners();
  }

  Future<bool> linkGoogleAccount() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      if (!isGoogleSignInSupported) {
        throw Exception('Fitur ini belum didukung di perangkat ini.');
      }

      final googleSignIn = GoogleSignIn();
      final account = await googleSignIn.signIn();
      if (account == null) {
        _loading = false;
        notifyListeners();
        return false;
      }

      final auth = await account.authentication;
      if (auth.idToken == null) {
        throw Exception('Gagal mendapatkan ID Token dari Google');
      }

      final res = await _api.linkGoogleAccount(auth.idToken!);
      _user = res['user'];

      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> unlinkGoogleAccount() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.unlinkGoogleAccount();
      _user = res['user'];

      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_data');
    notifyListeners();
  }
}

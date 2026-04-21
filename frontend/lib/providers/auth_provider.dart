import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
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

  Future<bool> register(String username, String password, String fullName, String role, {String? phoneNumber, String? workplace}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.register(username, password, fullName, role, phoneNumber: phoneNumber, workplace: workplace);
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

  void updateUserData(Map<String, dynamic> userData) {
    _user = userData;
    notifyListeners();
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

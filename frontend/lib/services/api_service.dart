import 'dart:convert';
import 'dart:async';
import 'dart:io' show Platform, HttpException, SocketException;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  static const String _baseUrlPrefsKey = 'api_base_url';
  static String? _runtimeBaseUrl;

  static const Duration _requestTimeout = Duration(seconds: 30);
  static const int _maxRetries = 2;

  /// Helper untuk build URL dengan query parameters menggunakan StringBuffer
  static String _buildUrl(String baseUrl, List<String> params) {
    if (params.isEmpty) return baseUrl;
    final buffer = StringBuffer(baseUrl);
    buffer.write('?');
    buffer.write(params.join('&'));
    return buffer.toString();
  }

  /// Helper untuk retry request jika terjadi connection reset
  static Future<http.Response> _retryRequest(
    Future<http.Response> Function() requestFn,
  ) async {
    int attempts = 0;
    Exception lastException = Exception('Unknown error');

    while (attempts <= _maxRetries) {
      try {
        return await requestFn().timeout(_requestTimeout);
      } on http.ClientException catch (e) {
        lastException = Exception('Connection error: ${e.message}');
        attempts++;
      } on TimeoutException catch (e) {
        lastException = Exception('Request timeout: ${e.message}');
        attempts++;
      } on HttpException catch (e) {
        lastException = Exception('HTTP error: ${e.message}');
        attempts++;
      } on SocketException catch (e) {
        lastException = Exception('Network error: ${e.message}');
        attempts++;
      } catch (e) {
        lastException = Exception('Unexpected error: $e');
        rethrow;
      }

      if (attempts <= _maxRetries) {
        await Future.delayed(Duration(milliseconds: 500 * attempts));
      }
    }

    throw lastException;
  }

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl;
    }
    if (_runtimeBaseUrl != null && _runtimeBaseUrl!.isNotEmpty) {
      return _runtimeBaseUrl!;
    }
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    }
    if (Platform.isAndroid) {
      // Untuk HP Android fisik, gunakan IP jaringan lokal
      return 'http://192.168.68.59:5000/api';
    }
    return 'http://localhost:5000/api';
  }

  static Future<void> loadSavedBaseUrl() async {
    if (_configuredBaseUrl.isNotEmpty) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    _runtimeBaseUrl = prefs.getString(_baseUrlPrefsKey);
  }

  static Future<void> saveBaseUrl(String url) async {
    if (_configuredBaseUrl.isNotEmpty) {
      return;
    }
    final normalized = url.trim().replaceAll(RegExp(r'/$'), '');
    final prefs = await SharedPreferences.getInstance();
    if (normalized.isEmpty) {
      _runtimeBaseUrl = null;
      await prefs.remove(_baseUrlPrefsKey);
      return;
    }
    _runtimeBaseUrl = normalized;
    await prefs.setString(_baseUrlPrefsKey, normalized);
  }

  String? _token;
  Future<void>? _tokenLoadingFuture;

  ApiService() {
    // Start loading token in background, but don't wait
    _tokenLoadingFuture = _loadTokenFromStorage();
  }

  Future<void> _loadTokenFromStorage() async {
    if (_token != null) return; // Already loaded
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');
    } catch (_) {
      // Silent fail if SharedPreferences not available
    }
  }

  // Ensure token is loaded (public method for services)
  Future<void> ensureTokenLoaded() async {
    if (_tokenLoadingFuture != null) {
      await _tokenLoadingFuture;
    }
  }

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Map<String, String> get _authHeaders => {
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // Public getter for auth headers
  Map<String, String> getAuthHeaders() => _authHeaders;

  // auth

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final res = await _retryRequest(
        () => http.post(
          Uri.parse('$baseUrl/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'username': username, 'password': password}),
        ),
      );
      return _handleResponse(res);
    } on TimeoutException {
      throw Exception(_networkHint('Koneksi ke server timeout'));
    } on http.ClientException {
      throw Exception(_networkHint('Tidak bisa terhubung ke server'));
    }
  }

  Future<Map<String, dynamic>> register(
    String username,
    String password,
    String fullName,
    String role, {
    String? phoneNumber,
    String? workplace,
  }) async {
    try {
      final res = await _retryRequest(
        () => http.post(
          Uri.parse('$baseUrl/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': username,
            'password': password,
            'full_name': fullName,
            'role': role,
            'phone_number': phoneNumber,
            'workplace': workplace,
          }),
        ),
      );
      return _handleResponse(res);
    } on TimeoutException {
      throw Exception(_networkHint('Koneksi ke server timeout'));
    } on http.ClientException {
      throw Exception(_networkHint('Tidak bisa terhubung ke server'));
    }
  }

  Future<Map<String, dynamic>> getMe() async {
    final res = await _retryRequest(
      () => http.get(Uri.parse('$baseUrl/auth/me'), headers: _headers),
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> getUsers() async {
    final res = await _retryRequest(
      () => http.get(Uri.parse('$baseUrl/auth/users'), headers: _headers),
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> createUser({
    required String username,
    required String password,
    required String fullName,
    required String role,
    String? phoneNumber,
    String? workplace,
  }) async {
    final res = await _retryRequest(
      () => http.post(
        Uri.parse('$baseUrl/auth/users'),
        headers: _headers,
        body: jsonEncode({
          'username': username,
          'password': password,
          'full_name': fullName,
          'role': role,
          'phone_number': phoneNumber,
          'workplace': workplace,
        }),
      ),
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? workplace,
    String? oldPassword,
    String? newPassword,
    String? profileImagePath,
    bool removeProfileImage = false,
  }) async {
    var request = http.MultipartRequest(
      'PUT',
      Uri.parse('$baseUrl/auth/profile'),
    );
    request.headers.addAll(_authHeaders);

    if (fullName != null) request.fields['full_name'] = fullName;
    if (phoneNumber != null) request.fields['phone_number'] = phoneNumber;
    if (workplace != null) request.fields['workplace'] = workplace;
    if (oldPassword != null) request.fields['old_password'] = oldPassword;
    if (newPassword != null) request.fields['new_password'] = newPassword;
    if (removeProfileImage) request.fields['remove_profile_image'] = 'true';

    if (profileImagePath != null) {
      request.files.add(
        await http.MultipartFile.fromPath('profile_image', profileImagePath),
      );
    }

    final streamedRes = await request.send();
    final res = await http.Response.fromStream(streamedRes);
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> updateUser(
    int userId, {
    String? fullName,
    String? phoneNumber,
    String? workplace,
    String? role,
    String? password,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['full_name'] = fullName;
    if (phoneNumber != null) body['phone_number'] = phoneNumber;
    if (workplace != null) body['workplace'] = workplace;
    if (role != null) body['role'] = role;
    if (password != null) body['password'] = password;

    final res = await _retryRequest(
      () => http.put(
        Uri.parse('$baseUrl/auth/users/$userId'),
        headers: _headers,
        body: jsonEncode(body),
      ),
    );
    return _handleResponse(res);
  }
  // settlements

  Future<Map<String, dynamic>> getSettlements({
    String? status,
    String? startDate,
    String? endDate,
    String? type,
    int? reportYear,
    String? search,
  }) async {
    final params = <String>[];
    if (status != null) params.add('status=$status');
    if (startDate != null) params.add('start_date=$startDate');
    if (endDate != null) params.add('end_date=$endDate');
    if (type != null) params.add('type=$type');
    if (reportYear != null) params.add('report_year=$reportYear');
    if (search != null && search.isNotEmpty) {
      params.add('search=${Uri.encodeComponent(search)}');
    }

    final url = _buildUrl('$baseUrl/settlements', params);
    final res = await _retryRequest(
      () => http.get(Uri.parse(url), headers: _headers),
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> getSettlement(int id) async {
    final res = await _retryRequest(
      () => http.get(Uri.parse('$baseUrl/settlements/$id'), headers: _headers),
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> createSettlement(
    String title,
    String description, {
    int? advanceId,
    String settlementType = 'single',
    int? reportYear,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'description': description,
      'settlement_type': settlementType,
    };
    if (advanceId != null) {
      body['advance_id'] = advanceId;
    }
    if (reportYear != null) {
      body['report_year'] = reportYear;
    }
    final res = await http.post(
      Uri.parse('$baseUrl/settlements'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> updateSettlement(
    int id, {
    String? title,
    String? description,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    final res = await http.put(
      Uri.parse('$baseUrl/settlements/$id'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> deleteSettlement(int id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/settlements/$id'),
      headers: _headers,
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> submitSettlement(int id) async {
    final res = await http.post(
      Uri.parse('$baseUrl/settlements/$id/submit'),
      headers: _headers,
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> approveSettlement(int id) async {
    final res = await http.post(
      Uri.parse('$baseUrl/settlements/$id/approve'),
      headers: _headers,
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> moveSettlementToDraft(int id) async {
    final res = await http.post(
      Uri.parse('$baseUrl/settlements/$id/move_to_draft'),
      headers: _headers,
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> rejectAllSettlement(
    int id, {
    String notes = '',
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/settlements/$id/reject_all'),
      headers: _headers,
      body: jsonEncode({'notes': notes}),
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> completeSettlement(int id) async {
    final res = await http.post(
      Uri.parse('$baseUrl/settlements/$id/complete'),
      headers: _headers,
    );
    return _handleResponse(res);
  }

  // expenses

  Future<Map<String, dynamic>> createExpense({
    required int settlementId,
    required int categoryId,
    List<int>? categoryIds,
    required String description,
    required double amount,
    required String date,
    String? source,
    String currency = 'IDR',
    double currencyExchange = 1,
    String? filePath,
  }) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/expenses'));
    request.headers.addAll(_authHeaders);
    request.fields['settlement_id'] = settlementId.toString();
    request.fields['category_id'] = categoryId.toString();
    if (categoryIds != null && categoryIds.isNotEmpty) {
      request.fields['category_ids'] = jsonEncode(categoryIds);
    }
    request.fields['description'] = description;
    request.fields['amount'] = amount.toString();
    request.fields['date'] = date;
    if (source != null && source.isNotEmpty) {
      request.fields['source'] = source;
    }
    request.fields['currency'] = currency;
    request.fields['currency_exchange'] = currencyExchange.toString();

    if (filePath != null) {
      request.files.add(
        await http.MultipartFile.fromPath('evidence', filePath),
      );
    }

    final streamedRes = await request.send();
    final res = await http.Response.fromStream(streamedRes);
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> updateExpense(
    int id, {
    int? categoryId,
    List<int>? categoryIds,
    String? description,
    double? amount,
    String? date,
    String? source,
    String? currency,
    double? currencyExchange,
    String? filePath,
    String? notes,
    String? status,
  }) async {
    var request = http.MultipartRequest(
      'PUT',
      Uri.parse('$baseUrl/expenses/$id'),
    );
    request.headers.addAll(_authHeaders);

    if (categoryId != null) {
      request.fields['category_id'] = categoryId.toString();
    }
    if (categoryIds != null) {
      request.fields['category_ids'] = jsonEncode(categoryIds);
    }
    if (description != null) {
      request.fields['description'] = description;
    }
    if (amount != null) {
      request.fields['amount'] = amount.toString();
    }
    if (date != null) {
      request.fields['date'] = date;
    }
    if (source != null) {
      request.fields['source'] = source;
    }
    if (currency != null) {
      request.fields['currency'] = currency;
    }
    if (currencyExchange != null) {
      request.fields['currency_exchange'] = currencyExchange.toString();
    }
    if (notes != null) {
      request.fields['notes'] = notes;
    }
    if (status != null) {
      request.fields['status'] = status;
    }

    if (filePath != null) {
      request.files.add(
        await http.MultipartFile.fromPath('evidence', filePath),
      );
    }

    final streamedRes = await request.send();
    final res = await http.Response.fromStream(streamedRes);
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> deleteExpense(int expenseId) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/expenses/$expenseId'),
      headers: _headers,
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> bulkDeleteExpenses(List<int> expenseIds) async {
    final res = await http.post(
      Uri.parse('$baseUrl/expenses/bulk-delete'),
      headers: _headers,
      body: jsonEncode({'expense_ids': expenseIds}),
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> approveExpense(
    int id,
    String action, {
    String notes = '',
  }) async {
    final ep = action == 'reject' ? 'reject' : 'approve';
    final res = await http.post(
      Uri.parse('$baseUrl/expenses/$id/$ep'),
      headers: _headers,
      body: jsonEncode({'notes': notes}),
    );
    return _handleResponse(res);
  }

  // categories

  Future<Map<String, dynamic>> getCategories() async {
    final res = await http.get(
      Uri.parse('$baseUrl/expenses/categories'),
      headers: _headers,
    );
    return _handleResponse(res);
  }

  // category management

  Future<Map<String, dynamic>> createCategory(
    String name, {
    int? parentId,
  }) async {
    final body = <String, dynamic>{'name': name};
    if (parentId != null) body['parent_id'] = parentId;
    final res = await http.post(
      Uri.parse('$baseUrl/categories'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> updateCategory(int id, String name) async {
    final res = await http.put(
      Uri.parse('$baseUrl/categories/$id'),
      headers: _headers,
      body: jsonEncode({'name': name}),
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> reorderCategories(
    List<Map<String, dynamic>> categories,
  ) async {
    final res = await http.put(
      Uri.parse('$baseUrl/categories/reorder'),
      headers: _headers,
      body: jsonEncode({'categories': categories}),
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> deleteCategory(int id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/categories/$id'),
      headers: _headers,
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> getPendingCategories() async {
    final res = await http.get(
      Uri.parse('$baseUrl/categories/pending'),
      headers: _headers,
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> approveCategory(int id, String action) async {
    final res = await http.post(
      Uri.parse('$baseUrl/categories/$id/approve'),
      headers: _headers,
      body: jsonEncode({'action': action}),
    );
    return _handleResponse(res);
  }

  // reports

  Future<Map<String, dynamic>> getAdvances({
    String? status,
    String? startDate,
    String? endDate,
    int? reportYear,
    String? type,
    String? search,
  }) async {
    final params = <String>[];
    if (status != null) params.add('status=$status');
    if (startDate != null) params.add('start_date=$startDate');
    if (endDate != null) params.add('end_date=$endDate');
    if (reportYear != null) params.add('report_year=$reportYear');
    if (type != null) params.add('type=$type');
    if (search != null && search.isNotEmpty) {
      params.add('search=${Uri.encodeComponent(search)}');
    }

    final url = _buildUrl('$baseUrl/advances', params);
    final res = await http.get(Uri.parse(url), headers: _headers);
    return _handleResponse(res);
  }

  // dashboard summary
  Future<Map<String, dynamic>> getDashboardSummary() async {
    final res = await http.get(
      Uri.parse('$baseUrl/dashboard/summary'),
      headers: _headers,
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> createAdvance(
    String title,
    String description, {
    String advanceType = 'single',
    int? reportYear,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'description': description,
      'advance_type': advanceType,
    };
    if (reportYear != null) body['report_year'] = reportYear;

    final res = await http.post(
      Uri.parse('$baseUrl/advances'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> getAdvance(int id) async {
    final res = await http.get(
      Uri.parse('$baseUrl/advances/$id'),
      headers: _headers,
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> updateAdvance(
    int id, {
    String? title,
    String? description,
    String? advanceType,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (advanceType != null) body['advance_type'] = advanceType;

    final res = await http.put(
      Uri.parse('$baseUrl/advances/$id'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> deleteAdvance(int id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/advances/$id'),
      headers: _headers,
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> startAdvanceRevision(int id) async {
    final res = await http.post(
      Uri.parse('$baseUrl/advances/$id/start_revision'),
      headers: _headers,
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> createSettlementFromAdvance(int id) async {
    final res = await http.post(
      Uri.parse('$baseUrl/advances/$id/create_settlement'),
      headers: _headers,
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> addAdvanceItem(
    int advanceId,
    int categoryId,
    String description,
    double estimatedAmount, {
    List<int>? categoryIds,
    String? filePath,
    String? date,
    String? source,
    String? currency,
    double? currencyExchange,
  }) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/advances/$advanceId/items'),
    );
    request.headers.addAll(_authHeaders);
    request.fields['advance_id'] = advanceId.toString();
    request.fields['category_id'] = categoryId.toString();
    if (categoryIds != null && categoryIds.isNotEmpty) {
      request.fields['category_ids'] = jsonEncode(categoryIds);
    }
    request.fields['description'] = description;
    request.fields['estimated_amount'] = estimatedAmount.toString();
    if (date != null) request.fields['date'] = date;
    if (source != null) request.fields['source'] = source;
    if (currency != null) request.fields['currency'] = currency;
    if (currencyExchange != null) {
      request.fields['currency_exchange'] = currencyExchange.toString();
    }

    if (filePath != null) {
      request.files.add(
        await http.MultipartFile.fromPath('evidence', filePath),
      );
    }

    final streamedRes = await request.send();
    final res = await http.Response.fromStream(streamedRes);
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> updateAdvanceItem(
    int itemId, {
    int? categoryId,
    List<int>? categoryIds,
    String? description,
    double? estimatedAmount,
    String? filePath,
    String? date,
    String? source,
    String? currency,
    double? currencyExchange,
    String? notes,
    String? status,
  }) async {
    var request = http.MultipartRequest(
      'PUT',
      Uri.parse('$baseUrl/advances/items/$itemId'),
    );
    request.headers.addAll(_authHeaders);

    if (categoryId != null) {
      request.fields['category_id'] = categoryId.toString();
    }
    if (categoryIds != null) {
      request.fields['category_ids'] = jsonEncode(categoryIds);
    }
    if (description != null) {
      request.fields['description'] = description;
    }
    if (estimatedAmount != null) {
      request.fields['estimated_amount'] = estimatedAmount.toString();
    }
    if (date != null) request.fields['date'] = date;
    if (source != null) request.fields['source'] = source;
    if (currency != null) request.fields['currency'] = currency;
    if (currencyExchange != null) {
      request.fields['currency_exchange'] = currencyExchange.toString();
    }

    if (notes != null) request.fields['notes'] = notes;
    if (status != null) request.fields['status'] = status;

    if (filePath != null) {
      request.files.add(
        await http.MultipartFile.fromPath('evidence', filePath),
      );
    }

    final streamedRes = await request.send();
    final res = await http.Response.fromStream(streamedRes);
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> deleteAdvanceItem(int itemId) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/advances/items/$itemId'),
      headers: _headers,
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> bulkDeleteAdvanceItems(List<int> itemIds) async {
    final res = await http.post(
      Uri.parse('$baseUrl/advances/items/bulk-delete'),
      headers: _headers,
      body: jsonEncode({'item_ids': itemIds}),
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> rejectAllExpenses(
    int settlementId, {
    String notes = 'Ditolak oleh manager',
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/settlements/$settlementId/reject_all'),
      headers: _authHeaders,
      body: jsonEncode({'notes': notes}),
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> approveAdvanceItem(
    int id,
    String action, {
    String notes = '',
  }) async {
    final ep = action == 'reject' ? 'reject' : 'approve';
    final res = await http.post(
      Uri.parse('$baseUrl/advances/items/$id/$ep'),
      headers: _headers,
      body: jsonEncode({'notes': notes}),
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> submitAdvance(int id) async {
    final res = await http.post(
      Uri.parse('$baseUrl/advances/$id/submit'),
      headers: _headers,
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> approveAdvance(
    int id, {
    String notes = 'Disetujui oleh manager',
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/advances/$id/approve_all'),
      headers: _headers,
      body: jsonEncode({'notes': notes}),
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> rejectAdvance(
    int id, {
    String notes = 'Ditolak oleh manager',
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/advances/$id/reject_all'),
      headers: _headers,
      body: jsonEncode({'notes': notes}),
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> moveAdvanceToDraft(int id) async {
    final res = await http.post(
      Uri.parse('$baseUrl/advances/$id/move_to_draft'),
      headers: _headers,
    );
    return _handleResponse(res);
  }

  Future<List<int>> exportAdvanceExcel({
    String? startDate,
    String? endDate,
    int? advanceId,
  }) async {
    final params = <String>[];
    if (startDate != null) params.add('start_date=$startDate');
    if (endDate != null) params.add('end_date=$endDate');
    if (advanceId != null) params.add('advance_id=$advanceId');

    final url = _buildUrl('$baseUrl/reports/excel_advance', params);
    final res = await http.get(Uri.parse(url), headers: _authHeaders);
    if (res.statusCode == 200) {
      return res.bodyBytes.toList();
    }
    throw Exception('Gagal export Kasbon Excel');
  }

  Future<List<int>> getBulkSettlementsPdf({
    String? status,
    String? startDate,
    String? endDate,
    int? reportYear,
  }) async {
    final params = <String>[];
    if (status != null) params.add('status=$status');
    if (startDate != null) params.add('start_date=$startDate');
    if (endDate != null) params.add('end_date=$endDate');
    if (reportYear != null) params.add('report_year=$reportYear');

    final url = _buildUrl('$baseUrl/reports/settlements/pdf', params);
    final res = await http.get(Uri.parse(url), headers: _authHeaders);
    if (res.statusCode == 200) {
      return res.bodyBytes.toList();
    }
    throw Exception('Gagal export Bulk Settlement PDF');
  }

  Future<List<int>> getBulkAdvancesPdf({
    String? startDate,
    String? endDate,
  }) async {
    final params = <String>[];
    if (startDate != null) params.add('start_date=$startDate');
    if (endDate != null) params.add('end_date=$endDate');

    final url = _buildUrl('$baseUrl/reports/advances/pdf', params);
    final res = await http.get(Uri.parse(url), headers: _authHeaders);
    if (res.statusCode == 200) {
      return res.bodyBytes.toList();
    }
    throw Exception('Gagal export Bulk Kasbon PDF');
  }

  Future<List<int>> getAdvanceReceipt(int advanceId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/reports/advance/$advanceId/pdf'),
      headers: _authHeaders,
    );
    if (res.statusCode == 200) {
      return res.bodyBytes.toList();
    }
    throw Exception('Gagal generate receipt Kasbon');
  }

  Future<List<int>> exportExcel({
    int? month,
    int? year,
    int? categoryId,
    int? settlementId,
    String? startDate,
    String? endDate,
    String? status,
  }) async {
    final params = <String>[];
    if (month != null) params.add('month=$month');
    if (year != null) params.add('year=$year');
    if (categoryId != null) params.add('category_id=$categoryId');
    if (settlementId != null) params.add('settlement_id=$settlementId');
    if (startDate != null) params.add('start_date=$startDate');
    if (endDate != null) params.add('end_date=$endDate');
    if (status != null) params.add('status=$status');

    final url = _buildUrl('$baseUrl/reports/excel', params);
    final res = await http.get(Uri.parse(url), headers: _authHeaders);
    if (res.statusCode == 200) {
      return res.bodyBytes.toList();
    }
    throw Exception('Gagal export Excel');
  }

  Future<Map<String, dynamic>> getSummary({
    int? year,
    String? startDate,
    String? endDate,
  }) async {
    final params = <String>[];
    if (year != null) params.add('year=$year');
    if (startDate != null) params.add('start_date=$startDate');
    if (endDate != null) params.add('end_date=$endDate');

    final url = _buildUrl('$baseUrl/reports/summary', params);
    final res = await http.get(Uri.parse(url), headers: _headers);
    return _handleResponse(res);
  }

  Future<List<int>> getSummaryPdf({
    int? year,
    String? startDate,
    String? endDate,
  }) async {
    final params = <String>[];
    if (year != null) params.add('year=$year');
    if (startDate != null) params.add('start_date=$startDate');
    if (endDate != null) params.add('end_date=$endDate');

    final url = _buildUrl('$baseUrl/reports/summary/pdf', params);
    final res = await http.get(Uri.parse(url), headers: _authHeaders);
    if (res.statusCode == 200) {
      return res.bodyBytes.toList();
    }
    throw Exception('Gagal export Summary PDF');
  }

  Future<List<int>> getReceipt(int settlementId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/reports/settlement/$settlementId/receipt'),
      headers: _authHeaders,
    );
    if (res.statusCode == 200) {
      return res.bodyBytes.toList();
    }
    throw Exception('Gagal generate receipt');
  }

  // evidence

  String getEvidenceUrl(String filename) {
    return '$baseUrl/expenses/evidence/$filename';
  }

  // settings

  Future<dynamic> getStorageSettings() async {
    final res = await http.get(
      Uri.parse('$baseUrl/settings/storage'),
      headers: _authHeaders,
    );
    return _handleResponse(res);
  }

  Future<dynamic> updateStorageSettings(String newDirectory) async {
    final res = await http.post(
      Uri.parse('$baseUrl/settings/storage'),
      headers: _headers,
      body: jsonEncode({'new_directory': newDirectory}),
    );
    return _handleResponse(res);
  }

  // revenues

  Future<List<dynamic>> getRevenues({
    String? startDate,
    String? endDate,
  }) async {
    final params = <String>[];
    if (startDate != null) params.add('start_date=$startDate');
    if (endDate != null) params.add('end_date=$endDate');

    final url = _buildUrl('$baseUrl/revenues', params);
    final res = await http.get(Uri.parse(url), headers: _headers);
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    throw Exception('Gagal memuat revenues');
  }

  Future<Map<String, dynamic>> createRevenue(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/revenues'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> updateRevenue(
    int id,
    Map<String, dynamic> data,
  ) async {
    final res = await http.put(
      Uri.parse('$baseUrl/revenues/$id'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> deleteRevenue(int id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/revenues/$id'),
      headers: _headers,
    );
    return _handleResponse(res);
  }

  Future<List<dynamic>> getRevenueCombineGroups({required int year}) async {
    final res = await http.get(
      Uri.parse('$baseUrl/revenues/combine-groups?year=$year'),
      headers: _headers,
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    throw Exception('Gagal memuat combine revenue');
  }

  Future<Map<String, dynamic>> createRevenueCombineGroup({
    required int year,
    required List<int> rowIds,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/revenues/combine-groups'),
      headers: _headers,
      body: jsonEncode({'year': year, 'row_ids': rowIds}),
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> deleteRevenueCombineGroup(int id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/revenues/combine-groups/$id'),
      headers: _headers,
    );
    return _handleResponse(res);
  }

  // taxes

  Future<List<dynamic>> getTaxes({String? startDate, String? endDate}) async {
    final params = <String>[];
    if (startDate != null) params.add('start_date=$startDate');
    if (endDate != null) params.add('end_date=$endDate');

    final url = _buildUrl('$baseUrl/taxes', params);
    final res = await http.get(Uri.parse(url), headers: _headers);
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    throw Exception('Gagal memuat pajak(taxes)');
  }

  Future<Map<String, dynamic>> createTax(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/taxes'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> updateTax(
    int id,
    Map<String, dynamic> data,
  ) async {
    final res = await http.put(
      Uri.parse('$baseUrl/taxes/$id'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> deleteTax(int id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/taxes/$id'),
      headers: _headers,
    );
    return _handleResponse(res);
  }

  Future<List<dynamic>> getTaxCombineGroups({required int year}) async {
    final res = await http.get(
      Uri.parse('$baseUrl/taxes/combine-groups?year=$year'),
      headers: _headers,
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    throw Exception('Gagal memuat combine pajak');
  }

  Future<Map<String, dynamic>> createTaxCombineGroup({
    required int year,
    required List<int> rowIds,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/taxes/combine-groups'),
      headers: _headers,
      body: jsonEncode({'year': year, 'row_ids': rowIds}),
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> deleteTaxCombineGroup(int id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/taxes/combine-groups/$id'),
      headers: _headers,
    );
    return _handleResponse(res);
  }

  // dividends

  Future<Map<String, dynamic>> getDividends({int? year}) async {
    String url = '$baseUrl/dividends';
    if (year != null) {
      url += '?year=$year';
    }

    final res = await http.get(Uri.parse(url), headers: _headers);
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> createDividend(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/dividends'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> updateDividend(
    int id,
    Map<String, dynamic> data,
  ) async {
    final res = await http.put(
      Uri.parse('$baseUrl/dividends/$id'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> deleteDividend(int id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/dividends/$id'),
      headers: _headers,
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> updateDividendSetting(
    int year,
    Map<String, dynamic> data,
  ) async {
    final res = await http.put(
      Uri.parse('$baseUrl/dividends/settings/$year'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return _handleResponse(res);
  }

  // annual reports

  Future<Map<String, dynamic>> getAnnualReport({int? year}) async {
    String url = '$baseUrl/reports/annual';
    if (year != null) {
      url += '?year=$year';
    }
    final res = await http.get(Uri.parse(url), headers: _headers);
    return _handleResponse(res);
  }

  Future<dynamic> getReportYearSettings() async {
    final res = await http.get(
      Uri.parse('$baseUrl/settings/report-year'),
      headers: _authHeaders,
    );
    return _handleResponse(res);
  }

  Future<dynamic> updateReportYearSettings(int defaultReportYear) async {
    final res = await http.post(
      Uri.parse('$baseUrl/settings/report-year'),
      headers: _headers,
      body: jsonEncode({'default_report_year': defaultReportYear}),
    );
    return _handleResponse(res);
  }

  Future<List<int>> getAnnualReportPdf({int? year}) async {
    String url = '$baseUrl/reports/annual/pdf';
    if (year != null) {
      url += '?year=$year';
    }

    final res = await http.get(Uri.parse(url), headers: _authHeaders);
    if (res.statusCode == 200) {
      return res.bodyBytes.toList();
    }
    throw Exception('Gagal export Laporan Tahunan PDF');
  }

  Future<List<int>> getAnnualReportExcel({int? year}) async {
    String url = '$baseUrl/reports/annual/excel';
    if (year != null) {
      url += '?year=$year';
    }

    final res = await http.get(Uri.parse(url), headers: _authHeaders);
    if (res.statusCode == 200) {
      return res.bodyBytes.toList();
    }
    throw Exception('Gagal export Laporan Tahunan Excel');
  }

  // helpers

  Map<String, dynamic> _handleResponse(http.Response res) {
    if (res.statusCode == 413) {
      throw Exception('File terlalu besar (Maks 16MB)');
    }

    // Handle 401 Unauthorized - token expired
    if (res.statusCode == 401) {
      throw Exception('Sesi expired. Silakan login kembali.');
    }

    // Handle empty body
    if (res.body.trim().isEmpty) {
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return {};
      }
      throw Exception('Server Error: ${res.statusCode}');
    }

    try {
      final body = jsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return body;
      }
      throw Exception(body['error'] ?? 'Terjadi kesalahan: ${res.statusCode}');
    } on FormatException {
      throw Exception('Server Error ${res.statusCode}: Respon tidak valid');
    }
  }

  String _networkHint(String message) {
    if (!kIsWeb && Platform.isAndroid) {
      if (_configuredBaseUrl.isEmpty) {
        return '$message. Pastikan: (1) Backend Flask running, (2) HP & PC di WiFi yang sama, (3) IP address benar';
      }
      return '$message. Periksa: (1) Flask backend aktif, (2) WiFi sama, (3) Firewall tidak blokir port 5000';
    }
    return '$message. Periksa backend aktif di $baseUrl';
  }
}

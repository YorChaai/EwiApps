import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class SettlementProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Map<String, dynamic>> _settlements = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _pendingCategories = [];
  Map<String, dynamic>? _currentSettlement;
  bool _loading = false;
  String? _error;
  bool _unsavedDraft = false; // Flag untuk track draft yang belum tersimpan

  String? _statusFilter;
  int _reportYear = 2024; // Default to 2024 as requested
  String? _startDate;
  String? _endDate;
  String? _searchQuery;
  bool _initialized = false; // ✅ Flag untuk track apakah sudah di-init dengan year dari settings

  // ✅ Sync report year from settings on init
  SettlementProvider() {
    // Load default year from settings (not from DateTime.now())
    // Use addPostFrameCallback or call syncReportYear explicitly before first load
    syncReportYear();
  }

  // ✅ Initialize with default year, will be overwritten by syncReportYear
  void initialize() {
    syncReportYear();
  }

  // ✅ Check if provider is initialized
  bool get isInitialized => _initialized;

  List<Map<String, dynamic>> get settlements => _settlements;
  List<Map<String, dynamic>> get categories => _categories;
  List<Map<String, dynamic>> get pendingCategories => _pendingCategories;
  Map<String, dynamic>? get currentSettlement => _currentSettlement;
  bool get unsavedDraft => _unsavedDraft;
  bool get loading => _loading;
  String? get error => _error;

  String? get statusFilter => _statusFilter;
  int get reportYear => _reportYear;
  String? get startDate => _startDate;
  String? get endDate => _endDate;
  String? get searchQuery => _searchQuery;

  // rapikan kategori untuk dropdown
  // parent dengan child jadi header
  // parent tanpa child tetap bisa dipilih
  List<Map<String, dynamic>> get flatCategories {
    final flat = <Map<String, dynamic>>[];
    for (final cat in _categories) {
      final children = cat['children'] as List? ?? [];
      if (children.isNotEmpty) {
        // parent hanya jadi header
        flat.add({...cat, '_isHeader': true});
        for (final child in children) {
          flat.add({
            ...child,
            'name': '  └ ${child['name']}',
            '_isHeader': false,
            'status': child['status'], // pastikan status terbawa
          });
        }
      } else {
        flat.add({...cat, '_isHeader': false});
      }
    }
    return flat;
  }

  void updateToken(String? token) {
    _api.setToken(token);
  }

  Future<void> loadSettlements({
    String? status,
    String? startDate,
    String? endDate,
    String? type,
    int? reportYear,
    String? search,
    bool notify = true,
  }) async {
    // ✅ SKIP load if not initialized yet (waiting for syncReportYear)
    // This prevents flash of old data before settings year is loaded
    if (!_initialized && reportYear == null) {
      // Don't load with default year, wait for syncReportYear to complete
      return;
    }

    // Set filters
    _statusFilter = status;
    _startDate = startDate;
    _endDate = endDate;
    if (reportYear != null) {
      _reportYear = reportYear;
    }

    // ✅ Centralized Sanitization
    _searchQuery = search
        ?.replaceAll('<', '')
        .replaceAll('>', '')
        .replaceAll('"', '')
        .replaceAll("'", '')
        .replaceAll('&', '')
        .replaceAll(';', '')
        .trim();

    _loading = true;
    if (notify) notifyListeners();
    _error = null;

    try {
      final params = <String, dynamic>{};
      if (_statusFilter != null) params['status'] = _statusFilter;
      if (_startDate != null) params['startDate'] = _startDate;
      if (_endDate != null) params['endDate'] = _endDate;
      params['reportYear'] = _reportYear;
      params['search'] = _searchQuery;

      final res = await _api.getSettlements(
        status: _statusFilter,
        startDate: _startDate,
        endDate: _endDate,
        type: type,
        reportYear: _reportYear,
        search: _searchQuery,
      );
      _settlements = List<Map<String, dynamic>>.from(res['settlements']);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    }

    _loading = false;
    if (notify) notifyListeners();
  }

  void clearFilters() {
    _statusFilter = null;
    _startDate = null;
    _endDate = null;
    // ✅ Don't reset to DateTime.now().year, keep the synced year from settings
    // _reportYear = DateTime.now().year;  // ❌ REMOVED
    _searchQuery = null;
    loadSettlements();
  }

  Future<void> loadSettlement(int id, {bool notify = true}) async {
    _loading = true;
    if (notify) notifyListeners();
    _error = null;

    try {
      final res = await _api.getSettlement(id);
      _currentSettlement = res['settlement'];
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    }

    _loading = false;
    if (notify) notifyListeners();
  }

  Future<void> syncReportYear() async {
    try {
      final res = await _api.getReportYearSettings();
      final year = int.tryParse((res['default_report_year'] ?? 2024).toString());
      if (year != null) {
        _reportYear = year;
        _initialized = true; // ✅ Mark as initialized
        notifyListeners();
      }
    } catch (_) {}
  }

  void setReportYear(int year, {bool reload = true}) {
    _reportYear = year;
    if (reload) {
      loadSettlements();
      // ✅ Trigger event untuk load annual summary
      notifyListeners();
    }
  }

  Future<void> loadCategories() async {
    try {
      final res = await _api.getCategories();
      _categories = List<Map<String, dynamic>>.from(res['categories']);
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    }
  }

  Future<Map<String, dynamic>?> createSettlement(
    String title,
    String description, {
    int? advanceId,
    String settlementType = 'single',
    int? reportYear,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.createSettlement(
        title,
        description,
        advanceId: advanceId,
        settlementType: settlementType,
        reportYear: reportYear,
      );

      final newSettlement = res['settlement'];
      _currentSettlement = newSettlement;
      _unsavedDraft = true; // Mark as unsaved draft until first expense

      _loading = false;
      notifyListeners();
      return newSettlement;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _loading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateSettlement(
    int id, {
    String? title,
    String? description,
  }) async {
    try {
      await _api.updateSettlement(id, title: title, description: description);
      await loadSettlement(id, notify: false); // Don't notify here
      notifyListeners(); // Notify once at the end
      return true;
    } catch (e) {

      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSettlement(int id, {bool reload = true}) async {
    try {
      await _api.deleteSettlement(id);
      if (reload) {
        await loadSettlements();
      }
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> submitSettlement(int id) async {
    try {
      await _api.submitSettlement(id);
      await loadSettlement(id, notify: false);
      await loadSettlements(notify: false);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeSettlement(int id) async {
    try {
      await _api.completeSettlement(id);
      await loadSettlement(id, notify: false);
      await loadSettlements(notify: false);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> approveSettlement(int id) async {
    try {
      await _api.approveSettlement(id);
      await loadSettlement(id, notify: false);
      await loadSettlements(notify: false);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectAllExpenses(int id, String notes) async {
    try {
      await _api.rejectAllExpenses(id, notes: notes);
      await loadSettlement(id, notify: false);
      await loadSettlements(notify: false);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> moveSettlementToDraft(int id) async {
    try {
      await _api.moveSettlementToDraft(id);
      await loadSettlement(id, notify: false);
      await loadSettlements(notify: false);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Save expense pertama sekaligus commit settlement ke list
  /// Ini adalah trigger utama untuk auto-save Settlement
  Future<bool> saveFirstExpenseAndCommitSettlement({
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
    try {
      // Save expense pertama
      await _api.createExpense(
        settlementId: settlementId,
        categoryId: categoryId,
        categoryIds: categoryIds,
        description: description,
        amount: amount,
        date: date,
        source: source,
        currency: currency,
        currencyExchange: currencyExchange,
        filePath: filePath,
      );

      // Commit settlement ke list dengan reload
      await loadSettlement(settlementId);
      await loadSettlements(
        status: _statusFilter,
        startDate: _startDate,
        endDate: _endDate,
        reportYear: _reportYear,
        search: _searchQuery,
      );
      _unsavedDraft = false;
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Cleanup - delete draft yang tidak ada expense
  Future<void> cleanupEmptyDraft(int settlementId) async {
    if (!_unsavedDraft) return;

    try {
      await deleteSettlement(settlementId, reload: true);
      _unsavedDraft = false;
    } catch (e) {
      // Ignore error, just mark as not unsaved
      _unsavedDraft = false;
      notifyListeners();
    }
  }

  Future<bool> addExpense({
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
    try {
      await _api.createExpense(
        settlementId: settlementId,
        categoryId: categoryId,
        categoryIds: categoryIds,
        description: description,
        amount: amount,
        date: date,
        source: source,
        currency: currency,
        currencyExchange: currencyExchange,
        filePath: filePath,
      );
      await loadSettlement(settlementId);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateExpense({
    required int expenseId,
    required int settlementId,
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
    try {
      await _api.updateExpense(
        expenseId,
        categoryId: categoryId,
        categoryIds: categoryIds,
        description: description,
        amount: amount,
        date: date,
        source: source,
        currency: currency,
        currencyExchange: currencyExchange,
        filePath: filePath,
        notes: notes,
        status: status,
      );
      await loadSettlement(settlementId);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateExpensePartial(
    int expenseId,
    int settlementId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _api.updateExpense(
        expenseId,
        categoryId: data['category_id'],
        description: data['description'],
        amount: data['amount'],
        date: data['date'],
        source: data['source'],
        currency: data['currency'],
        currencyExchange: data['currency_exchange'],
        filePath: data['file_path'],
        notes: data['notes'],
        status: data['status'],
      );
      await loadSettlement(settlementId);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteExpense(int expenseId, int settlementId) async {
    try {
      await _api.deleteExpense(expenseId);
      await loadSettlement(settlementId);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> bulkDeleteExpenses(List<int> expenseIds, int settlementId) async {
    try {
      await _api.bulkDeleteExpenses(expenseIds);
      await loadSettlement(settlementId);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> approveExpense(
    int expenseId,
    String action, {
    String notes = '',
  }) async {
    try {
      // Preserve existing notes if approving and no new notes provided
      String finalNotes = notes;
      if (action == 'approve' && finalNotes.isEmpty && _currentSettlement != null) {
        final expenses = _currentSettlement!['expenses'] as List? ?? [];
        final existing = expenses.firstWhere(
          (e) => e['id'] == expenseId,
          orElse: () => null,
        );
        if (existing != null && existing['notes'] != null) {
          finalNotes = existing['notes'].toString();
        }
      }

      await _api.approveExpense(expenseId, action, notes: finalNotes);
      if (_currentSettlement != null) {
        await loadSettlement(_currentSettlement!['id']);
      }
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> approveAllSettlement(int settlementId) async {
    try {
      await _api.approveSettlement(settlementId);
      await loadSettlement(settlementId);
      await loadSettlements();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectAllSettlement(
    int settlementId, {
    String notes = '',
  }) async {
    try {
      await _api.rejectAllSettlement(settlementId, notes: notes);
      await loadSettlement(settlementId);
      await loadSettlements();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // kategori

  Future<bool> createCategory(String name, {int? parentId}) async {
    try {
      await _api.createCategory(name, parentId: parentId);
      await loadCategories();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCategory(int id, String name) async {
    try {
      await _api.updateCategory(id, name);
      await loadCategories();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> reorderCategories(List<Map<String, dynamic>> categories) async {
    try {
      await _api.reorderCategories(categories);
      await loadCategories();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCategory(int id) async {
    try {
      await _api.deleteCategory(id);
      await loadCategories();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> loadPendingCategories() async {
    try {
      final res = await _api.getPendingCategories();
      _pendingCategories = List<Map<String, dynamic>>.from(res['categories']);
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    }
  }

  Future<bool> approveCategory(int id, String action) async {
    try {
      await _api.approveCategory(id, action);
      await loadPendingCategories();
      await loadCategories();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  String getEvidenceUrl(String filename) {
    return _api.getEvidenceUrl(filename);
  }

  Future<List<int>> exportExcel({
    int? month,
    int? year,
    int? categoryId,
    int? settlementId,
    String? startDate,
    String? endDate,
    String? status,
  }) {
    return _api.exportExcel(
      month: month,
      year: year,
      categoryId: categoryId,
      settlementId: settlementId,
      startDate: startDate,
      endDate: endDate,
      status: status,
    );
  }

  Future<Map<String, dynamic>> getSummary({
    int? year,
    String? startDate,
    String? endDate,
  }) {
    return _api.getSummary(year: year, startDate: startDate, endDate: endDate);
  }

  Future<List<int>> getSummaryPdf({
    int? year,
    String? startDate,
    String? endDate,
  }) {
    return _api.getSummaryPdf(
      year: year,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<List<int>> getReceipt(int settlementId) {
    return _api.getReceipt(settlementId);
  }

  Future<List<int>> getBulkPdf({
    String? status,
    String? startDate,
    String? endDate,
    int? reportYear,
  }) {
    return _api.getBulkSettlementsPdf(
      status: status,
      startDate: startDate,
      endDate: endDate,
      reportYear: reportYear,
    );
  }
}

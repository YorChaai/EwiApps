import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdvanceProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Map<String, dynamic>> _advances = [];
  Map<String, dynamic>? _currentAdvance;
  bool _loading = false;
  String? _error;
  bool _unsavedDraft = false;
  int _reportYear = DateTime.now().year;

  List<Map<String, dynamic>> get advances => _advances;
  Map<String, dynamic>? get currentAdvance => _currentAdvance;
  bool get unsavedDraft => _unsavedDraft;
  List<Map<String, dynamic>> get availableAdvances =>
      _advances
          .where(
            (a) => a['status'] == 'approved' && a['settlement_id'] == null,
          )
          .toList();
  bool get loading => _loading;
  String? get error => _error;
  int get reportYear => _reportYear;

  void updateToken(String? token) {
    _api.setToken(token);
  }

  Future<void> loadAdvances({
    String? status,
    String? startDate,
    String? endDate,
    int? reportYear,
    String? type,
    String? search,
  }) async {
    if (reportYear != null) _reportYear = reportYear;
    final yearToUse = _reportYear == 0 ? null : _reportYear;

    // ✅ Centralized Sanitization
    final cleanSearch = search
        ?.replaceAll('<', '')
        .replaceAll('>', '')
        .replaceAll('"', '')
        .replaceAll("'", '')
        .replaceAll('&', '')
        .replaceAll(';', '')
        .trim();

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.getAdvances(
        status: status,
        startDate: startDate,
        endDate: endDate,
        reportYear: yearToUse,
        type: type,
        search: cleanSearch,
      );
      _advances = List<Map<String, dynamic>>.from(res['advances']);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    }

    _loading = false;
    notifyListeners();
  }

  void clearFilters() {
    loadAdvances();
  }

  Future<void> syncReportYear() async {
    try {
      final res = await _api.getReportYearSettings();
      final year = int.tryParse((res['default_report_year'] ?? DateTime.now().year).toString());
      if (year != null) {
        _reportYear = year;
        notifyListeners();
      }
    } catch (_) {}
  }

  void setReportYear(int year, {bool reload = true}) {
    _reportYear = year;
    if (reload) loadAdvances();
    notifyListeners();
  }

  Future<void> loadAdvance(int id) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.getAdvance(id);
      _currentAdvance = res['advance'];
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    }

    _loading = false;
    notifyListeners();
  }

  /// Create advance tanpa auto-load (untuk unsaved draft)
  /// Advance akan tersimpan tapi belum masuk ke list sampai ada item pertama
  Future<Map<String, dynamic>?> createUnsavedAdvance(
    String title,
    String desc, {
    String advanceType = 'single',
    int? reportYear,
  }) async {
    try {
      final res = await _api.createAdvance(
        title,
        desc,
        advanceType: advanceType,
        reportYear: reportYear,
      );
      _currentAdvance = res['advance'];
      _unsavedDraft = true;
      notifyListeners();
      return res['advance'];
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  /// Save item pertama sekaligus commit advance ke list
  /// Ini adalah trigger utama untuk auto-save Kasbon
  Future<bool> saveFirstItemAndCommitAdvance({
    required int advanceId,
    required int categoryId,
    List<int>? categoryIds,
    required String desc,
    required double amount,
    String? filePath,
    String? date,
    String? source,
    String? currency,
    double? currencyExchange,
  }) async {
    try {
      // Save item pertama
      final itemSaved = await addAdvanceItem(
        advanceId,
        categoryId,
        desc,
        amount,
        categoryIds: categoryIds,
        filePath: filePath,
        date: date,
        source: source,
        currency: currency,
        currencyExchange: currencyExchange,
      );

      if (itemSaved) {
        // Commit advance ke list dengan reload
        await loadAdvances();
        _unsavedDraft = false;
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Cleanup - delete draft yang tidak ada item
  Future<void> cleanupEmptyDraft(int advanceId) async {
    if (!_unsavedDraft) return;

    try {
      await deleteAdvance(advanceId, reload: true);
      _unsavedDraft = false;
    } catch (e) {
      // Ignore error, just mark as not unsaved
      _unsavedDraft = false;
      notifyListeners();
    }
  }

  Future<void> updateAdvance(
    int id,
    String title,
    String desc, {
    String? advanceType,
  }) async {
    try {
      await _api.updateAdvance(
        id,
        title: title,
        description: desc,
        advanceType: advanceType,
      );
      await loadAdvances();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<bool> deleteAdvance(int id, {bool reload = true}) async {
    try {
      await _api.deleteAdvance(id);
      if (reload) {
        await loadAdvances();
      }
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> addAdvanceItem(
    int advanceId,
    int categoryId,
    String desc,
    double amount, {
    List<int>? categoryIds,
    String? filePath,
    String? date,
    String? source,
    String? currency,
    double? currencyExchange,
  }) async {
    try {
      await _api.addAdvanceItem(
        advanceId,
        categoryId,
        desc,
        amount,
        categoryIds: categoryIds,
        filePath: filePath,
        date: date,
        source: source,
        currency: currency,
        currencyExchange: currencyExchange,
      );
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAdvanceItem(
    int itemId,
    int categoryId,
    String desc,
    double amount, {
    List<int>? categoryIds,
    String? filePath,
    String? date,
    String? source,
    String? currency,
    double? currencyExchange,
    String? notes,
    String? status,
  }) async {
    try {
      await _api.updateAdvanceItem(
        itemId,
        categoryId: categoryId,
        categoryIds: categoryIds,
        description: desc,
        estimatedAmount: amount,
        filePath: filePath,
        date: date,
        source: source,
        currency: currency,
        currencyExchange: currencyExchange,
        notes: notes,
        status: status,
      );
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateItemPartial(int itemId, Map<String, dynamic> data) async {
    try {
      await _api.updateAdvanceItem(
        itemId,
        categoryId: data['category_id'],
        description: data['description'],
        estimatedAmount: data['estimated_amount'],
        date: data['date'],
        source: data['source'],
        currency: data['currency'],
        currencyExchange: data['currency_exchange'],
        notes: data['notes'],
        status: data['status'],
      );
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAdvanceItem(int itemId) async {
    try {
      await _api.deleteAdvanceItem(itemId);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> bulkDeleteAdvanceItems(List<int> itemIds, int advanceId) async {
    try {
      await _api.bulkDeleteAdvanceItems(itemIds);
      await loadAdvance(advanceId);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> submitAdvance(int id) async {
    try {
      await _api.submitAdvance(id);
      await loadAdvances();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> approveAdvance(int id, {String notes = ''}) async {         try {
      await _api.approveAdvance(id, notes: notes);
      await loadAdvances();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> approveAdvanceItem(int itemId, String action, {String notes = ''}) async {
    try {
      await _api.approveAdvanceItem(itemId, action, notes: notes);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectAdvance(int id, String notes) async {
    try {
      await _api.rejectAdvance(id, notes: notes);
      await loadAdvances();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<List<int>> getAdvanceReceipt(int advanceId) async {
    try {
      return await _api.getAdvanceReceipt(advanceId);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> startRevision(int id) async {
    try {
      final res = await _api.startAdvanceRevision(id);
      _currentAdvance = res['advance'];
      await loadAdvances();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>?> createSettlementFromAdvance(int id) async {
    try {
      final res = await _api.createSettlementFromAdvance(id);
      await loadAdvance(id);
      await loadAdvances();
      return res['settlement'];
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<List<int>> exportExcel({
    String? startDate,
    String? endDate,
    int? advanceId,
  }) {
    return _api.exportAdvanceExcel(
      startDate: startDate,
      endDate: endDate,
      advanceId: advanceId,
    );
  }

  Future<List<int>> getBulkPdf({String? startDate, String? endDate}) {
    return _api.getBulkAdvancesPdf(startDate: startDate, endDate: endDate);
  }

  Future<bool> moveAdvanceToDraft(int id) async {
    try {
      await _api.moveAdvanceToDraft(id);
      await loadAdvance(id);
      await loadAdvances();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}

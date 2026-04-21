import 'package:flutter/material.dart';

import '../services/api_service.dart';

class DividendProvider with ChangeNotifier {
  final ApiService _api;

  DividendProvider(this._api);

  List<dynamic> _dividends = [];
  Map<String, dynamic> _summary = {};
  bool _isLoading = false;
  String? _error;

  List<dynamic> get dividends => _dividends;
  Map<String, dynamic> get summary => _summary;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchDividends({int? year}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _api.getDividends(year: year);
      _summary = result;
      _dividends = List<dynamic>.from(result['data'] ?? const []);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createDividend(Map<String, dynamic> data, {int? year}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.createDividend(data);
      await fetchDividends(year: year);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateDividend(
    int id,
    Map<String, dynamic> data, {
    int? year,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.updateDividend(id, data);
      await fetchDividends(year: year);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteDividend(int id, {int? year}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.deleteDividend(id);
      await fetchDividends(year: year);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateDividendSetting(
    int year,
    Map<String, dynamic> data,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.updateDividendSetting(year, data);
      await fetchDividends(year: year);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}

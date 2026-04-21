import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TaxProvider with ChangeNotifier {
  final ApiService _api;

  TaxProvider(this._api);

  List<dynamic> _taxes = [];
  List<dynamic> _combineGroups = [];
  bool _isLoading = false;
  String? _error;

  List<dynamic> get taxes => _taxes;
  List<dynamic> get combineGroups => _combineGroups;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchTaxes({String? startDate, String? endDate}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.getTaxes(startDate: startDate, endDate: endDate);
      _taxes = data;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTaxCombineGroups({required int year}) async {
    try {
      final data = await _api.getTaxCombineGroups(year: year);
      _combineGroups = data;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> createTax(
    Map<String, dynamic> data, {
    String? startDate,
    String? endDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.createTax(data);
      await fetchTaxes(startDate: startDate, endDate: endDate);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateTax(
    int id,
    Map<String, dynamic> data, {
    String? startDate,
    String? endDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.updateTax(id, data);
      await fetchTaxes(startDate: startDate, endDate: endDate);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteTax(
    int id, {
    String? startDate,
    String? endDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.deleteTax(id);
      await fetchTaxes(startDate: startDate, endDate: endDate);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> createTaxCombineGroup({
    required int year,
    required List<int> rowIds,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.createTaxCombineGroup(year: year, rowIds: rowIds);
      await fetchTaxCombineGroups(year: year);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteTaxCombineGroup({
    required int id,
    required int year,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.deleteTaxCombineGroup(id);
      await fetchTaxCombineGroups(year: year);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}

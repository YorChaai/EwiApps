import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RevenueProvider with ChangeNotifier {
  final ApiService _api;

  RevenueProvider(this._api);

  List<dynamic> _revenues = [];
  List<dynamic> _combineGroups = [];
  bool _isLoading = false;
  String? _error;

  List<dynamic> get revenues => _revenues;
  List<dynamic> get combineGroups => _combineGroups;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchRevenues({String? startDate, String? endDate}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // pakai endpoint get revenues di api service
      final data = await _api.getRevenues(
        startDate: startDate,
        endDate: endDate,
      );
      _revenues = data;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchRevenueCombineGroups({required int year}) async {
    try {
      final data = await _api.getRevenueCombineGroups(year: year);
      _combineGroups = data;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> createRevenue(
    Map<String, dynamic> data, {
    String? startDate,
    String? endDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.createRevenue(data);
      await fetchRevenues(startDate: startDate, endDate: endDate);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateRevenue(
    int id,
    Map<String, dynamic> data, {
    String? startDate,
    String? endDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.updateRevenue(id, data);
      await fetchRevenues(startDate: startDate, endDate: endDate);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteRevenue(
    int id, {
    String? startDate,
    String? endDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.deleteRevenue(id);
      await fetchRevenues(startDate: startDate, endDate: endDate);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> createRevenueCombineGroup({
    required int year,
    required List<int> rowIds,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.createRevenueCombineGroup(year: year, rowIds: rowIds);
      await fetchRevenueCombineGroups(year: year);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteRevenueCombineGroup({
    required int id,
    required int year,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.deleteRevenueCombineGroup(id);
      await fetchRevenueCombineGroups(year: year);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}

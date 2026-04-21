import 'package:intl/intl.dart';

/// Centralized date and currency formatting utilities
class AppFormatters {
  // Date formats
  static final DateFormat _apiFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _displayFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _filenameFormat = DateFormat('yyyyMMdd');
  static final DateFormat _fullDateTimeFormat = DateFormat('dd MMM yyyy, HH:mm');

  // Currency formats
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final NumberFormat _plainNumberFormat = NumberFormat('#,##0', 'id_ID');

  /// Format date for API requests
  static String formatDateForApi(DateTime date) {
    return _apiFormat.format(date);
  }

  /// Format date for display
  static String formatDateForDisplay(DateTime date) {
    return _displayFormat.format(date);
  }

  /// Format date for filenames
  static String formatDateForFilename(DateTime date) {
    return _filenameFormat.format(date);
  }

  /// Format full date time for display
  static String formatDateTime(DateTime date) {
    return _fullDateTimeFormat.format(date);
  }

  /// Parse date from API string
  static DateTime? parseDateFromApi(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    return DateTime.tryParse(dateStr);
  }

  /// Format currency with Rp symbol
  static String formatCurrency(dynamic amount, {bool withSymbol = true}) {
    final value = _toDouble(amount);
    return withSymbol ? _currencyFormat.format(value) : _plainNumberFormat.format(value);
  }

  /// Format currency plain without symbol
  static String formatCurrencyPlain(dynamic amount) {
    return _plainNumberFormat.format(_toDouble(amount));
  }

  /// Convert dynamic value to double safely
  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value == null) return 0.0;
    final str = value.toString().replaceAll('.', '').replaceAll(',', '');
    return double.tryParse(str) ?? 0.0;
  }

  /// Format timestamp for filenames
  static String formatTimestamp([DateTime? dateTime]) {
    final now = dateTime ?? DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
  }
}

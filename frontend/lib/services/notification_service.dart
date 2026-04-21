import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../models/notification_model.dart';

class NotificationService {
  final ApiService _apiService;

  NotificationService(this._apiService);

  /// Fetch notifications for the current user
  /// - readStatus: 'all', 'true', 'false' (default: 'all')
  /// - limit: number of notifications (default: 50)
  /// - offset: pagination offset (default: 0)
  Future<Map<String, dynamic>> fetchNotifications({
    String readStatus = 'all',
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      // Ensure token is loaded before making request
      await _apiService.ensureTokenLoaded();

      final url = Uri.parse(
        '${ApiService.baseUrl}/notifications?read_status=$readStatus&limit=$limit&offset=$offset',
      );

      final response = await http
          .get(url, headers: _apiService.getAuthHeaders())
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>?;
        if (data == null) {
          return {'success': false, 'error': 'Invalid response format'};
        }
        final rawList = data['data'];
        final List<NotificationModel> notifications = [];
        if (rawList is List) {
          for (final item in rawList) {
            try {
              if (item is Map<String, dynamic>) {
                notifications.add(NotificationModel.fromJson(item));
              }
            } catch (_) {
              // Skip invalid items
            }
          }
        }
        return {
          'success': true,
          'notifications': notifications,
          'total': data['total'] ?? notifications.length,
          'unread_count': data['unread_count'] ?? 0,
          'limit': data['limit'] ?? limit,
          'offset': data['offset'] ?? offset,
        };
      } else if (response.statusCode == 401) {
        return {'success': false, 'error': 'Unauthorized'};
      }
      return {'success': false, 'error': 'Failed to fetch notifications'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Mark a single notification as read
  Future<Map<String, dynamic>> markNotificationAsRead(int notificationId) async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/notifications/$notificationId/read');

      final response = await http
          .put(url, headers: _apiService.getAuthHeaders())
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'notification': NotificationModel.fromJson(data['data']),
          'unread_count': data['unread_count'] ?? 0,
        };
      }
      return {'success': false, 'error': 'Failed to mark notification as read'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Mark all notifications as read
  Future<Map<String, dynamic>> markAllNotificationsAsRead() async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/notifications/mark-all-read');

      final response = await http
          .put(url, headers: _apiService.getAuthHeaders())
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'],
          'unread_count': data['unread_count'] ?? 0,
        };
      }
      return {'success': false, 'error': 'Failed to mark all as read'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Delete a single notification
  Future<Map<String, dynamic>> deleteNotification(int notificationId) async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/notifications/$notificationId');

      final response = await http
          .delete(url, headers: _apiService.getAuthHeaders())
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'],
          'unread_count': data['unread_count'] ?? 0,
        };
      }
      return {'success': false, 'error': 'Failed to delete notification'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get unread notification count
  Future<Map<String, dynamic>> getUnreadCount() async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/notifications/unread-count');

      final response = await http
          .get(url, headers: _apiService.getAuthHeaders())
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'unread_count': data['unread_count'] ?? 0,
        };
      }
      return {'success': false, 'error': 'Failed to get unread count'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}

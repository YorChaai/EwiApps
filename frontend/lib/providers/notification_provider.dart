import 'package:flutter/material.dart';
import 'dart:async';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../services/api_service.dart';

class NotificationProvider extends ChangeNotifier {
  final ApiService _apiService;
  late final NotificationService _notificationService;

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _loading = false;
  String? _error;
  Timer? _pollingTimer;
  bool _isPolling = false;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get loading => _loading;
  String? get error => _error;

  NotificationProvider(this._apiService) {
    _notificationService = NotificationService(_apiService);
  }

  /// Start polling notifications (every 5 seconds)
  void startPolling() {
    if (_isPolling) return;
    _isPolling = true;

    // Fetch once immediately
    fetchNotifications(silent: true);

    // Then poll every 30 seconds (battery-friendly)
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      await fetchNotifications(silent: true);
    });
  }

  /// Stop polling notifications
  void stopPolling() {
    _isPolling = false;
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Fetch all notifications
  Future<void> fetchNotifications({bool silent = false}) async {
    if (!silent) {
      _loading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final result = await _notificationService.fetchNotifications(
        limit: 50,
        offset: 0,
      );

      if (result['success']) {
        _notifications = result['notifications'] ?? [];
        _unreadCount = result['unread_count'] ?? 0;
        _error = null;
      } else {
        _error = result['error'] ?? 'Failed to fetch notifications';
      }
    } catch (e) {
      _error = e.toString();
    }

    if (!silent) {
      _loading = false;
    }
    notifyListeners();
  }

  /// Get unread notifications only
  Future<void> fetchUnreadNotifications() async {
    try {
      final result = await _notificationService.fetchNotifications(
        readStatus: 'false',
        limit: 50,
        offset: 0,
      );

      if (result['success']) {
        _notifications = result['notifications'] ?? [];
        _unreadCount = result['unread_count'] ?? 0;
      } else {
        _error = result['error'] ?? 'Failed to fetch unread notifications';
      }
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  /// Mark single notification as read
  Future<bool> markAsRead(int notificationId) async {
    try {
      final result = await _notificationService.markNotificationAsRead(notificationId);

      if (result['success']) {
        // Update local notification with null check
        final notification = result['notification'] as NotificationModel?;
        if (notification != null) {
          final index = _notifications.indexWhere((n) => n.id == notificationId);
          if (index != -1) {
            _notifications[index] = notification;
          }
        }
        _unreadCount = result['unread_count'] ?? 0;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllAsRead() async {
    try {
      final result = await _notificationService.markAllNotificationsAsRead();

      if (result['success']) {
        // Update all notifications
        _notifications = _notifications
            .map((n) => n.copyWith(readStatus: true))
            .toList();
        _unreadCount = 0;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete notification
  Future<bool> deleteNotification(int notificationId) async {
    try {
      final result = await _notificationService.deleteNotification(notificationId);

      if (result['success']) {
        _notifications.removeWhere((n) => n.id == notificationId);
        _unreadCount = result['unread_count'] ?? 0;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Get unread count only
  Future<void> getUnreadCount() async {
    try {
      final result = await _notificationService.getUnreadCount();

      if (result['success']) {
        _unreadCount = result['unread_count'] ?? 0;
        notifyListeners();
      }
    } catch (e) {
      // silent fail for quick count checks
    }
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}

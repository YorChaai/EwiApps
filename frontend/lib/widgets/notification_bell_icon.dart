import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class NotificationBellIcon extends StatefulWidget {
  final Function(String)? onNotificationTap;

  const NotificationBellIcon({super.key, this.onNotificationTap});

  @override
  State<NotificationBellIcon> createState() => _NotificationBellIconState();
}

class _NotificationBellIconState extends State<NotificationBellIcon> {
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  final ScrollController _scrollController = ScrollController();

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
  Color _cardColor(BuildContext context) =>
      _isDark(context) ? AppTheme.card : AppTheme.lightCard;
  Color _dividerColor(BuildContext context) =>
      _isDark(context) ? AppTheme.divider : AppTheme.lightDivider;
  Color _titleColor(BuildContext context) =>
      _isDark(context) ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
  Color _bodyColor(BuildContext context) =>
      _isDark(context) ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

  void _closeNotificationPanel() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() => _isOpen = false);
    }
  }

  @override
  void initState() {
    super.initState();
    // Start polling for notifications
    if (mounted) {
      Future.microtask(() {
        if (mounted) {
          context.read<NotificationProvider>().startPolling();
        }
      });
    }
  }

  @override
  void dispose() {
    // Clean up overlay
    _overlayEntry?.remove();
    _overlayEntry = null;

    // Dispose scroll controller
    _scrollController.dispose();

    // Don't call context.read() in dispose() - widget tree may be tearing down
    // The NotificationProvider will be disposed by the MultiProvider in main.dart

    super.dispose();
  }

  void _toggleNotificationPanel(BuildContext context) {
    if (_isOpen) {
      _closeNotificationPanel();
    } else {
      _showNotificationPanel(context);
      setState(() => _isOpen = true);
    }
  }

  void _showNotificationPanel(BuildContext context) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;
    final Size screenSize = MediaQuery.of(context).size;

    // Check if we should show above or below
    final bool showAbove = offset.dy > screenSize.height / 2;

    // Horizontal position: if icon is on the left, keep panel on the left (sidebar style)
    // but the user's bell is in a sidebar, so sticking to a fixed width on left or right is better.
    // Based on screenshot, it's in a bottom corner.

    double? top;
    double? bottom;

    if (showAbove) {
      bottom = screenSize.height - offset.dy + 8;
    } else {
      top = offset.dy + size.height + 8;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: top,
        bottom: bottom,
        left: offset.dx < 100 ? 70 : null, // If in sidebar, show next to it
        right: offset.dx >= 100 ? 20 : null,
        width: 380,
        child: Material(
          elevation: 12,
          borderRadius: BorderRadius.circular(12),
          color: _cardColor(context),
          child: Container(
            decoration: BoxDecoration(
              color: _cardColor(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _dividerColor(context), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            constraints: BoxConstraints(maxHeight: screenSize.height * 0.6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Notifikasi',
                        style: TextStyle(
                          color: _titleColor(context),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Consumer<NotificationProvider>(
                            builder: (context, notifProvider, _) {
                              return IconButton(
                                tooltip: 'Tandai semua dibaca',
                                onPressed: notifProvider.notifications.isEmpty
                                    ? null
                                    : () async {
                                        await notifProvider.markAllAsRead();
                                      },
                                icon: const Icon(
                                  Icons.done_all_rounded,
                                  size: 20,
                                  color: AppTheme.accent,
                                ),
                              );
                            },
                          ),
                          IconButton(
                            tooltip: 'Tutup',
                            onPressed: _closeNotificationPanel,
                            icon: Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: _bodyColor(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: _dividerColor(context)),
                // Notifications List
                Expanded(
                  child: Consumer<NotificationProvider>(
                    builder: (context, notifProvider, _) {
                      if (notifProvider.loading &&
                          notifProvider.notifications.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }

                      if (notifProvider.notifications.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.notifications_none,
                                size: 48,
                                color: _bodyColor(context),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Tidak ada notifikasi',
                                style: TextStyle(color: _bodyColor(context)),
                              ),
                            ],
                          ),
                        );
                      }

                      return Scrollbar(
                        controller: _scrollController,
                        thumbVisibility: true,
                        trackVisibility: true,
                        interactive: true,
                        thickness: 6,
                        radius: const Radius.circular(3),
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.zero,
                          cacheExtent: 320,
                          itemCount: notifProvider.notifications.length,
                          itemBuilder: (context, index) {
                            final notification =
                                notifProvider.notifications[index];
                            return _buildNotificationItem(
                              context,
                              notification,
                              notifProvider,
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  bool _hasNavigablePath(NotificationModel notification) {
    final path = notification.linkPath;
    if (path == null) return false;
    return path.trim().isNotEmpty;
  }

  String _openButtonLabel(NotificationModel notification) {
    final target = notification.targetType.toLowerCase();
    if (target == 'advance') return 'Buka Kasbon';
    if (target == 'settlement') return 'Buka Settlement';
    if (target == 'category') return 'Buka Kategori';
    return 'Buka Detail';
  }

  void _openNotificationTarget(
    NotificationModel notification,
    NotificationProvider provider,
  ) {
    if (!notification.readStatus) {
      provider.markAsRead(notification.id);
    }
    final path = notification.linkPath;
    if (path == null || path.trim().isEmpty) return;
    _closeNotificationPanel();
    widget.onNotificationTap?.call(path);
  }

  Widget _buildNotificationItem(
    BuildContext context,
    NotificationModel notification,
    NotificationProvider provider,
  ) {
    final now = DateTime.now();
    final notifTime = notification.createdAt;
    final isUnread = !notification.readStatus;

    String timeText;
    if (now.difference(notifTime).inMinutes < 1) {
      timeText = 'Baru saja';
    } else if (now.difference(notifTime).inHours < 1) {
      timeText = '${now.difference(notifTime).inMinutes} menit yang lalu';
    } else if (now.difference(notifTime).inDays < 1) {
      timeText = '${now.difference(notifTime).inHours} jam yang lalu';
    } else {
      final day = notifTime.day.toString().padLeft(2, '0');
      final month = notifTime.month.toString().padLeft(2, '0');
      timeText = '$day/$month/${notifTime.year}';
    }

    // Determine Icon based on target type
    IconData typeIcon;
    Color typeColor;
    switch (notification.targetType.toLowerCase()) {
      case 'advance':
        typeIcon = Icons.payments_rounded;
        typeColor = Colors.teal;
        break;
      case 'settlement':
        typeIcon = Icons.receipt_long_rounded;
        typeColor = Colors.blue;
        break;
      case 'category':
        typeIcon = Icons.category_rounded;
        typeColor = Colors.orange;
        break;
      case 'user':
        typeIcon = Icons.person_add_rounded;
        typeColor = Colors.purple;
        break;
      default:
        typeIcon = Icons.notifications_rounded;
        typeColor = AppTheme.accent;
    }

    return Container(
      decoration: BoxDecoration(
        color: isUnread
            ? (_isDark(context)
                ? const Color(0xFF232335)
                : AppTheme.lightSurface.withValues(alpha: 0.8))
            : Colors.transparent,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Stack(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: typeColor.withValues(alpha: 0.15),
                    backgroundImage: notification.actorProfileImage != null
                        ? NetworkImage('${ApiService.baseUrl}/uploads/${notification.actorProfileImage}')
                        : null,
                    child: notification.actorProfileImage == null
                        ? Text(
                            notification.actorName.isNotEmpty
                                ? notification.actorName[0].toUpperCase()
                                : 'S',
                            style: TextStyle(
                              color: typeColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: _cardColor(context),
                        shape: BoxShape.circle,
                        border: Border.all(color: _cardColor(context), width: 1),
                      ),
                      child: Icon(typeIcon, size: 10, color: typeColor),
                    ),
                  ),
                  if (isUnread)
                    Positioned(
                      left: 0,
                      top: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: _cardColor(context), width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              title: RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: _titleColor(context),
                    fontSize: 13.5,
                    height: 1.3,
                    fontFamily: 'Inter',
                  ),
                  children: [
                    TextSpan(
                      text: '${notification.actorName} ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: notification.message),
                  ],
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      timeText,
                      style: TextStyle(color: _bodyColor(context), fontSize: 11),
                    ),
                    if (_hasNavigablePath(notification)) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 32,
                        child: OutlinedButton(
                          onPressed: () => _openNotificationTarget(notification, provider),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: typeColor.withValues(alpha: 0.5)),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          child: Text(
                            _openButtonLabel(notification),
                            style: TextStyle(fontSize: 11, color: typeColor, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              trailing: PopupMenuButton(
                itemBuilder: (context) => [
                  if (isUnread)
                    PopupMenuItem(
                      child: const Text('Tandai Dibaca', style: TextStyle(fontSize: 13)),
                      onTap: () {
                        Future.delayed(Duration.zero, () async {
                          await provider.markAsRead(notification.id);
                        });
                      },
                    ),
                  PopupMenuItem(
                    child: const Text('Hapus', style: TextStyle(fontSize: 13)),
                    onTap: () {
                      Future.delayed(Duration.zero, () async {
                        await provider.deleteNotification(notification.id);
                      });
                    },
                  ),
                ],
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(Icons.more_horiz_rounded, size: 18, color: _bodyColor(context).withValues(alpha: 0.6)),
                ),
              ),
              onTap: () {
                _openNotificationTarget(notification, provider);
              },
            ),
          ),
          Divider(height: 1, thickness: 0.5, color: _dividerColor(context).withValues(alpha: 0.5)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notifProvider, _) {
        return GestureDetector(
          onTap: () => _toggleNotificationPanel(context),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Stack(
              alignment: Alignment.topRight,
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications, size: 24),
                if (notifProvider.unreadCount > 0)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _isDark(context) ? AppTheme.card : Colors.white, width: 1.5),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        notifProvider.unreadCount > 99
                            ? '99+'
                            : '${notifProvider.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

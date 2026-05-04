// pages/notifications_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:routefixer/services/notification_service.dart';
import 'dart:async';
import 'package:routefixer/services/fcm_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

enum NotiFilter { all, unread, updates, alerts }

class _NotificationsPageState extends State<NotificationsPage> {
  NotiFilter _filter = NotiFilter.all;
  final NotificationService _notificationService = NotificationService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String? _error;
  StreamSubscription? _notificationSubscription;
  @override
  void initState() {
    super.initState();
    _loadNotifications();

    _notificationSubscription = FCMService.notificationStream.listen((_) {
      _loadNotifications();
    });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _error = 'Not authenticated';
          _isLoading = false;
        });
        return;
      }

      final notifications = await _notificationService.getNotifications(
        user.uid,
      );
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refresh() async {
    await _loadNotifications();
  }

  List<NotificationModel> get _filtered {
    return _notifications.where((n) {
      switch (_filter) {
        case NotiFilter.unread:
          return !n.isRead;
        case NotiFilter.updates:
          return n.type == 'UPDATE';
        case NotiFilter.alerts:
          return n.type == 'ALERT' || n.type == 'ADMIN';
        case NotiFilter.all:
        // ignore: unreachable_switch_default
        default:
          return true;
      }
    }).toList();
  }

  Future<void> _toggleRead(NotificationModel n) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Optimistic update
    setState(() {
      final index = _notifications.indexWhere((item) => item.id == n.id);
      if (index != -1) {
        _notifications[index] = NotificationModel(
          id: n.id,
          title: n.title,
          message: n.message,
          type: n.type,
          isRead: !n.isRead,
          createdAt: n.createdAt,
        );
      }
    });

    // Update on server
    if (!n.isRead) {
      final success = await _notificationService.markAsRead(user.uid, n.id);
      if (!success && mounted) {
        // Revert if failed
        setState(() {
          final index = _notifications.indexWhere((item) => item.id == n.id);
          if (index != -1) {
            _notifications[index] = NotificationModel(
              id: n.id,
              title: n.title,
              message: n.message,
              type: n.type,
              isRead: n.isRead,
              createdAt: n.createdAt,
            );
          }
        });
      }
    }
  }

  Future<void> _markAllAsRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final success = await _notificationService.markAllAsRead(user.uid);
    if (success) {
      await _loadNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to mark all as read'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteNotification(NotificationModel n) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Remove from list immediately (optimistic)
    setState(() {
      _notifications.removeWhere((item) => item.id == n.id);
    });

    // Delete from server
    final success = await _notificationService.deleteNotification(
      user.uid,
      n.id,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Notification deleted' : 'Failed to delete'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }

    // Reload if failed
    if (!success) {
      await _loadNotifications();
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'ADMIN':
        return Icons.admin_panel_settings;
      case 'UPDATE':
        return Icons.system_update_alt;
      case 'ALERT':
        return Icons.warning_amber_rounded;
      case 'REPORT':
        return Icons.check_circle;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEmpty = _filtered.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Mark all as read',
            onPressed: _notifications.any((n) => !n.isRead)
                ? _markAllAsRead
                : null,
            icon: const Icon(Icons.done_all),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('All', NotiFilter.all),
                  const SizedBox(width: 8),
                  _filterChip('Unread', NotiFilter.unread),
                  const SizedBox(width: 8),
                  _filterChip('Updates', NotiFilter.updates),
                  const SizedBox(width: 8),
                  _filterChip('Alerts', NotiFilter.alerts),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadNotifications,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _refresh,
                    child: isEmpty
                        ? ListView(
                            children: const [
                              Padding(
                                padding: EdgeInsets.only(top: 96),
                                child: _EmptyState(
                                  title: 'You\'re all caught up!',
                                  subtitle:
                                      'New notifications will appear here.',
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final n = _filtered[index];
                              return Dismissible(
                                key: ValueKey(n.id),
                                direction: DismissDirection.endToStart,
                                background: _DismissBg(
                                  icon: Icons.delete_outline,
                                  label: 'Delete',
                                  color: theme.colorScheme.errorContainer,
                                  fg: theme.colorScheme.onErrorContainer,
                                ),
                                confirmDismiss: (direction) async {
                                  return await showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Notification'),
                                      content: const Text(
                                        'Are you sure you want to delete this notification?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text(
                                            'Delete',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                onDismissed: (_) => _deleteNotification(n),
                                child: _NotificationCard(
                                  notification: n,
                                  icon: _getIconForType(n.type),
                                  onTap: () => _toggleRead(n),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, NotiFilter value) {
    final selected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = value),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      pressElevation: 0,
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final IconData icon;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = Colors.white;
    final onSurface = theme.colorScheme.onSurface;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IconBadge(icon: icon, unread: !notification.isRead),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _timeAgo(notification.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: onSurface.withOpacity(0.8),
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        TextButton(
                          onPressed: onTap,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            notification.isRead
                                ? 'Mark as unread'
                                : 'Mark as read',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        const Spacer(),
                        Chip(
                          label: Text(
                            notification.type,
                            style: const TextStyle(fontSize: 10),
                          ),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _timeAgo(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    if (d.inDays < 7) return '${d.inDays}d';
    final weeks = (d.inDays / 7).floor();
    return '${weeks}w';
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final bool unread;
  const _IconBadge({required this.icon, required this.unread});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.colorScheme.primaryContainer;
    final fg = theme.colorScheme.onPrimaryContainer;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: fg),
        ),
        if (unread)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}

class _DismissBg extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color fg;
  const _DismissBg({
    required this.icon,
    required this.label,
    required this.color,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            label,
            style: TextStyle(color: fg, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          Icon(icon, color: fg),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  const _EmptyState({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(
          Icons.notifications_none,
          size: 64,
          color: theme.colorScheme.primary.withOpacity(0.5),
        ),
        const SizedBox(height: 12),
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

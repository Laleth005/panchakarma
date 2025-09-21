import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../utils/dummy_notification_data.dart';
import 'package:intl/intl.dart';

class NotificationsAlertsPanel extends StatefulWidget {
  final String practitionerId;
  final Function(NotificationModel) onNotificationTap;

  const NotificationsAlertsPanel({
    super.key,
    required this.practitionerId,
    required this.onNotificationTap,
  });

  @override
  State<NotificationsAlertsPanel> createState() =>
      _NotificationsAlertsPanelState();
}

class _NotificationsAlertsPanelState extends State<NotificationsAlertsPanel> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    // In a real app, this would come from a repository or service
    final notifications = DummyNotificationData.getNotifications(
      widget.practitionerId,
    );

    setState(() {
      _notifications = notifications;
      _isLoading = false;
    });
  }

  void _markAsRead(String notificationId) {
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        final notification = _notifications[index];

        // Create a new notification with isRead set to true
        final updatedNotification = NotificationModel(
          id: notification.id,
          title: notification.title,
          message: notification.message,
          timestamp: notification.timestamp,
          type: notification.type,
          isRead: true,
          practitionerId: notification.practitionerId,
          patientId: notification.patientId,
          patientName: notification.patientName,
          sessionId: notification.sessionId,
          additionalData: notification.additionalData,
        );

        // Replace the old notification with the updated one
        _notifications[index] = updatedNotification;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05).withAlpha(255),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notifications & Alerts',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.green),
                      onPressed: _loadNotifications,
                      tooltip: 'Refresh',
                    ),
                    if (_notifications.any((n) => !n.isRead))
                      Badge(
                        backgroundColor: Colors.red,
                        label: Text(
                          '${_notifications.where((n) => !n.isRead).length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.notifications_active,
                            color: Colors.amber,
                          ),
                          onPressed: () {
                            // Mark all as read option
                            final snackBar = SnackBar(
                              content: const Text('Mark all as read?'),
                              action: SnackBarAction(
                                label: 'YES',
                                onPressed: () {
                                  setState(() {
                                    _notifications = _notifications.map((
                                      notification,
                                    ) {
                                      return NotificationModel(
                                        id: notification.id,
                                        title: notification.title,
                                        message: notification.message,
                                        timestamp: notification.timestamp,
                                        type: notification.type,
                                        isRead: true,
                                        practitionerId:
                                            notification.practitionerId,
                                        patientId: notification.patientId,
                                        patientName: notification.patientName,
                                        sessionId: notification.sessionId,
                                        additionalData:
                                            notification.additionalData,
                                      );
                                    }).toList();
                                  });
                                },
                              ),
                            );
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(snackBar);
                          },
                        ),
                      )
                    else
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_none,
                          color: Colors.grey,
                        ),
                        onPressed: () {},
                        tooltip: 'No unread notifications',
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _buildNotificationList(),
        ],
      ),
    );
  }

  Widget _buildNotificationList() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_notifications.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.notifications_off, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text('No notifications', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _notifications.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return _buildNotificationItem(notification);
      },
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    // Get icon based on type
    IconData iconData;
    switch (notification.type) {
      case NotificationType.sessionReminder:
        iconData = Icons.calendar_today;
        break;
      case NotificationType.patientAlert:
        iconData = Icons.warning;
        break;
      case NotificationType.procedurePrecaution:
        iconData = Icons.medical_information;
        break;
      case NotificationType.general:
        iconData = Icons.notifications;
        break;
    }

    // Get color based on type and read status
    Color iconColor;
    switch (notification.type) {
      case NotificationType.sessionReminder:
        iconColor = Colors.blue;
        break;
      case NotificationType.patientAlert:
        iconColor = Colors.red;
        break;
      case NotificationType.procedurePrecaution:
        iconColor = Colors.amber;
        break;
      case NotificationType.general:
        iconColor = Colors.green;
        break;
    }

    return Dismissible(
      key: Key(notification.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        setState(() {
          _notifications.removeWhere((item) => item.id == notification.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification dismissed'),
            action: SnackBarAction(
              label: 'UNDO',
              onPressed: _loadNotifications,
            ),
          ),
        );
      },
      child: InkWell(
        onTap: () {
          _markAsRead(notification.id);
          widget.onNotificationTap(notification);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          color: notification.isRead ? Colors.white : Colors.blue.shade50,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(8),
                child: Icon(iconData, color: iconColor, size: 24),
              ),
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
                            style: TextStyle(
                              fontWeight: notification.isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Text(
                          _getTimeAgo(notification.timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (notification.patientName != null)
                          Chip(
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            label: Text(
                              notification.patientName!,
                              style: const TextStyle(fontSize: 12),
                            ),
                            avatar: const Icon(Icons.person, size: 16),
                            backgroundColor: Colors.grey.shade200,
                            padding: EdgeInsets.zero,
                          ),
                        const Spacer(),
                        if (!notification.isRead)
                          TextButton(
                            onPressed: () => _markAsRead(notification.id),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Mark as read'),
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

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 1) {
      return DateFormat('MMM d, h:mm a').format(dateTime);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

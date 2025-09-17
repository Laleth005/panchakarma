import 'package:flutter/material.dart';

class PatientNotificationsScreen extends StatefulWidget {
  const PatientNotificationsScreen({Key? key}) : super(key: key);

  @override
  _PatientNotificationsScreenState createState() => _PatientNotificationsScreenState();
}

class _PatientNotificationsScreenState extends State<PatientNotificationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    // Simulating API call
    await Future.delayed(Duration(seconds: 1));
    
    // Sample notification data - replace with actual data from Firebase
    setState(() {
      _notifications = [
        {
          'id': '1',
          'title': 'Appointment Reminder',
          'message': 'You have a Shirodhara session scheduled for tomorrow at 10:00 AM.',
          'timestamp': DateTime.now().subtract(Duration(hours: 2)),
          'isRead': false,
          'type': 'appointment',
        },
        {
          'id': '2',
          'title': 'Treatment Completed',
          'message': 'Your Abhyanga treatment has been marked as completed. How did you feel?',
          'timestamp': DateTime.now().subtract(Duration(days: 1)),
          'isRead': true,
          'type': 'treatment',
        },
        {
          'id': '3',
          'title': 'Diet Recommendation',
          'message': 'Dr. Sharma has updated your diet plan. Check it out in your treatment plan section.',
          'timestamp': DateTime.now().subtract(Duration(days: 2)),
          'isRead': false,
          'type': 'recommendation',
        },
        {
          'id': '4',
          'title': 'New Article',
          'message': 'New article published: "Understanding Your Dosha Type". Read now to learn more about Ayurvedic body types.',
          'timestamp': DateTime.now().subtract(Duration(days: 3)),
          'isRead': true,
          'type': 'general',
        },
        {
          'id': '5',
          'title': 'Practitioner Message',
          'message': 'Dr. Patel has sent you a message regarding your upcoming treatment plan.',
          'timestamp': DateTime.now().subtract(Duration(days: 5)),
          'isRead': true,
          'type': 'message',
        },
      ];
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Custom app bar
        Container(
          color: Colors.green.shade700,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.check_circle_outline, color: Colors.white),
                          onPressed: _markAllAsRead,
                          tooltip: 'Mark all as read',
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.white),
                          onPressed: _clearAllNotifications,
                          tooltip: 'Clear all notifications',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: [
                  Tab(text: 'All'),
                  Tab(text: 'Unread'),
                ],
              ),
            ],
          ),
        ),
        
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildNotificationList(false),
              _buildNotificationList(true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationList(bool unreadOnly) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: Colors.green.shade700,
        ),
      );
    }

    final filteredNotifications = unreadOnly
        ? _notifications.where((notification) => notification['isRead'] == false).toList()
        : _notifications;

    if (filteredNotifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off,
              size: 80,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16),
            Text(
              unreadOnly ? 'No unread notifications' : 'No notifications',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: Colors.green.shade700,
      child: ListView.builder(
        itemCount: filteredNotifications.length,
        padding: EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (context, index) {
          final notification = filteredNotifications[index];
          return _buildNotificationItem(notification);
        },
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final isRead = notification['isRead'] as bool;
    final timestamp = notification['timestamp'] as DateTime;
    final timeAgo = _getTimeAgo(timestamp);
    final type = notification['type'] as String;

    return Dismissible(
      key: Key(notification['id']),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.0),
        child: Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _removeNotification(notification['id']);
      },
      child: Card(
        elevation: isRead ? 0 : 2,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isRead ? Colors.transparent : Colors.green.shade200,
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: () => _markAsRead(notification['id']),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _getNotificationIcon(type),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notification['title'],
                              style: TextStyle(
                                fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.green.shade700,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        notification['message'],
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          height: 1.3,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            timeAgo,
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // Navigate to the relevant screen based on notification type
                              _handleNotificationAction(notification);
                            },
                            child: Text(
                              _getActionText(type),
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              minimumSize: Size(0, 0),
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
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
      ),
    );
  }

  Widget _getNotificationIcon(String type) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case 'appointment':
        iconData = Icons.calendar_today;
        iconColor = Colors.blue.shade700;
        break;
      case 'treatment':
        iconData = Icons.spa;
        iconColor = Colors.green.shade700;
        break;
      case 'recommendation':
        iconData = Icons.restaurant_menu;
        iconColor = Colors.orange.shade700;
        break;
      case 'message':
        iconData = Icons.message;
        iconColor = Colors.purple.shade700;
        break;
      case 'general':
      default:
        iconData = Icons.notifications;
        iconColor = Colors.grey.shade700;
        break;
    }

    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }

  String _getActionText(String type) {
    switch (type) {
      case 'appointment':
        return 'View Appointment';
      case 'treatment':
        return 'View Treatment';
      case 'recommendation':
        return 'View Details';
      case 'message':
        return 'Reply';
      case 'general':
      default:
        return 'View';
    }
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  void _markAsRead(String id) {
    setState(() {
      final index = _notifications.indexWhere((notification) => notification['id'] == id);
      if (index != -1) {
        _notifications[index]['isRead'] = true;
      }
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification['isRead'] = true;
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('All notifications marked as read'),
        backgroundColor: Colors.green.shade700,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _removeNotification(String id) {
    setState(() {
      _notifications.removeWhere((notification) => notification['id'] == id);
    });
  }

  void _clearAllNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear All Notifications'),
        content: Text('Are you sure you want to clear all notifications?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'CANCEL',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _notifications.clear();
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('All notifications cleared'),
                  backgroundColor: Colors.green.shade700,
                ),
              );
            },
            child: Text(
              'CLEAR',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNotificationAction(Map<String, dynamic> notification) {
    // Implement navigation based on notification type
    final type = notification['type'] as String;
    
    // Mark as read when action is taken
    _markAsRead(notification['id']);
    
    switch (type) {
      case 'appointment':
        // Navigate to appointments tab
        break;
      case 'treatment':
        // Navigate to treatment details
        break;
      case 'recommendation':
        // Navigate to recommendations
        break;
      case 'message':
        // Navigate to message details
        break;
      case 'general':
      default:
        // Handle general navigation
        break;
    }
  }
}
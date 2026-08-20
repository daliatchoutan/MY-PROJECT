import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final notifs = await auth.api.getNotifications();
      setState(() {
        _notifications = notifs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllAsRead() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.api.markAllNotificationsAsRead();
    _fetchNotifications();
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'ai_alert':
        return Icons.warning_amber_rounded;
      case 'environmental_alert':
        return Icons.thermostat_outlined;
      case 'order_update':
        return Icons.shopping_bag_outlined;
      case 'delivery_update':
        return Icons.local_shipping_outlined;
      default:
        return Icons.notifications_active_outlined;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'ai_alert':
        return Colors.red;
      case 'environmental_alert':
        return Colors.orange;
      case 'order_update':
        return Colors.blue;
      case 'delivery_update':
        return Colors.purple;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts & Notifications'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: _markAllAsRead,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchNotifications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text(
                        'No notifications in your feed',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final item = _notifications[index];
                      final isRead = item['isRead'] ?? false;
                      final type = item['type'] ?? 'system';

                      return Card(
                        elevation: isRead ? 1 : 3,
                        color: isRead ? Colors.grey.shade50 : Colors.white,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getColorForType(type).withOpacity(0.15),
                            child: Icon(_getIconForType(type), color: _getColorForType(type)),
                          ),
                          title: Text(
                            item['title'] ?? 'Notification',
                            style: TextStyle(
                              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(item['message'] ?? ''),
                              const SizedBox(height: 4),
                              Text(
                                item['createdAt'] != null
                                    ? item['createdAt'].toString().substring(0, 19).replaceAll('T', ' ')
                                    : '',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                          trailing: isRead
                              ? null
                              : const Icon(Icons.circle, color: Colors.green, size: 10),
                          onTap: () async {
                            if (!isRead) {
                              final auth = Provider.of<AuthProvider>(context, listen: false);
                              await auth.api.markNotificationAsRead(item['id']);
                              _fetchNotifications();
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

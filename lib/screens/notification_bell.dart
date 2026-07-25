import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_event.dart';
import '../services/event_service.dart';
import '../screens/add_edit_vulnerability_screen.dart';

class NotificationBell extends StatelessWidget {
  final String role;
  const NotificationBell({super.key, required this.role});

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final eventService = EventService();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<List<AppEvent>>(
      stream: eventService.getNotificationsForUser(uid),
      builder: (context, snapshot) {
        final notifications = snapshot.data ?? [];
        final unreadCount =
            notifications.where((n) => !n.readBy.contains(uid)).length;

        return PopupMenuButton<void>(
          icon: Badge(
            label: Text(unreadCount.toString()),
            isLabelVisible: unreadCount > 0,
            child: const Icon(Icons.notifications),
          ),
          itemBuilder: (context) {
            if (notifications.isEmpty) {
              return [
                const PopupMenuItem(
                  enabled: false,
                  child: Text('No notifications yet.'),
                ),
              ];
            }

            return notifications.map((notification) {
              final isUnread = !notification.readBy.contains(uid);

              return PopupMenuItem(
                onTap: () {
                  // mark it read the moment it's tapped
                  eventService.markAsRead(notification.id, uid);
                },
                child: ListTile(
                  dense: true,
                  leading: Icon(
                    isUnread ? Icons.circle : Icons.circle_outlined,
                    size: 10,
                    color: isUnread ? Colors.blue : Colors.grey,
                  ),
                  title: Text(
                    notification.message,
                    style: TextStyle(
                      fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(_timeAgo(notification.timestamp)),
                ),
              );
            }).toList();
          },
        );
      },
    );
  }
}
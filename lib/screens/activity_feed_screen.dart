import 'package:flutter/material.dart';
import '../models/app_event.dart';
import '../services/event_service.dart';

class ActivityFeedScreen extends StatelessWidget {
  const ActivityFeedScreen({super.key});

  // shows a friendly relative time, like "5m ago" or "2h ago"
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

    return Scaffold(
      appBar: AppBar(title: const Text('Activity')),
      body: StreamBuilder<List<AppEvent>>(
        stream: eventService.getRecentEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final events = snapshot.data ?? [];

          if (events.isEmpty) {
            return const Center(child: Text('No activity yet.'));
          }

          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return ListTile(
                leading: const Icon(Icons.circle_notifications_outlined),
                title: Text('${event.actorEmail} ${event.message}'),
                subtitle: Text(_timeAgo(event.timestamp)),
              );
            },
          );
        },
      ),
    );
  }
}
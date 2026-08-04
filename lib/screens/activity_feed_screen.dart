import 'package:flutter/material.dart';
import '../models/app_event.dart';
import '../services/event_service.dart';
import 'package:printing/printing.dart';
import 'dart:typed_data';
import '../services/activity_report_service.dart';
import '../widgets/theme_toggle_button.dart';

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
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Activity'),
            Text(
              'Team audit trail',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export Activity Report',
            onPressed: () => _handleExportActivity(context),
          ),
          const ThemeToggleButton(),
        ],
      ),
      body: StreamBuilder<List<AppEvent>>(
        stream: eventService.getRecentEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final events = snapshot.data ?? [];

          if (events.isEmpty) {
            return const Center(
              child: Text('No activity has been recorded yet.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            itemCount: events.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final event = events[index];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      Icons.history_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    event.message,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(
                      '${event.actorEmail}  •  ${_timeAgo(event.timestamp)}',
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _handleExportActivity(BuildContext context) async {
    // ask the user to pick a range, or export everything
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Activity Report'),
        content: const Text(
          'Choose a date range, or export all recorded activity.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'all'),
            child: const Text('All Activity'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'range'),
            child: const Text('Pick a Date Range'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (choice == null || choice == 'cancel') return;

    DateTime? start;
    DateTime? end;
    String rangeLabel = 'All Activity';

    if (choice == 'range') {
      if (!context.mounted) return;

      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2024),
        lastDate: DateTime.now(),
      );

      if (picked == null) return; // user cancelled the picker

      start = picked.start;
      // include the entire end day, not just midnight of that day
      end = DateTime(
        picked.end.year,
        picked.end.month,
        picked.end.day,
        23,
        59,
        59,
      );
      rangeLabel =
          '${start.month}/${start.day}/${start.year} - ${end.month}/${end.day}/${end.year}';
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final eventService = EventService();
    final events = await eventService.getEventsInRange(start, end);

    final reportService = ActivityReportService();
    final pdfBytes = await reportService.generateActivityReport(
      events: events,
      rangeLabel: rangeLabel,
    );

    if (context.mounted) {
      Navigator.pop(context); // close loading dialog
    }

    await Printing.sharePdf(
      bytes: Uint8List.fromList(pdfBytes),
      filename: 'vulnera-activity-report.pdf',
    );
  }
}

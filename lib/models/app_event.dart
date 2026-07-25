import 'package:cloud_firestore/cloud_firestore.dart';

class AppEvent {
  final String id;
  final String message;
  final String actorEmail; // who did the action
  final DateTime timestamp;

  AppEvent({
    required this.id,
    required this.message,
    required this.actorEmail,
    required this.timestamp,
  });

  factory AppEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppEvent(
      id: doc.id,
      message: data['message'] ?? '',
      actorEmail: data['actorEmail'] ?? 'Unknown',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
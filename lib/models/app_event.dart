import 'package:cloud_firestore/cloud_firestore.dart';

class AppEvent {
  final String id;
  final String message;
  final String actorEmail;
  final DateTime timestamp;
  final String? notifiedUid;
  final List<String> readBy;

  AppEvent({
    required this.id,
    required this.message,
    required this.actorEmail,
    required this.timestamp,
    this.notifiedUid,
    this.readBy = const [],
  });

  factory AppEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppEvent(
      id: doc.id,
      message: data['message'] ?? '',
      actorEmail: data['actorEmail'] ?? 'Unknown',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notifiedUid: data['notifiedUid'],
      readBy: List<String>.from(data['readBy'] ?? []),
    );
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_event.dart';

class EventService {
  final CollectionReference _eventsRef =
      FirebaseFirestore.instance.collection('events');

  // writes a new event to the feed - called from other services
  // whenever something worth logging happens
  Future<void> logEvent(String message) async {
    final email = FirebaseAuth.instance.currentUser?.email ?? 'Unknown';

    await _eventsRef.add({
      'message': message,
      'actorEmail': email,
      'timestamp': Timestamp.now(),
    });
  }

  // gives a live stream of the most recent events, newest first
  Stream<List<AppEvent>> getRecentEvents() {
    return _eventsRef
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => AppEvent.fromFirestore(doc)).toList();
    });
  }
}
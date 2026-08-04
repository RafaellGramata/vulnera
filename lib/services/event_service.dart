import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_event.dart';

class EventService {
  final CollectionReference _eventsRef = FirebaseFirestore.instance.collection(
    'events',
  );

  // writes a new event to the feed - called from other services
  // whenever something worth logging happens.
  // notifiedUid is optional - only set when this event is a personal
  // notification for a specific person (like being assigned something)
  Future<void> logEvent(String message, {String? notifiedUid}) async {
    final email = FirebaseAuth.instance.currentUser?.email ?? 'Unknown';

    await _eventsRef.add({
      'message': message,
      'actorEmail': email,
      'timestamp': Timestamp.now(),
      'notifiedUid': notifiedUid,
      'readBy': <String>[], // list of uids who have marked this as read
    });
  }

  // gives a live stream of the most recent events, newest first
  Stream<List<AppEvent>> getRecentEvents() {
    return _eventsRef
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => AppEvent.fromFirestore(doc))
              .toList();
        });
  }

  // gives a live stream of notifications meant for a specific user
  Stream<List<AppEvent>> getNotificationsForUser(String uid) {
    return _eventsRef
        .where('notifiedUid', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => AppEvent.fromFirestore(doc))
              .toList();
        });
  }

  // marks a single notification as read by a specific user
  Future<void> markAsRead(String eventId, String uid) async {
    await _eventsRef.doc(eventId).update({
      'readBy': FieldValue.arrayUnion([uid]),
    });
  }

  // fetches events within a date range - if either date is null,
  // that side is unbounded (e.g. null end means "up to now")
  Future<List<AppEvent>> getEventsInRange(
    DateTime? start,
    DateTime? end,
  ) async {
    Query query = _eventsRef.orderBy('timestamp', descending: true);

    if (start != null) {
      query = query.where(
        'timestamp',
        isGreaterThanOrEqualTo: Timestamp.fromDate(start),
      );
    }
    if (end != null) {
      query = query.where(
        'timestamp',
        isLessThanOrEqualTo: Timestamp.fromDate(end),
      );
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => AppEvent.fromFirestore(doc)).toList();
  }
}

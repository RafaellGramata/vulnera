import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import 'event_service.dart';

class UserService {
  final EventService _eventService = EventService();
  final CollectionReference _usersRef = FirebaseFirestore.instance.collection(
    'users',
  );

  Stream<AppUser?> getCurrentUserProfile() {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return Stream.value(null);
    }

    return _usersRef.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AppUser.fromFirestore(doc);
    });
  }

  Stream<List<AppUser>> getAllUsers() {
    return _usersRef.orderBy('email').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList();
    });
  }

  Future<void> updateUserRole(String uid, String newRole) async {
    final userDoc = await _usersRef.doc(uid).get();
    final userData = userDoc.data() as Map<String, dynamic>?;
    final targetEmail = userData?['email'] ?? 'a user';

    await _usersRef.doc(uid).update({'role': newRole});
    await _eventService.logEvent('changed $targetEmail\'s role to $newRole');
  }
}

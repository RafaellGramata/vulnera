import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';

class UserService {
  final CollectionReference _usersRef =
      FirebaseFirestore.instance.collection('users');

  // gives a live stream of the currently logged in user's profile,
  // so the app updates automatically if their role ever changes
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
}
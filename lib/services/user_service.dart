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

  // gives a live stream of every user, so an admin can manage roles
  Stream<List<AppUser>> getAllUsers() {
    return _usersRef.orderBy('email').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList();
    });
  }

  // updates a specific user's role - firestore rules only allow
  // this to actually succeed if the caller is an admin
  Future<void> updateUserRole(String uid, String newRole) async {
    await _usersRef.doc(uid).update({'role': newRole});
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String role;

  AppUser({required this.uid, required this.email, required this.role});

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      email: data['email'] ?? '',
      role: data['role'] ?? 'Analyst',
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // creates a new account with email and password
  Future<String?> signUp(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // every new user gets a profile document in firestore,
      // storing their role - defaults to 'Analyst' since that's
      // a reasonable middle-ground for a new team member
      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
        'email': email,
        'role': 'Analyst',
        'createdAt': Timestamp.now(),
      });

      return null; // null means no error
    } on FirebaseAuthException catch (e) {
      return e.message; // return the error so the ui can show it
    }
  }

  // logs in an existing user
  Future<String?> logIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // logs the current user out
  Future<void> logOut() async {
    await _auth.signOut();
  }

  // gives us the currently logged in user, or null if nobody is logged in
  User? get currentUser => _auth.currentUser;
}
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // creates a new account with email and password
  Future<String?> signUp(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null; // null means no error
    } on FirebaseAuthException catch (e) {
      return e.message;
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

  User? get currentUser => _auth.currentUser;
}
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'main_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // authStateChanges is a live stream that fires whenever the user
    // logs in, logs out, or the app starts up with an existing session
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // while firebase is still figuring out if someone's logged in,
        // show a loading spinner instead of flashing the login screen
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // snapshot.data is the current user, or null if nobody's logged in
        if (snapshot.hasData) {
          return const MainScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
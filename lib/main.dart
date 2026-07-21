import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // this file comes from flutterfire configure
import 'screens/login_screen.dart';

void main() async {
  // this line is needed before using any firebase feature
  WidgetsFlutterBinding.ensureInitialized();

  // connects our app to the firebase project
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ProjectNameABC',
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),
    );
  }
}
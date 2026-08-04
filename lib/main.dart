import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // this file comes from flutterfire configure
import 'screens/auth_gate.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

void main() async {
  // this line is needed before using any firebase feature
  WidgetsFlutterBinding.ensureInitialized();

  // connects our app to the firebase project
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeController,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'Vulnera',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          home: const AuthGate(),
        );
      },
    );
  }
}

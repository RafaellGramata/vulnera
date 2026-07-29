import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // this file comes from flutterfire configure
import 'screens/auth_gate.dart';
import 'services/port_severity_mapper.dart';

void main() async {
  // this line is needed before using any firebase feature
  WidgetsFlutterBinding.ensureInitialized();

  // TEMPORARY sanity check - confirms the port mapper returns sensible values
  final testPorts = [21, 22, 23, 80, 443, 445, 3389, 9999];
  for (final port in testPorts) {
    final finding = PortSeverityMapper.findingForPort(port);
    print('Port $port -> ${finding.severity} (${finding.cvssScore}): ${finding.title}');
  }

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
      home: const AuthGate(),
    );
  }
}
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'auth_gate.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const SwimForceApp());
}

class SwimForceApp extends StatelessWidget {
  const SwimForceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SwimForce+',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF061226),
        fontFamily: 'Arial',
      ),
      home: const AuthGate(),
    );
  }
}
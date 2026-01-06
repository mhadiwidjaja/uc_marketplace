import 'package:flutter/material.dart';
import 'login_page.dart'; // Changed to LoginPage
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  // 1. Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Firebase
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
      title: 'UC Marketplace',
      debugShowCheckedModeBanner: false, // Removes the debug banner
      theme: ThemeData(
        // We can define the global orange color here based on your image
        primaryColor: const Color(0xFFF39C12),
        useMaterial3: true,
      ),
      home: const LoginPage(), // Changed to LoginPage
    );
  }
}
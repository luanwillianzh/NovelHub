import 'package:flutter/material.dart';

// 1. IMPORT YOUR HOME SCREEN
// Make sure this path is correct. If 'home_screen.dart' is in lib/,
// just use 'home_screen.dart'.
import 'screens/home_screen.dart'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Novel Reader', // You can change this
      theme: ThemeData(
        // Using a dark theme is often good for reading apps
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false, // Hides the "debug" banner

      // 2. SET THE HOME PAGE
      // This is the main change. We point 'home' to your HomeScreen.
      home: const HomeScreen(),
    );
  }
}

// 3. REMOVED
// The old 'MyHomePage' and '_MyHomePageState' classes that
// contained the counter logic have been deleted from this file.
import 'package:flutter/material.dart';
import 'screens/home_page.dart';

void main() {
  runApp(const MacroDeckApp());
}

class MacroDeckApp extends StatelessWidget {
  const MacroDeckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Macro-Deck',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF1E1E1E),
        ),
      ),
      home: const HomePage(),
    );
  }
}

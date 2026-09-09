import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const LyricsApp());
}

class LyricsApp extends StatelessWidget {
  const LyricsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '노래 가사 인식 (Song Lyrics)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFF0E0E12),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0E0E12),
          elevation: 0,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

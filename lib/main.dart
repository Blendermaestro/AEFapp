import 'package:flutter/material.dart';
import 'screens/work_card_screen.dart';

void main() {
  runApp(const WorkCardApp());
}

class WorkCardApp extends StatefulWidget {
  const WorkCardApp({super.key});

  @override
  State<WorkCardApp> createState() => _WorkCardAppState();
}

class _WorkCardAppState extends State<WorkCardApp> {
  bool _isDarkMode = false;

  void _toggleTheme(bool isDark) {
    setState(() {
      _isDarkMode = isDark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Työkorttisovellus',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: WorkCardScreen(onThemeChanged: _toggleTheme),
    );
  }
} 
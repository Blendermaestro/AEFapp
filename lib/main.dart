import 'package:flutter/material.dart';
import 'screens/work_card_screen.dart';
import 'services/local_storage_service.dart';

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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDarkModePreference();
  }

  Future<void> _loadDarkModePreference() async {
    try {
      final savedDarkMode = await LocalStorageService.loadDarkMode();
      setState(() {
        _isDarkMode = savedDarkMode;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isDarkMode = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleTheme(bool isDark) async {
    setState(() {
      _isDarkMode = isDark;
    });
    // Save the preference
    await LocalStorageService.saveDarkMode(isDark);
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while loading preferences
    if (_isLoading) {
      return MaterialApp(
        home: Scaffold(
          body: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

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
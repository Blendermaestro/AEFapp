import 'package:flutter/material.dart';
import 'screens/work_card_screen.dart';
import 'screens/auth_screen.dart';
import 'services/local_storage_service.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await SupabaseService.initialize();
  
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
  bool _showAuth = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Load dark mode preference
      final savedDarkMode = await LocalStorageService.loadDarkMode();
      
      setState(() {
        _isDarkMode = savedDarkMode;
        _isLoading = false;
        // Show auth screen only if user wants to login (they can skip)
        _showAuth = false; // Start with work card screen, user can choose to login
      });
    } catch (e) {
      setState(() {
        _isDarkMode = false;
        _isLoading = false;
        _showAuth = false;
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

  void _onAuthenticated() {
    setState(() {
      _showAuth = false;
    });
  }

  void _showAuthScreen() {
    setState(() {
      _showAuth = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while initializing
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
      home: _showAuth
          ? AuthScreen(onAuthenticated: _onAuthenticated)
          : WorkCardScreen(
              onThemeChanged: _toggleTheme,
              onShowAuth: _showAuthScreen,
            ),
    );
  }
} 
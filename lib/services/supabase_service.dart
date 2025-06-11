import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/work_card_screen.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class SupabaseService {
  // Define keys for environment variables
  static const String supabaseUrlEnvKey = 'SUPABASE_URL';
  static const String supabaseAnonKeyEnvKey = 'SUPABASE_ANON_KEY';

  // Attempt to get credentials from environment variables, with fallbacks to hardcoded values.
  static const String supabaseUrl = String.fromEnvironment(
    supabaseUrlEnvKey,
    defaultValue: 'https://zkgrctejqujcmsdebten.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    supabaseAnonKeyEnvKey,
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InprZ3JjdGVqcXVqY21zZGVidGVuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk2MzY1ODMsImV4cCI6MjA2NTIxMjU4M30.SWQc9ORjpi90a-wZQ32NdnFE3R_gH0GmVALHnHcLb9k',
  );
  
  static bool _isAvailable = false;
  static bool isConfigured = false;
  
  static bool get isAvailable => _isAvailable;
  
  static SupabaseClient? get client {
    try {
      return _isAvailable ? Supabase.instance.client : null;
    } catch (e) {
      return null;
    }
  }
  
  static User? get currentUser {
    try {
      return client?.auth.currentUser;
    } catch (e) {
      return null;
    }
  }
  
  static bool get isLoggedIn {
    try {
      return currentUser != null && _isAvailable;
    } catch (e) {
      return false;
    }
  }
  
  /// Initialize Supabase with error handling
  static Future<void> initialize() async {
    // Check if the app is running with credentials from environment variables
    isConfigured = const bool.hasEnvironment(supabaseUrlEnvKey) &&
                   const bool.hasEnvironment(supabaseAnonKeyEnvKey);

    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      _isAvailable = false;
      print('Supabase credentials are not configured. App will use local storage only.');
      print('To enable Supabase, provide SUPABASE_URL and SUPABASE_ANON_KEY via --dart-define.');
      return;
    }

    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
      _isAvailable = true;
      if (isConfigured) {
        print('Supabase initialized successfully using credentials from environment variables.');
      } else {
        print('Supabase initialized successfully using hardcoded credentials.');
        print('WARNING: For production, use --dart-define to set Supabase credentials.');
      }
    } catch (e) {
      _isAvailable = false;
      print('Supabase initialization failed: $e');
      print('App will use local storage only.');
    }
  }
  
  /// Sign up with email and password
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    if (!_isAvailable || client == null) {
      throw Exception('Cloud sync is currently unavailable. Please try again later.');
    }
    
    try {
      return await client!.auth.signUp(
        email: email,
        password: password,
        data: displayName != null ? {'display_name': displayName} : null,
      );
    } catch (e) {
      if (e.toString().contains('401')) {
        throw Exception('Authentication service is temporarily unavailable. Please try again later.');
      }
      rethrow;
    }
  }
  
  /// Sign in with email and password
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    if (!_isAvailable || client == null) {
      throw Exception('Cloud sync is currently unavailable. Please try again later.');
    }
    
    try {
      return await client!.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      if (e.toString().contains('401')) {
        throw Exception('Authentication service is temporarily unavailable. Please try again later.');
      }
      rethrow;
    }
  }
  
  /// Sign out
  static Future<void> signOut() async {
    await client?.auth.signOut();
  }
  
  /// Save work cards to cloud
  static Future<void> saveWorkCards(List<ProfessionCardData> cards) async {
    if (!isLoggedIn) return;
    
    // Delete existing cards for this user
    await client
        ?.from('work_cards')
        .delete()
        .eq('user_id', currentUser!.id);
    
    // Insert new cards
    final List<Map<String, dynamic>> cardsData = cards.map((card) => {
      'user_id': currentUser!.id,
      'profession_name': card.professionName,
      'pdf_name1': card.pdfName1,
      'pdf_name2': card.pdfName2,
      'excel_name1': card.excelName1,
      'excel_name2': card.excelName2,
      'tasks': card.tasks.map((task) => task.toJson()).toList(),
      'equipment': card.equipment,
      'equipment_location': card.equipmentLocation,
    }).toList();
    
    if (cardsData.isNotEmpty) {
      await client?.from('work_cards').insert(cardsData);
    }
  }
  
  /// Load work cards from cloud
  static Future<List<ProfessionCardData>> loadWorkCards() async {
    if (!isLoggedIn) return [];
    
    final response = await client
        ?.from('work_cards')
        .select()
        .eq('user_id', currentUser!.id)
        .order('created_at');
    
    if (response == null) return [];
    
    return response.map<ProfessionCardData>((data) {
      return ProfessionCardData(
        professionName: data['profession_name'] ?? '',
        pdfName1: data['pdf_name1'] ?? '',
        pdfName2: data['pdf_name2'] ?? '',
        excelName1: data['excel_name1'] ?? '',
        excelName2: data['excel_name2'] ?? '',
        tasks: (data['tasks'] as List<dynamic>?)
            ?.map((taskJson) => TaskData.fromJson(taskJson))
            .toList() ?? [TaskData()],
        equipment: data['equipment'] ?? '',
        equipmentLocation: data['equipment_location'] ?? '',
      );
    }).toList();
  }
  
  /// Save user settings to cloud
  static Future<void> saveUserSettings(Map<String, dynamic> settings) async {
    if (!isLoggedIn) {
      print('SupabaseService: Not logged in, cannot save user settings');
      return;
    }

    try {
      final currentUser = client?.auth.currentUser;
      if (currentUser == null) {
        print('SupabaseService: No current user');
        return;
      }

      final userSettings = {
        'user_id': currentUser.id,
        'pdf_supervisor': settings['pdf_supervisor'] ?? '',
        'pdf_date': settings['pdf_date'] ?? '',
        'pdf_shift': settings['pdf_shift'] ?? '',
        'excel_supervisor': settings['excel_supervisor'] ?? '',
        'excel_date': settings['excel_date'] ?? '',
        'excel_shift': settings['excel_shift'] ?? '',
        'global_notice': settings['global_notice'] ?? '',
        'shift_notes': settings['shift_notes'] ?? [],
        'comments': settings['comments'] ?? [],
        'extra_work': settings['extra_work'] ?? [],
        'updated_at': DateTime.now().toIso8601String(),
      };

      print('SupabaseService: Saving user settings to user_settings table');
      await client
          ?.from('user_settings')
          .upsert(userSettings, onConflict: 'user_id');
      
      print('SupabaseService: Successfully saved user settings');
    } catch (e) {
      print('SupabaseService: Error saving user settings: $e');
      rethrow;
    }
  }
  
  /// Load user settings from cloud
  static Future<Map<String, dynamic>?> loadUserSettings() async {
    if (!isLoggedIn) return null;
    
    final response = await client
        ?.from('user_settings')
        .select()
        .eq('user_id', currentUser!.id)
        .maybeSingle();
    
    return response;
  }
  
  /// Listen to real-time changes
  static Stream<List<Map<String, dynamic>>> watchWorkCards() {
    if (!isLoggedIn) return Stream.empty();
    
    return client
        ?.from('work_cards')
        .stream(primaryKey: ['id'])
        .eq('user_id', currentUser!.id) ?? Stream.empty();
  }
} 
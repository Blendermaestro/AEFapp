import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/work_card_screen.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://zkgrctejqujcmsdebten.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InprZ3JjdGVqcXVqY21zZGVidGVuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzM4NTIwOTcsImV4cCI6MjA0OTQyODA5N30.D1vHmRMxJOL1Z1Dn3j1vQnVlUIcBHDGSd6bpvKzH9iI';
  
  static SupabaseClient get client => Supabase.instance.client;
  static User? get currentUser => client.auth.currentUser;
  static bool get isLoggedIn => currentUser != null;
  
  /// Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
  
  /// Sign up with email and password
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: displayName != null ? {'display_name': displayName} : null,
    );
  }
  
  /// Sign in with email and password
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  
  /// Sign out
  static Future<void> signOut() async {
    await client.auth.signOut();
  }
  
  /// Save work cards to cloud
  static Future<void> saveWorkCards(List<ProfessionCardData> cards) async {
    if (!isLoggedIn) return;
    
    // Delete existing cards for this user
    await client
        .from('work_cards')
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
      await client.from('work_cards').insert(cardsData);
    }
  }
  
  /// Load work cards from cloud
  static Future<List<ProfessionCardData>> loadWorkCards() async {
    if (!isLoggedIn) return [];
    
    final response = await client
        .from('work_cards')
        .select()
        .eq('user_id', currentUser!.id)
        .order('created_at');
    
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
  static Future<void> saveUserSettings({
    required String pdfSupervisor,
    required String pdfDate,
    required String pdfShift,
    required String excelSupervisor,
    required String excelDate,
    required String excelShift,
    required String globalNotice,
    required List<String> shiftNotes,
    required List<String> comments,
    required List<String> extraWork,
  }) async {
    if (!isLoggedIn) return;
    
    final settingsData = {
      'user_id': currentUser!.id,
      'pdf_supervisor': pdfSupervisor,
      'pdf_date': pdfDate,
      'pdf_shift': pdfShift,
      'excel_supervisor': excelSupervisor,
      'excel_date': excelDate,
      'excel_shift': excelShift,
      'global_notice': globalNotice,
      'shift_notes': shiftNotes,
      'comments': comments,
      'extra_work': extraWork,
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    await client
        .from('user_settings')
        .upsert(settingsData);
  }
  
  /// Load user settings from cloud
  static Future<Map<String, dynamic>?> loadUserSettings() async {
    if (!isLoggedIn) return null;
    
    final response = await client
        .from('user_settings')
        .select()
        .eq('user_id', currentUser!.id)
        .maybeSingle();
    
    return response;
  }
  
  /// Listen to real-time changes
  static Stream<List<Map<String, dynamic>>> watchWorkCards() {
    if (!isLoggedIn) return Stream.empty();
    
    return client
        .from('work_cards')
        .stream(primaryKey: ['id'])
        .eq('user_id', currentUser!.id);
  }
} 
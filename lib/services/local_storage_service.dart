import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/work_card_screen.dart';

class LocalStorageService {
  static const String _supervisorKey = 'supervisor';
  static const String _dateKey = 'date';
  static const String _shiftKey = 'shift';
  static const String _professionCardsKey = 'profession_cards';
  static const String _globalNoticeKey = 'global_notice';
  static const String _excelSpecificFieldsKey = 'excel_specific_fields';
  static const String _darkModeKey = 'dark_mode';
  static const String _namesDatabaseKey = 'names_database';
  static const String _supervisorsDatabaseKey = 'supervisors_database';
  static const String _equipmentDatabaseKey = 'equipment_database';
  static const String _shiftNotesKey = 'shift_notes';

  static Future<SharedPreferences> get _prefs async =>
      await SharedPreferences.getInstance();

  // Basic fields - separate for PDF and Excel
  static Future<void> savePdfSupervisor(String supervisor) async {
    final prefs = await _prefs;
    await prefs.setString('pdf_supervisor', supervisor);
  }

  static Future<String> loadPdfSupervisor() async {
    final prefs = await _prefs;
    return prefs.getString('pdf_supervisor') ?? '';
  }

  static Future<void> saveExcelSupervisor(String supervisor) async {
    final prefs = await _prefs;
    await prefs.setString('excel_supervisor', supervisor);
  }

  static Future<String> loadExcelSupervisor() async {
    final prefs = await _prefs;
    return prefs.getString('excel_supervisor') ?? '';
  }

  static Future<void> savePdfDate(String date) async {
    final prefs = await _prefs;
    await prefs.setString('pdf_date', date);
  }

  static Future<String> loadPdfDate() async {
    final prefs = await _prefs;
    return prefs.getString('pdf_date') ?? '';
  }

  static Future<void> saveExcelDate(String date) async {
    final prefs = await _prefs;
    await prefs.setString('excel_date', date);
  }

  static Future<String> loadExcelDate() async {
    final prefs = await _prefs;
    return prefs.getString('excel_date') ?? '';
  }

  static Future<void> savePdfShift(String shift) async {
    final prefs = await _prefs;
    await prefs.setString('pdf_shift', shift);
  }

  static Future<String> loadPdfShift() async {
    final prefs = await _prefs;
    return prefs.getString('pdf_shift') ?? '';
  }

  static Future<void> saveExcelShift(String shift) async {
    final prefs = await _prefs;
    await prefs.setString('excel_shift', shift);
  }

  static Future<String> loadExcelShift() async {
    final prefs = await _prefs;
    return prefs.getString('excel_shift') ?? '';
  }

  // PDF2 tab fields
  static Future<void> savePdf2Supervisor(String supervisor) async {
    final prefs = await _prefs;
    await prefs.setString('pdf2_supervisor', supervisor);
  }

  static Future<String> loadPdf2Supervisor() async {
    final prefs = await _prefs;
    return prefs.getString('pdf2_supervisor') ?? '';
  }

  static Future<void> savePdf2Date(String date) async {
    final prefs = await _prefs;
    await prefs.setString('pdf2_date', date);
  }

  static Future<String> loadPdf2Date() async {
    final prefs = await _prefs;
    return prefs.getString('pdf2_date') ?? '';
  }

  static Future<void> savePdf2Shift(String shift) async {
    final prefs = await _prefs;
    await prefs.setString('pdf2_shift', shift);
  }

  static Future<String> loadPdf2Shift() async {
    final prefs = await _prefs;
    return prefs.getString('pdf2_shift') ?? '';
  }

  // PDF3 tab fields
  static Future<void> savePdf3Supervisor(String supervisor) async {
    final prefs = await _prefs;
    await prefs.setString('pdf3_supervisor', supervisor);
  }

  static Future<String> loadPdf3Supervisor() async {
    final prefs = await _prefs;
    return prefs.getString('pdf3_supervisor') ?? '';
  }

  static Future<void> savePdf3Date(String date) async {
    final prefs = await _prefs;
    await prefs.setString('pdf3_date', date);
  }

  static Future<String> loadPdf3Date() async {
    final prefs = await _prefs;
    return prefs.getString('pdf3_date') ?? '';
  }

  static Future<void> savePdf3Shift(String shift) async {
    final prefs = await _prefs;
    await prefs.setString('pdf3_shift', shift);
  }

  static Future<String> loadPdf3Shift() async {
    final prefs = await _prefs;
    return prefs.getString('pdf3_shift') ?? '';
  }

  // Legacy methods for backward compatibility (keep for now)
  static Future<void> saveSupervisor(String supervisor) async {
    final prefs = await _prefs;
    await prefs.setString('supervisor', supervisor);
  }

  static Future<String> loadSupervisor() async {
    final prefs = await _prefs;
    return prefs.getString('supervisor') ?? '';
  }

  static Future<void> saveDate(String date) async {
    final prefs = await _prefs;
    await prefs.setString('date', date);
  }

  static Future<String> loadDate() async {
    final prefs = await _prefs;
    return prefs.getString('date') ?? '';
  }

  static Future<void> saveShift(String shift) async {
    final prefs = await _prefs;
    await prefs.setString('shift', shift);
  }

  static Future<String> loadShift() async {
    final prefs = await _prefs;
    return prefs.getString('shift') ?? '';
  }

  // Save profession cards
  static Future<void> saveProfessionCards(List<ProfessionCardData> cards) async {
    final prefs = await _prefs;
    final cardsJson = cards.map((card) => card.toJson()).toList();
    final jsonString = jsonEncode(cardsJson);
    print('LocalStorageService: Saving ${cards.length} cards, JSON length: ${jsonString.length}');
    await prefs.setString(_professionCardsKey, jsonString);
    print('LocalStorageService: Cards saved to SharedPreferences');
  }

  // Load profession cards
  static Future<List<ProfessionCardData>> loadProfessionCards() async {
    final prefs = await _prefs;
    final cardsString = prefs.getString(_professionCardsKey);
    print('LocalStorageService: Loading cards, stored string length: ${cardsString?.length ?? 0}');
    if (cardsString == null) {
      print('LocalStorageService: No cards found in storage');
      return [];
    }
    
    try {
      final cardsList = jsonDecode(cardsString) as List;
      final cards = cardsList.map((cardJson) => ProfessionCardData.fromJson(cardJson)).toList();
      print('LocalStorageService: Successfully loaded ${cards.length} cards');
      return cards;
    } catch (e) {
      print('LocalStorageService: Error loading cards: $e');
      return [];
    }
  }

  // Save global notice
  static Future<void> saveGlobalNotice(String notice) async {
    final prefs = await _prefs;
    await prefs.setString(_globalNoticeKey, notice);
  }

  // Load global notice
  static Future<String> loadGlobalNotice() async {
    final prefs = await _prefs;
    return prefs.getString(_globalNoticeKey) ?? '';
  }

  // Save excel specific fields
  static Future<void> saveExcelSpecificFields(Map<String, dynamic> fields) async {
    final prefs = await _prefs;
    await prefs.setString(_excelSpecificFieldsKey, jsonEncode(fields));
  }

  // Load excel specific fields
  static Future<Map<String, dynamic>> loadExcelSpecificFields() async {
    final prefs = await _prefs;
    final fieldsString = prefs.getString(_excelSpecificFieldsKey);
    if (fieldsString == null) return {};
    
    try {
      return jsonDecode(fieldsString) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  // Save dark mode preference
  static Future<void> saveDarkMode(bool isDarkMode) async {
    final prefs = await _prefs;
    await prefs.setBool(_darkModeKey, isDarkMode);
  }

  // Load dark mode preference
  static Future<bool> loadDarkMode() async {
    final prefs = await _prefs;
    return prefs.getBool(_darkModeKey) ?? false;
  }

  // Save databases
  static Future<void> saveNamesDatabase(List<String> names) async {
    final prefs = await _prefs;
    await prefs.setStringList(_namesDatabaseKey, names);
  }

  static Future<List<String>> loadNamesDatabase() async {
    final prefs = await _prefs;
    return prefs.getStringList(_namesDatabaseKey) ?? [];
  }

  static Future<void> saveSupervisorsDatabase(List<String> supervisors) async {
    final prefs = await _prefs;
    await prefs.setStringList(_supervisorsDatabaseKey, supervisors);
  }

  static Future<List<String>> loadSupervisorsDatabase() async {
    final prefs = await _prefs;
    return prefs.getStringList(_supervisorsDatabaseKey) ?? [];
  }

  static Future<void> saveEquipmentDatabase(List<String> equipment) async {
    final prefs = await _prefs;
    await prefs.setStringList(_equipmentDatabaseKey, equipment);
  }

  static Future<List<String>> loadEquipmentDatabase() async {
    final prefs = await _prefs;
    return prefs.getStringList(_equipmentDatabaseKey) ?? [];
  }

  // Save shift notes
  static Future<void> saveShiftNotes(List<String> shiftNotes) async {
    final prefs = await _prefs;
    await prefs.setStringList(_shiftNotesKey, shiftNotes);
  }

  // Load shift notes
  static Future<List<String>> loadShiftNotes() async {
    final prefs = await _prefs;
    return prefs.getStringList(_shiftNotesKey) ?? [''];
  }

  // Save shift notes for PDF2
  static Future<void> saveShiftNotes2(List<String> shiftNotes) async {
    final prefs = await _prefs;
    await prefs.setStringList('shift_notes2', shiftNotes);
  }

  // Load shift notes for PDF2
  static Future<List<String>> loadShiftNotes2() async {
    final prefs = await _prefs;
    return prefs.getStringList('shift_notes2') ?? [''];
  }

  // Save shift notes for PDF3
  static Future<void> saveShiftNotes3(List<String> shiftNotes) async {
    final prefs = await _prefs;
    await prefs.setStringList('shift_notes3', shiftNotes);
  }

  // Load shift notes for PDF3
  static Future<List<String>> loadShiftNotes3() async {
    final prefs = await _prefs;
    return prefs.getStringList('shift_notes3') ?? [''];
  }

  // Clear all data
  static Future<void> clearAllData() async {
    final prefs = await _prefs;
    await prefs.clear();
  }
} 
import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html;
import '../screens/work_card_screen.dart';

class ExcelService {
  /// Export work card data to Excel using the pre-made template
  static Future<void> exportToExcel({
    required String excelSupervisor,
    required String excelShift,
    required String excelDate,
    required List<String> comments,
    required List<String> extraWork,
    required List<ProfessionCardData> professionCards,
  }) async {
    try {
      // Debug: Verify data before export
      _logDataSummary(excelSupervisor, excelShift, excelDate, comments, extraWork, professionCards);
      
      Excel excel;
      Sheet sheet;
      
      try {
        // Try to load the template from assets
        final ByteData data = await rootBundle.load('assets/template.xlsx');
        final Uint8List bytes = data.buffer.asUint8List();
        excel = Excel.decodeBytes(bytes);
        sheet = excel['Taul1'];
        print('✅ Template loaded successfully - using Taul1 sheet');
      } catch (e) {
        // If template doesn't exist, create a new Excel file with basic structure
        print('⚠️ Template not found, creating new Excel file');
        excel = Excel.createExcel();
        sheet = excel['Sheet1'];
      }
      
      // Fill basic information using YOUR EXACT CELL MAPPING
      // excelDate → C4
      sheet.cell(CellIndex.indexByString('C4')).value = TextCellValue(excelDate);
      print('✍️ Writing date "$excelDate" to C4');
      
      // excelSupervisor + excelShift → E4
      final combinedSupervisor = '$excelSupervisor $excelShift';
      sheet.cell(CellIndex.indexByString('E4')).value = TextCellValue(combinedSupervisor);
      print('✍️ Writing supervisor+shift "$combinedSupervisor" to E4');
      
      // Calculate manpower counts and insert the higher value into C5
      final pdfManpower = _calculatePDFManpowerCount(professionCards);
      final excelManpower = _calculateExcelManpowerCount(professionCards);
      final higherManpower = pdfManpower > excelManpower ? pdfManpower : excelManpower;
      
      sheet.cell(CellIndex.indexByString('C5')).value = IntCellValue(higherManpower);
      print('🔥 PDF Manpower: $pdfManpower, Excel Manpower: $excelManpower');
      print('✍️ Writing HIGHER manpower count "$higherManpower" to C5');
      
      // Comments: F5, F6, F7
      if (comments.isNotEmpty && comments[0].isNotEmpty) {
        sheet.cell(CellIndex.indexByString('F5')).value = TextCellValue(comments[0]);
        print('✍️ Writing comment 1 "${comments[0]}" to F5');
      }
      if (comments.length > 1 && comments[1].isNotEmpty) {
        sheet.cell(CellIndex.indexByString('F6')).value = TextCellValue(comments[1]);
        print('✍️ Writing comment 2 "${comments[1]}" to F6');
      }
      if (comments.length > 2 && comments[2].isNotEmpty) {
        sheet.cell(CellIndex.indexByString('F7')).value = TextCellValue(comments[2]);
        print('✍️ Writing comment 3 "${comments[2]}" to F7');
      }
      
      // Extra Work: F9, F10, F11
      if (extraWork.isNotEmpty && extraWork[0].isNotEmpty) {
        sheet.cell(CellIndex.indexByString('F9')).value = TextCellValue(extraWork[0]);
        print('✍️ Writing extra work 1 "${extraWork[0]}" to F9');
      }
      if (extraWork.length > 1 && extraWork[1].isNotEmpty) {
        sheet.cell(CellIndex.indexByString('F10')).value = TextCellValue(extraWork[1]);
        print('✍️ Writing extra work 2 "${extraWork[1]}" to F10');
      }
      if (extraWork.length > 2 && extraWork[2].isNotEmpty) {
        sheet.cell(CellIndex.indexByString('F11')).value = TextCellValue(extraWork[2]);
        print('✍️ Writing extra work 3 "${extraWork[2]}" to F11');
      }
      
      // Profession Cards using YOUR EXACT BASE ROWS
      final List<int> baseRows = [12, 21, 30, 39, 48, 57, 66, 75, 84, 93];
      
      for (int i = 0; i < professionCards.length && i < 10; i++) {
        final card = professionCards[i];
        final baseRow = baseRows[i];
        
        print('📝 Filling profession card ${i+1} at base row $baseRow: "${card.professionName}"');
        
        // Profession name → B{baseRow}
        if (card.professionName.isNotEmpty) {
          sheet.cell(CellIndex.indexByString('B$baseRow')).value = TextCellValue(card.professionName);
          print('✍️ Writing profession "${card.professionName}" to B$baseRow');
        }
        
        // Excel names → G{baseRow+3}, G{baseRow+4}
        if (card.excelName1.isNotEmpty) {
          sheet.cell(CellIndex.indexByString('G${baseRow + 3}')).value = TextCellValue(card.excelName1);
          print('✍️ Writing excel name 1 "${card.excelName1}" to G${baseRow + 3}');
        }
        if (card.excelName2.isNotEmpty) {
          sheet.cell(CellIndex.indexByString('G${baseRow + 4}')).value = TextCellValue(card.excelName2);
          print('✍️ Writing excel name 2 "${card.excelName2}" to G${baseRow + 4}');
        }
        
        // Equipment → G{baseRow+1}, H{baseRow+1}
        if (card.equipment.isNotEmpty) {
          sheet.cell(CellIndex.indexByString('G${baseRow + 1}')).value = TextCellValue(card.equipment);
          print('✍️ Writing equipment "${card.equipment}" to G${baseRow + 1}');
        }
        if (card.equipmentLocation.isNotEmpty) {
          sheet.cell(CellIndex.indexByString('H${baseRow + 1}')).value = TextCellValue(card.equipmentLocation);
          print('✍️ Writing equipment location "${card.equipmentLocation}" to H${baseRow + 1}');
        }
        
        // Tasks and Task Notices (up to 4 tasks per profession)
        for (int j = 0; j < card.tasks.length && j < 4; j++) {
          final task = card.tasks[j];
          
          // Tasks → B{baseRow + 1 + j}
          if (task.task.isNotEmpty) {
            sheet.cell(CellIndex.indexByString('B${baseRow + 1 + j}')).value = TextCellValue(task.task);
            print('✍️ Writing task "${task.task}" to B${baseRow + 1 + j}');
          }
          
          // Task notices → F{baseRow + 1 + j}
          if (task.taskNotice.isNotEmpty) {
            sheet.cell(CellIndex.indexByString('F${baseRow + 1 + j}')).value = TextCellValue(task.taskNotice);
            print('✍️ Writing task notice "${task.taskNotice}" to F${baseRow + 1 + j}');
          }
        }
      }
      
      // Save the Excel file
      await _saveExcelFile(excel, excelSupervisor, excelShift, excelDate);
      print('✅ Excel file saved successfully with YOUR EXACT CELL MAPPING');
      
    } catch (e) {
      print('❌ Excel export error: $e');
      throw Exception('Excel export failed: $e');
    }
  }
  
  /// Create basic Excel structure when template is not available
  static void _createBasicStructure(Sheet sheet) {
    // Headers for reference
    var cell1 = sheet.cell(CellIndex.indexByString('C3'));
    cell1.value = TextCellValue('Päivämäärä:');
    
    var cell2 = sheet.cell(CellIndex.indexByString('E3'));
    cell2.value = TextCellValue('TJ + Vuoro:');
    
    var cell3 = sheet.cell(CellIndex.indexByString('F4'));
    cell3.value = TextCellValue('Huomiot:');
    
    var cell4 = sheet.cell(CellIndex.indexByString('F8'));
    cell4.value = TextCellValue('Lisätyöt:');
    
    // Profession headers
    var cell5 = sheet.cell(CellIndex.indexByString('B11'));
    cell5.value = TextCellValue('Aselaji');
    
    var cell6 = sheet.cell(CellIndex.indexByString('G11'));
    cell6.value = TextCellValue('Asentajat');
    
    var cell7 = sheet.cell(CellIndex.indexByString('B10'));
    cell7.value = TextCellValue('Tehtävät');
  }
  
  /// Fill basic information cells
  static void _fillBasicInfo(Sheet sheet, String supervisor, String shift, String date) {
    // excelDate → C4
    var cell = sheet.cell(CellIndex.indexByString('C4'));
    cell.value = TextCellValue(date);
    print('✍️ Writing date "$date" to C4');
    
    // excelSupervisor + excelShift → E4 (combining them)
    var supervisorCell = sheet.cell(CellIndex.indexByString('E4'));
    final combinedValue = '$supervisor $shift';
    supervisorCell.value = TextCellValue(combinedValue);
    print('✍️ Writing supervisor+shift "$combinedValue" to E4');
  }
  
  /// Fill comments and extra work sections
  static void _fillCommentsAndExtraWork(Sheet sheet, List<String> comments, List<String> extraWork) {
    // Comments: F5, F6, F7
    if (comments.isNotEmpty && comments[0].isNotEmpty) {
      var cell = sheet.cell(CellIndex.indexByString('F5'));
      cell.value = TextCellValue(comments[0]);
      print('✍️ Writing comment 1 "${comments[0]}" to F5');
    }
    if (comments.length > 1 && comments[1].isNotEmpty) {
      var cell = sheet.cell(CellIndex.indexByString('F6'));
      cell.value = TextCellValue(comments[1]);
      print('✍️ Writing comment 2 "${comments[1]}" to F6');
    }
    if (comments.length > 2 && comments[2].isNotEmpty) {
      var cell = sheet.cell(CellIndex.indexByString('F7'));
      cell.value = TextCellValue(comments[2]);
      print('✍️ Writing comment 3 "${comments[2]}" to F7');
    }
    
    // Extra Work: F9, F10, F11
    if (extraWork.isNotEmpty && extraWork[0].isNotEmpty) {
      var cell = sheet.cell(CellIndex.indexByString('F9'));
      cell.value = TextCellValue(extraWork[0]);
      print('✍️ Writing extra work 1 "${extraWork[0]}" to F9');
    }
    if (extraWork.length > 1 && extraWork[1].isNotEmpty) {
      var cell = sheet.cell(CellIndex.indexByString('F10'));
      cell.value = TextCellValue(extraWork[1]);
      print('✍️ Writing extra work 2 "${extraWork[1]}" to F10');
    }
    if (extraWork.length > 2 && extraWork[2].isNotEmpty) {
      var cell = sheet.cell(CellIndex.indexByString('F11'));
      cell.value = TextCellValue(extraWork[2]);
      print('✍️ Writing extra work 3 "${extraWork[2]}" to F11');
    }
  }
  
  /// Fill profession cards data (up to 10 professions)
  static void _fillProfessionCards(Sheet sheet, List<ProfessionCardData> cards) {
    // Base rows for each profession (1-10)
    final List<int> baseRows = [12, 21, 30, 39, 48, 57, 66, 75, 84, 93];
    
    for (int i = 0; i < cards.length && i < 10; i++) {
      final card = cards[i];
      final baseRow = baseRows[i];
      
      _fillSingleProfessionCard(sheet, card, baseRow);
    }
  }
  
  /// Fill a single profession card at the specified base row
  static void _fillSingleProfessionCard(Sheet sheet, ProfessionCardData card, int baseRow) {
    print('📝 Filling profession card at row $baseRow: "${card.professionName}"');
    
    // Profession name → B{baseRow}
    if (card.professionName.isNotEmpty) {
      var cell = sheet.cell(CellIndex.indexByString('B$baseRow'));
      cell.value = TextCellValue(card.professionName);
      print('✍️ Writing profession "${card.professionName}" to B$baseRow');
    }
    
    // Excel names (use ONLY Excel names, not PDF names)
    if (card.excelName1.isNotEmpty) {
      var cell = sheet.cell(CellIndex.indexByString('G${baseRow + 3}'));
      cell.value = TextCellValue(card.excelName1);
      print('✍️ Writing excel name 1 "${card.excelName1}" to G${baseRow + 3}');
    }
    if (card.excelName2.isNotEmpty) {
      var cell = sheet.cell(CellIndex.indexByString('G${baseRow + 4}'));
      cell.value = TextCellValue(card.excelName2);
      print('✍️ Writing excel name 2 "${card.excelName2}" to G${baseRow + 4}');
    }
    
    // Equipment
    if (card.equipment.isNotEmpty) {
      var cell = sheet.cell(CellIndex.indexByString('G${baseRow + 1}'));
      cell.value = TextCellValue(card.equipment);
      print('✍️ Writing equipment "${card.equipment}" to G${baseRow + 1}');
    }
    if (card.equipmentLocation.isNotEmpty) {
      var cell = sheet.cell(CellIndex.indexByString('H${baseRow + 1}'));
      cell.value = TextCellValue(card.equipmentLocation);
      print('✍️ Writing equipment location "${card.equipmentLocation}" to H${baseRow + 1}');
    }
    
    // Tasks
    for (int j = 0; j < card.tasks.length; j++) {
      final task = card.tasks[j];
      if (task.task.isNotEmpty) {
        sheet.cell(CellIndex.indexByString('B${baseRow + 1 + j}')).value = TextCellValue(task.task);
        print('✍️ Writing task "${task.task}" to B${baseRow + 1 + j}');
      }
      
      if (task.taskNotice.isNotEmpty) {
        sheet.cell(CellIndex.indexByString('F${baseRow + 1 + j}')).value = TextCellValue(task.taskNotice);
        print('✍️ Writing task notice "${task.taskNotice}" to F${baseRow + 1 + j}');
      }
    }
  }
  
  /// Save Excel file with platform-specific approach
  static Future<void> _saveExcelFile(Excel excel, String supervisor, String shift, String date) async {
    // Create filename
    final sanitizedDate = date.replaceAll('.', '-').replaceAll('/', '-');
    final sanitizedSupervisor = supervisor.replaceAll(' ', '_');
    final sanitizedShift = shift.replaceAll(' ', '_');
    
    final filename = 'Vuoronvaihtopäiväkirja_${sanitizedSupervisor}_${sanitizedShift}_$sanitizedDate.xlsx';
    
    // Encode Excel file
    final List<int>? fileBytes = excel.encode();
    if (fileBytes == null) {
      throw Exception('Failed to encode Excel file');
    }
    
    // Platform-specific saving
    if (kIsWeb) {
      // 🌐 WEB: Download file via browser
      await _downloadFileWeb(fileBytes, filename);
    } else if (Platform.isAndroid || Platform.isIOS) {
      // 📱 MOBILE: Share file
      await _shareFileMobile(fileBytes, filename);
    } else {
      // 🖥️ DESKTOP: Save to file system
      await _saveFileDesktop(fileBytes, filename);
    }
  }
  
  /// Download file on web platforms
  static Future<void> _downloadFileWeb(List<int> fileBytes, String filename) async {
    final blob = html.Blob([fileBytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    
    html.Url.revokeObjectUrl(url);
  }
  
  /// Share file on mobile platforms
  static Future<void> _shareFileMobile(List<int> fileBytes, String filename) async {
    // Create temporary file for sharing
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/$filename';
    
    final file = File(filePath);
    await file.writeAsBytes(fileBytes);
    
    // Share the file
    await Share.shareXFiles([XFile(filePath)], text: 'Vuoronvaihtopäiväkirja');
  }
  
  /// Save file on desktop platforms
  static Future<void> _saveFileDesktop(List<int> fileBytes, String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$filename';
    
    final file = File(filePath);
    await file.writeAsBytes(fileBytes);
    
    // Open the file automatically
    await OpenFile.open(filePath);
  }
  
  /// Create a template Excel file (for development/testing)
  static Future<void> createTemplate() async {
    var excel = Excel.createExcel();
    var sheet = excel['Sheet1'];
    
    // Add headers for reference (this would be your pre-made template)
    var cell1 = sheet.cell(CellIndex.indexByString('C4'));
    cell1.value = TextCellValue('Date');
    
    var cell2 = sheet.cell(CellIndex.indexByString('E4'));
    cell2.value = TextCellValue('Supervisor + Shift');
    
    // Comments section
    var cell3 = sheet.cell(CellIndex.indexByString('F5'));
    cell3.value = TextCellValue('Comment 1');
    
    var cell4 = sheet.cell(CellIndex.indexByString('F6'));
    cell4.value = TextCellValue('Comment 2');
    
    var cell5 = sheet.cell(CellIndex.indexByString('F7'));
    cell5.value = TextCellValue('Comment 3');
    
    // Extra work section
    var cell6 = sheet.cell(CellIndex.indexByString('F9'));
    cell6.value = TextCellValue('Extra Work 1');
    
    var cell7 = sheet.cell(CellIndex.indexByString('F10'));
    cell7.value = TextCellValue('Extra Work 2');
    
    var cell8 = sheet.cell(CellIndex.indexByString('F11'));
    cell8.value = TextCellValue('Extra Work 3');
    
    // Save template
    final directory = await getApplicationDocumentsDirectory();
    final templatePath = '${directory.path}/excel_template.xlsx';
    final file = File(templatePath);
    await file.writeAsBytes(excel.encode()!);
  }
  
  /// Log data summary for debugging
  static void _logDataSummary(String supervisor, String shift, String date, 
                             List<String> comments, List<String> extraWork, 
                             List<ProfessionCardData> cards) {
    print('\n📊 EXCEL EXPORT DATA SUMMARY:');
    print('Supervisor: "$supervisor"');
    print('Shift: "$shift"');
    print('Date: "$date"');
    print('Comments: ${comments.where((c) => c.isNotEmpty).length}/3 filled');
    print('Extra Work: ${extraWork.where((e) => e.isNotEmpty).length}/3 filled');
    print('Profession Cards: ${cards.length}');
    
    for (int i = 0; i < cards.length; i++) {
      final card = cards[i];
      final taskCount = card.tasks.where((t) => t.task.isNotEmpty || t.taskNotice.isNotEmpty).length;
      print('  Card ${i+1}: "${card.professionName}" | Names: "${card.excelName1}" + "${card.excelName2}" | Equipment: "${card.equipment}" @ "${card.equipmentLocation}" | Tasks: $taskCount');
    }
    print('📊 END DATA SUMMARY\n');
  }
  
  /// Calculate PDF manpower count
  static int _calculatePDFManpowerCount(List<ProfessionCardData> cards) {
    int count = 0;
    for (final card in cards) {
      if (card.pdfName1.isNotEmpty) count++;
      if (card.pdfName2.isNotEmpty) count++;
    }
    return count;
  }
  
  /// Calculate Excel manpower count
  static int _calculateExcelManpowerCount(List<ProfessionCardData> cards) {
    int count = 0;
    for (final card in cards) {
      if (card.excelName1.isNotEmpty) count++;
      if (card.excelName2.isNotEmpty) count++;
    }
    return count;
  }
} 
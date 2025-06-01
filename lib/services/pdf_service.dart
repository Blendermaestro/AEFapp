import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../screens/work_card_screen.dart';
import 'package:open_file/open_file.dart';

class PdfService {
  /// Export work card data to PDF using the template
  static Future<void> exportToPdf({
    required String pdfSupervisor,
    required String pdfShift,
    required String pdfDate,
    required String globalNotice,
    required List<ProfessionCardData> professionCards,
  }) async {
    try {
      // Get all PDF names to generate individual PDFs
      final List<Map<String, dynamic>> allPdfNames = _getAllPdfNamesWithCards(professionCards);
      
      print('📊 PDF EXPORT SUMMARY:');
      print('Supervisor: "$pdfSupervisor"');
      print('Shift: "$pdfShift"');
      print('Date: "$pdfDate"');
      print('Global Notice: "$globalNotice"');
      print('Total PDF names: ${allPdfNames.length}');
      
      if (allPdfNames.isEmpty) {
        throw Exception('No PDF names found - add some workers first!');
      }
      
      // Generate individual PDFs for each worker
      final List<Uint8List> individualPdfs = [];
      for (int i = 0; i < allPdfNames.length; i++) {
        final workerName = allPdfNames[i]['name'];
        final card = allPdfNames[i]['card'];
        print('📄 Generating PDF ${i + 1}/${allPdfNames.length} for: "$workerName" from card "${card.professionName}"');
        
        final pdfBytes = await _generateSingleWorkerPdf(
          workerName: workerName,
          supervisor: pdfSupervisor,
          shift: pdfShift,
          date: pdfDate,
          globalNotice: globalNotice,
          workerCard: card,
        );
        
        individualPdfs.add(pdfBytes);
      }
      
      // Merge all individual PDFs into one final document
      final mergedPdf = await _mergeAllPdfs(individualPdfs);
      await _savePdfFile(mergedPdf, pdfSupervisor, pdfShift, pdfDate);
      
      print('✅ PDF export completed successfully! Generated ${individualPdfs.length} worker PDFs and merged them.');
      
    } catch (e) {
      print('❌ PDF export error: $e');
      throw Exception('PDF export failed: $e');
    }
  }
  
  /// Get all PDF names from profession cards with their associated card data
  static List<Map<String, dynamic>> _getAllPdfNamesWithCards(List<ProfessionCardData> cards) {
    final List<Map<String, dynamic>> namesWithCards = [];
    
    for (final card in cards) {
      // Add name_1 if it exists
      if (card.pdfName1.isNotEmpty) {
        namesWithCards.add({
          'name': card.pdfName1,
          'card': card,
        });
      }
      // Add name_2 if it exists  
      if (card.pdfName2.isNotEmpty) {
        namesWithCards.add({
          'name': card.pdfName2,
          'card': card,
        });
      }
    }
    
    return namesWithCards;
  }
  
  /// Generate a single PDF for one worker using SYNCFUSION with REAL TEMPLATE
  static Future<Uint8List> _generateSingleWorkerPdf({
    required String workerName,
    required String supervisor,
    required String shift,
    required String date,
    required String globalNotice,
    required ProfessionCardData workerCard,
  }) async {
    try {
      // Method 1: Try to create PDF with template using Syncfusion
      return await _createPdfWithSyncfusionTemplate(
        workerName: workerName,
        supervisor: supervisor,
        shift: shift,
        date: date,
        globalNotice: globalNotice,
        workerCard: workerCard,
      );
    } catch (e) {
      print('⚠️ Syncfusion template failed: $e');
      // Fallback: Create PDF without template background
      return await _createPdfWithoutTemplate(
        workerName: workerName,
        supervisor: supervisor,
        shift: shift,
        date: date,
        globalNotice: globalNotice,
        workerCard: workerCard,
      );
    }
  }
  
  /// Create PDF with actual template using Syncfusion (REAL TEMPLATE IMPORT)
  static Future<Uint8List> _createPdfWithSyncfusionTemplate({
    required String workerName,
    required String supervisor,
    required String shift,
    required String date,
    required String globalNotice,
    required ProfessionCardData workerCard,
  }) async {
    // Load template PDF bytes
    final ByteData templateData = await rootBundle.load('assets/template_workcard_blank.pdf');
    final Uint8List templateBytes = templateData.buffer.asUint8List();
    print('✅ Template PDF loaded (${templateBytes.length} bytes)');
    
    // Load existing PDF template using Syncfusion
    final PdfDocument templateDocument = PdfDocument(inputBytes: templateBytes);
    print('📄 Template loaded with ${templateDocument.pages.count} pages');
    
    if (templateDocument.pages.count == 0) {
      throw Exception('Template PDF has no pages');
    }
    
    // Create new document that will maintain LANDSCAPE orientation
    final PdfDocument newDocument = PdfDocument();
    
    // FORCE LANDSCAPE ORIENTATION BEFORE ADDING PAGES
    newDocument.pageSettings.orientation = PdfPageOrientation.landscape;
    newDocument.pageSettings.margins.all = 0;
    
    // Process all pages from template
    for (int pageIndex = 0; pageIndex < templateDocument.pages.count; pageIndex++) {
      final PdfPage templatePage = templateDocument.pages[pageIndex];
      print('📏 Template page ${pageIndex + 1} size: ${templatePage.size.width} x ${templatePage.size.height}');
      
      // Create template from the current page
      final PdfTemplate template = templatePage.createTemplate();
      
      // Add new page to our document (will inherit landscape orientation)
      final PdfPage newPage = newDocument.pages.add();
      
      // Get graphics context
      final PdfGraphics graphics = newPage.graphics;
      
      // Draw the template as background FIRST - maintain template's actual size
      graphics.drawPdfTemplate(template, const Offset(0, 0), template.size);
      
      // ONLY ADD DATA TO THE FIRST PAGE (pageIndex == 0)
      if (pageIndex == 0) {
        print('📋 Adding data to page 1 for worker: "$workerName" using work card: "${workerCard.professionName}"');
        
        // Create font for text overlay
        final PdfFont fontSmall = PdfStandardFont(PdfFontFamily.helvetica, 7);
        final PdfFont fontNormal = PdfStandardFont(PdfFontFamily.helvetica, 8);
        final PdfFont fontMedium = PdfStandardFont(PdfFontFamily.helvetica, 10);
        final PdfFont fontLarge = PdfStandardFont(PdfFontFamily.helvetica, 18);
        
        final PdfBrush blackBrush = PdfSolidBrush(PdfColor(0, 0, 0)); // Black text
        final PdfBrush blueBrush = PdfSolidBrush(PdfColor(0, 0, 255)); // Blue text

        // USER'S EXACT FIELD COORDINATES AND STYLING (ONLY ON FIRST PAGE)
        
        // Date fields
        _drawTextAt(graphics, fontMedium, blackBrush, date, x: 150, y: 83);  // date_1
        _drawTextAt(graphics, fontMedium, blackBrush, date, x: 493, y: 100); // date_2
        
        // Supervisor fields
        _drawTextAt(graphics, fontNormal, blackBrush, supervisor, x: 314, y: 43);  // supervisor_1 (size=8)
        _drawTextAt(graphics, fontMedium, blackBrush, supervisor, x: 687, y: 116); // supervisor_2 (size=10)
        
        // Shift fields
        _drawTextAt(graphics, fontMedium, blackBrush, shift, x: 205, y: 83);  // shift_1
        _drawTextAt(graphics, fontMedium, blackBrush, shift, x: 687, y: 101); // shift_2
        
        // Profession fields (FROM THE SPECIFIC WORK CARD) - size=18
        final profession = workerCard.professionName ?? '';
        print('🏗️ Drawing profession: "$profession" for worker: "$workerName"');
        _drawTextAt(graphics, fontLarge, blackBrush, profession, x: 22, y: 40);   // profession_1
        _drawTextAt(graphics, fontLarge, blackBrush, profession, x: 577, y: 59);  // profession_2
        
        // Name fields - this worker's name
        _drawTextAt(graphics, fontMedium, blackBrush, workerName, x: 50, y: 81);   // name_1
        _drawTextAt(graphics, fontMedium, blackBrush, workerName, x: 493, y: 115); // name_2
        
        // Equipment fields (FROM THE SPECIFIC WORK CARD) - BLUE COLOR - COMBINED
        final combinedEquipment = _combineEquipmentWithLocation(workerCard.equipment, workerCard.equipmentLocation);
        _drawTextAt(graphics, fontSmall, blueBrush, combinedEquipment, x: 495, y: 131); // equipment - equipmentLocation (size=7, blue)
        
        // Global notice
        _drawTextAt(graphics, fontMedium, blackBrush, globalNotice, x: 469, y: 280); // globalNotice
        
        // Task fields (up to 4 tasks) - COMBINE task and task note with "-" separator
        final task1 = _combineTaskWithNote(workerCard.tasks, 0);
        final task2 = _combineTaskWithNote(workerCard.tasks, 1);
        final task3 = _combineTaskWithNote(workerCard.tasks, 2);
        final task4 = _combineTaskWithNote(workerCard.tasks, 3);
        
        _drawTextAt(graphics, fontNormal, blackBrush, task1, x: 469, y: 218); // task_1 with note
        _drawTextAt(graphics, fontNormal, blackBrush, task2, x: 469, y: 234); // task_2 with note
        _drawTextAt(graphics, fontNormal, blackBrush, task3, x: 469, y: 250); // task_3 with note
        _drawTextAt(graphics, fontNormal, blackBrush, task4, x: 469, y: 265); // task_4 with note
      } else {
        // For pages 2+ just use the template as-is (no data overlay)
        print('📋 Page ${pageIndex + 1}: Using template as-is (no data overlay)');
      }
    }
    
    // Save the new document with template background
    final List<int> pdfBytes = await newDocument.save();
    templateDocument.dispose();
    newDocument.dispose();
    
    print('✅ PDF created for worker "$workerName" using work card "${workerCard.professionName}" - LANDSCAPE FORCED');
    return Uint8List.fromList(pdfBytes);
  }
  
  /// Helper method to combine equipment and equipment location with "-" separator
  static String _combineEquipmentWithLocation(String? equipment, String? equipmentLocation) {
    final equipmentText = equipment ?? '';
    final locationText = equipmentLocation ?? '';
    
    if (equipmentText.isEmpty && locationText.isEmpty) {
      return '';
    } else if (equipmentText.isEmpty) {
      return locationText;
    } else if (locationText.isEmpty) {
      return equipmentText;
    } else {
      return '$equipmentText - $locationText';
    }
  }
  
  /// Helper method to combine task and task note with "-" separator
  static String _combineTaskWithNote(List<TaskData>? tasks, int index) {
    if (tasks == null || tasks.length <= index) {
      return '';
    }
    
    final task = tasks[index];
    final taskText = task.task ?? '';
    final taskNote = task.taskNotice ?? '';
    
    if (taskText.isEmpty && taskNote.isEmpty) {
      return '';
    } else if (taskText.isEmpty) {
      return taskNote;
    } else if (taskNote.isEmpty) {
      return taskText;
    } else {
      return '$taskText - $taskNote';
    }
  }
  
  /// Helper method to draw text at specific coordinates
  static void _drawTextAt(PdfGraphics graphics, PdfFont font, PdfBrush brush, String text, {
    required double x,
    required double y,
  }) {
    if (text.isEmpty) {
      print('⚠️ Skipping empty text at ($x, $y)');
      return;
    }
    
    // Calculate appropriate bounds based on font size
    final double fontSize = font.size;
    final double width = text.length * fontSize * 0.6; // Rough estimate
    final double height = fontSize * 1.5; // 1.5x font size for proper height
    
    print('📝 Drawing text "$text" at ($x, $y) with font size $fontSize, bounds: ${width}x$height');
    
    graphics.drawString(
      text,
      font,
      brush: brush,
      bounds: Rect.fromLTWH(x, y, width.clamp(100, 500), height.clamp(15, 50)),
    );
  }
  
  /// Merge all individual PDFs into one final document
  static Future<Uint8List> _mergeAllPdfs(List<Uint8List> individualPdfs) async {
    if (individualPdfs.isEmpty) {
      throw Exception('No PDFs to merge');
    }
    
    if (individualPdfs.length == 1) {
      print('📄 Only one PDF, no merging needed');
      return individualPdfs[0];
    }
    
    // CRITICAL FIX: Create new document with FORCED LANDSCAPE orientation
    final PdfDocument mergedDocument = PdfDocument();
    mergedDocument.pageSettings.orientation = PdfPageOrientation.landscape;
    mergedDocument.pageSettings.margins.all = 0;
    
    print('🔗 Merging ${individualPdfs.length} PDFs with ROTATION FIX...');
    
    // Load template once to get the correct size
    final ByteData templateData = await rootBundle.load('assets/template_workcard_blank.pdf');
    final Uint8List templateBytes = templateData.buffer.asUint8List();
    final PdfDocument templateDoc = PdfDocument(inputBytes: templateBytes);
    final Size templateSize = templateDoc.pages[0].size;
    templateDoc.dispose();
    
    // Process each individual PDF with proper rotation handling
    for (int i = 0; i < individualPdfs.length; i++) {
      try {
        final PdfDocument sourceDocument = PdfDocument(inputBytes: individualPdfs[i]);
        
        // Process each page in the source document
        for (int pageIndex = 0; pageIndex < sourceDocument.pages.count; pageIndex++) {
          final PdfPage sourcePage = sourceDocument.pages[pageIndex];
          
          // Add new page to merged document (inherits landscape orientation)
          final PdfPage newPage = mergedDocument.pages.add();
          final PdfGraphics graphics = newPage.graphics;
          
          // Create template from source page
          final PdfTemplate template = sourcePage.createTemplate();
          
          print('📏 Source page size: ${sourcePage.size.width} x ${sourcePage.size.height}');
          print('📏 Template size: ${template.size.width} x ${template.size.height}');
          print('📏 New page size: ${newPage.size.width} x ${newPage.size.height}');
          
          // CRITICAL FIX: Detect if template is wrongly oriented
          final bool needsRotation = template.size.width < template.size.height;
          
          if (needsRotation) {
            print('🔄 Applying rotation fix for PDF ${i + 1}, page ${pageIndex + 1}');
            
            // Save graphics state
            graphics.save();
            
            // Apply rotation transformation to fix orientation
            // Move to top-right corner and rotate 90 degrees
            graphics.translateTransform(newPage.size.width, 0);
            graphics.rotateTransform(90);
            
            // Draw template with swapped dimensions
            graphics.drawPdfTemplate(
              template, 
              const Offset(0, 0),
              Size(template.size.height, template.size.width)
            );
            
            // Restore graphics state
            graphics.restore();
          } else {
            // Template is already correct orientation
            print('✅ Template already landscape for PDF ${i + 1}, page ${pageIndex + 1}');
            graphics.drawPdfTemplate(template, const Offset(0, 0), template.size);
          }
        }
        
        sourceDocument.dispose();
        print('📄 Successfully merged PDF ${i + 1}/${individualPdfs.length}');
      } catch (e) {
        print('⚠️ Failed to merge PDF ${i + 1}: $e');
        rethrow;
      }
    }
    
    // Save merged document
    final List<int> mergedBytes = await mergedDocument.save();
    mergedDocument.dispose();
    
    print('✅ Successfully merged ${individualPdfs.length} PDFs with PROPER LANDSCAPE ORIENTATION');
    return Uint8List.fromList(mergedBytes);
  }
  
  /// Create PDF without template (fallback)
  static Future<Uint8List> _createPdfWithoutTemplate({
    required String workerName,
    required String supervisor,
    required String shift,
    required String date,
    required String globalNotice,
    required ProfessionCardData workerCard,
  }) async {
    // Create new PDF document
    final PdfDocument document = PdfDocument();
    
    // Add page
    final PdfPage page = document.pages.add();
    final PdfGraphics graphics = page.graphics;
    
    // Create font and brush
    final PdfFont font = PdfStandardFont(PdfFontFamily.helvetica, 10);
    final PdfBrush textBrush = PdfSolidBrush(PdfColor(0, 0, 0));
    
    // Add fallback message
    graphics.drawString(
      'FALLBACK MODE - NO TEMPLATE\nWORKER: $workerName',
      font,
      brush: PdfSolidBrush(PdfColor(255, 0, 0)), // Red text
      bounds: const Rect.fromLTWH(20, 20, 300, 40),
    );
    
    // Draw all data fields FROM THE SPECIFIC WORK CARD
    double y = 100;
    graphics.drawString('Date: $date', font, brush: textBrush, bounds: Rect.fromLTWH(20, y, 200, 20));
    y += 25;
    graphics.drawString('Supervisor: $supervisor', font, brush: textBrush, bounds: Rect.fromLTWH(20, y, 200, 20));
    y += 25;
    graphics.drawString('Shift: $shift', font, brush: textBrush, bounds: Rect.fromLTWH(20, y, 200, 20));
    y += 25;
    graphics.drawString('Worker: $workerName', font, brush: textBrush, bounds: Rect.fromLTWH(20, y, 200, 20));
    y += 25;
    graphics.drawString('Profession: ${workerCard.professionName ?? ""}', font, brush: textBrush, bounds: Rect.fromLTWH(20, y, 200, 20));
    y += 25;
    graphics.drawString('Equipment: ${workerCard.equipment ?? ""}', font, brush: textBrush, bounds: Rect.fromLTWH(20, y, 200, 20));
    y += 25;
    graphics.drawString('Global Notice: $globalNotice', font, brush: textBrush, bounds: Rect.fromLTWH(20, y, 300, 20));
    
    // Save PDF
    final List<int> pdfBytes = await document.save();
    document.dispose();
    
    print('✅ PDF without template created (fallback mode)');
    return Uint8List.fromList(pdfBytes);
  }
  
  /// Save PDF file with platform-specific approach
  static Future<void> _savePdfFile(Uint8List pdfBytes, String supervisor, String shift, String date) async {
    // Create filename: "Työkortti_Supervisorpdf_pdfshift_pdfdate.pdf"
    final sanitizedDate = date.replaceAll('.', '-').replaceAll('/', '-');
    final sanitizedSupervisor = supervisor.replaceAll(' ', '_');
    final sanitizedShift = shift.replaceAll(' ', '_');
    
    final filename = 'Työkortti_${sanitizedSupervisor}_${sanitizedShift}_$sanitizedDate.pdf';
    
    // Platform-specific saving (same as Excel)
    if (kIsWeb) {
      // 🌐 WEB: Download file via browser
      await _downloadFileWeb(pdfBytes, filename);
    } else if (Platform.isAndroid || Platform.isIOS) {
      // 📱 MOBILE: Share file
      await _shareFileMobile(pdfBytes, filename);
    } else {
      // 🖥️ DESKTOP: Save to file system
      await _saveFileDesktop(pdfBytes, filename);
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
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/$filename';
    
    final file = File(filePath);
    await file.writeAsBytes(fileBytes);
    
    await Share.shareXFiles([XFile(filePath)], text: 'Työkortti');
  }
  
  /// Save file on desktop platforms
  static Future<void> _saveFileDesktop(List<int> fileBytes, String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$filename';
    
    final file = File(filePath);
    await file.writeAsBytes(fileBytes);
    
    print('📁 PDF saved to: $filePath');
    
    // Automatically open the PDF file on desktop
    try {
      await OpenFile.open(filePath);
      print('✅ PDF opened automatically');
    } catch (e) {
      print('⚠️ Could not open PDF automatically: $e');
    }
  }
} 
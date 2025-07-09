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
    required List<String> shiftNotes,
    int pdfTabIndex = 0, // NEW - to specify which PDF tab (0=PDF, 1=PDF2, 2=PDF3)
    bool includeSuojapaikat = false, // NEW - to choose template with Suojapaikat
  }) async {
    try {
      // Get all PDF names to generate individual PDFs
      final List<Map<String, dynamic>> allPdfNames = _getAllPdfNamesWithCards(professionCards, pdfTabIndex);
      
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
          includeSuojapaikat: includeSuojapaikat,
        );
        
        individualPdfs.add(pdfBytes);
      }
      
      // Merge all individual PDFs into one final document
      final mergedPdf = await _mergeAllPdfs(individualPdfs);
      
      // Save work cards only (no summary)
      await _savePdfFile(mergedPdf, pdfSupervisor, pdfShift, pdfDate);
      
      print('✅ PDF export completed successfully! Generated ${individualPdfs.length} worker PDFs and merged them.');
      
    } catch (e) {
      print('❌ PDF export error: $e');
      throw Exception('PDF export failed: $e');
    }
  }

  /// Export only the summary page as a separate PDF
  static Future<void> exportSummaryOnly({
    required String supervisor,
    required String shift,
    required String date,
    required List<ProfessionCardData> professionCards,
    required List<String> shiftNotes,
    int pdfTabIndex = 0, // NEW - to specify which PDF tab names to use in summary
  }) async {
    try {
      print('📄 Exporting summary only...');
      
      // Generate summary page
      final summaryPdf = await _generateSummaryPage(
        supervisor: supervisor,
        shift: shift,
        date: date,
        globalNotice: '', // Not needed for summary
        professionCards: professionCards,
        shiftNotes: shiftNotes,
        pdfTabIndex: pdfTabIndex,
      );
      
      // Save with specific naming: Yhteenveto_supervisor_shift_date.pdf
      await _saveSummaryPdfFile(summaryPdf, supervisor, shift, date);
      
      print('✅ Summary PDF export completed successfully!');
      
    } catch (e) {
      print('❌ Summary PDF export error: $e');
      throw Exception('Summary PDF export failed: $e');
    }
  }
  
  /// Get all PDF names from profession cards with their associated card data
  static List<Map<String, dynamic>> _getAllPdfNamesWithCards(List<ProfessionCardData> cards, int tabIndex) {
    final List<Map<String, dynamic>> namesWithCards = [];
    
    for (final card in cards) {
      String name1, name2;
      
      // Get the correct names based on tab index
      switch (tabIndex) {
        case 0: // PDF tab
          name1 = card.pdfName1;
          name2 = card.pdfName2;
          break;
        case 1: // PDF2 tab
          name1 = card.pdf2Name1;
          name2 = card.pdf2Name2;
          break;
        case 2: // PDF3 tab
          name1 = card.pdf3Name1;
          name2 = card.pdf3Name2;
          break;
        default:
          name1 = card.pdfName1;
          name2 = card.pdfName2;
          break;
      }
      
      // Add name_1 if it exists
      if (name1.isNotEmpty) {
        namesWithCards.add({
          'name': name1,
          'card': card,
        });
      }
      // Add name_2 if it exists  
      if (name2.isNotEmpty) {
        namesWithCards.add({
          'name': name2,
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
    bool includeSuojapaikat = false,
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
        includeSuojapaikat: includeSuojapaikat,
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
        includeSuojapaikat: includeSuojapaikat,
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
    bool includeSuojapaikat = false,
  }) async {
    // Choose correct template based on checkbox
    final String templatePath = includeSuojapaikat 
        ? 'assets/template_workcard_blank_SP.pdf'
        : 'assets/template_workcard_blank.pdf';
    
    // Load template PDF bytes
    final ByteData templateData = await rootBundle.load(templatePath);
    final Uint8List templateBytes = templateData.buffer.asUint8List();
    print('✅ Template PDF loaded from $templatePath (${templateBytes.length} bytes)');
    
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
        
        // Equipment fields removed - no longer drawing equipment and location
        
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
        
        // Work Site Conditions fields (up to 3 conditions) - NEW FEATURE
        final workSiteCondition1 = _getWorkSiteCondition(workerCard.workSiteConditions, 0);
        final workSiteCondition2 = _getWorkSiteCondition(workerCard.workSiteConditions, 1);
        final workSiteCondition3 = _getWorkSiteCondition(workerCard.workSiteConditions, 2);
        
        _drawTextAt(graphics, fontNormal, blackBrush, workSiteCondition1, x: 470, y: 310); // workSiteCondition_1
        _drawTextAt(graphics, fontNormal, blackBrush, workSiteCondition2, x: 470, y: 327); // workSiteCondition_2
        _drawTextAt(graphics, fontNormal, blackBrush, workSiteCondition3, x: 470, y: 342); // workSiteCondition_3
        
        // Supervisor Risk Notes fields (up to 3 notes) - NEW FEATURE
        final supervisorRiskNote1 = _getSupervisorRiskNote(workerCard.supervisorRiskNotes, 0);
        final supervisorRiskNote2 = _getSupervisorRiskNote(workerCard.supervisorRiskNotes, 1);
        final supervisorRiskNote3 = _getSupervisorRiskNote(workerCard.supervisorRiskNotes, 2);
        
        _drawTextAt(graphics, fontNormal, blackBrush, supervisorRiskNote1, x: 470, y: 373); // supervisorRiskNote_1
        _drawTextAt(graphics, fontNormal, blackBrush, supervisorRiskNote2, x: 470, y: 388); // supervisorRiskNote_2
        _drawTextAt(graphics, fontNormal, blackBrush, supervisorRiskNote3, x: 470, y: 404); // supervisorRiskNote_3
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
  
  /// Helper method to get work site condition at specific index
  static String _getWorkSiteCondition(List<String>? workSiteConditions, int index) {
    if (workSiteConditions == null || workSiteConditions.length <= index) {
      return '';
    }
    return workSiteConditions[index] ?? '';
  }
  
  /// Helper method to get supervisor risk note at specific index
  static String _getSupervisorRiskNote(List<String>? supervisorRiskNotes, int index) {
    if (supervisorRiskNotes == null || supervisorRiskNotes.length <= index) {
      return '';
    }
    return supervisorRiskNotes[index] ?? '';
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
    
    // Create new document with landscape orientation
    final PdfDocument mergedDocument = PdfDocument();
    mergedDocument.pageSettings.orientation = PdfPageOrientation.landscape;
    mergedDocument.pageSettings.margins.all = 0;
    
    print('🔗 Merging ${individualPdfs.length} PDFs...');
    
    // Process each individual PDF
    for (int i = 0; i < individualPdfs.length; i++) {
      try {
        final PdfDocument sourceDocument = PdfDocument(inputBytes: individualPdfs[i]);
        
        // Copy all pages from source to merged document
        for (int pageIndex = 0; pageIndex < sourceDocument.pages.count; pageIndex++) {
          final PdfPage sourcePage = sourceDocument.pages[pageIndex];
          final PdfPage newPage = mergedDocument.pages.add();
          final PdfTemplate template = sourcePage.createTemplate();
          
          // Draw template directly - no rotation needed since template is already landscape
          newPage.graphics.drawPdfTemplate(template, const Offset(0, 0), template.size);
        }
        
        sourceDocument.dispose();
      } catch (e) {
        print('⚠️ Failed to merge PDF ${i + 1}: $e');
        rethrow;
      }
    }
    
    // Save merged document
    final List<int> mergedBytes = await mergedDocument.save();
    mergedDocument.dispose();
    
    print('✅ Successfully merged ${individualPdfs.length} PDFs');
    return Uint8List.fromList(mergedBytes);
  }
  
  /// Generate A4 landscape summary page with 90-degree rotated text (portrait layout)
  static Future<Uint8List> _generateSummaryPage({
    required String supervisor,
    required String shift,
    required String date,
    required String globalNotice,
    required List<ProfessionCardData> professionCards,
    required List<String> shiftNotes,
    int pdfTabIndex = 0, // NEW - to specify which PDF tab names to use
  }) async {
    print('📄 Generating summary page...');
    
    // Create new PDF document with A4 PORTRAIT orientation
    final PdfDocument document = PdfDocument();
    document.pageSettings.orientation = PdfPageOrientation.portrait;
    document.pageSettings.size = PdfPageSize.a4;
    document.pageSettings.margins.all = 15; // Slightly more margins
    
    // Add page
    final PdfPage page = document.pages.add();
    PdfGraphics graphics = page.graphics;
    
    // Work directly in portrait coordinate system
    final double pageHeight = page.size.height - 30; // Available height 
    final double pageWidth = page.size.width - 30;  // Available width
    
    // Create fonts - all same size except title
    final PdfFont titleFont = PdfStandardFont(PdfFontFamily.helvetica, 16, style: PdfFontStyle.bold);
    final PdfFont professionFont = PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold);
    final PdfFont normalFont = PdfStandardFont(PdfFontFamily.helvetica, 10); // Headers and names use normal font
    final PdfFont smallFont = PdfStandardFont(PdfFontFamily.helvetica, 8);
    
    // Create brushes
    final PdfBrush blackBrush = PdfSolidBrush(PdfColor(0, 0, 0));
    final PdfBrush grayBrush = PdfSolidBrush(PdfColor(100, 100, 100));
    
    double yPosition = 0;
    
    // Draw professional grey header bar
    final PdfBrush headerBrush = PdfSolidBrush(PdfColor(220, 220, 220)); // Light grey
    graphics.drawRectangle(
      brush: headerBrush,
      bounds: Rect.fromLTWH(0, 0, page.size.width, 50),
    );
    
    // Add header title
    yPosition = 15;
    graphics.drawString(
      'Vuoronvaihto yhteenveto',
      titleFont,
      brush: blackBrush,
      bounds: Rect.fromLTWH(15, yPosition, pageWidth, 20),
    );
    

    
    yPosition = 60; // Start content after header
    
    // Calculate total manpower (PDF workers only - for the specific tab)
    int totalManpower = 0;
    for (final card in professionCards) {
      String name1, name2;
      
      // Get the correct names based on tab index
      switch (pdfTabIndex) {
        case 0: // PDF tab
          name1 = card.pdfName1;
          name2 = card.pdfName2;
          break;
        case 1: // PDF2 tab
          name1 = card.pdf2Name1;
          name2 = card.pdf2Name2;
          break;
        case 2: // PDF3 tab
          name1 = card.pdf3Name1;
          name2 = card.pdf3Name2;
          break;
        default:
          name1 = card.pdfName1;
          name2 = card.pdfName2;
          break;
      }
      
      if (name1.isNotEmpty) totalManpower++;
      if (name2.isNotEmpty) totalManpower++;
    }
    
    // Basic information
    graphics.drawString('Päivämäärä: $date', normalFont, brush: blackBrush, bounds: Rect.fromLTWH(15, yPosition, 200, 15));
    graphics.drawString('Työnjohtaja: $supervisor', normalFont, brush: blackBrush, bounds: Rect.fromLTWH(220, yPosition, 200, 15));
    yPosition += 17;
    graphics.drawString('Vuoro: $shift', normalFont, brush: blackBrush, bounds: Rect.fromLTWH(15, yPosition, 200, 15));
    graphics.drawString('Vahvuus: $totalManpower', normalFont, brush: blackBrush, bounds: Rect.fromLTWH(220, yPosition, 200, 15));
    yPosition += 22; // Better spacing
    
    // Shift Notes
    final activeShiftNotes = shiftNotes.where((note) => note.isNotEmpty).toList();
    if (activeShiftNotes.isNotEmpty) {
      graphics.drawString('Huomioita seuraavalle vuorolle:', normalFont, brush: blackBrush, bounds: Rect.fromLTWH(15, yPosition, pageWidth, 15));
      yPosition += 17;
      
      for (final note in activeShiftNotes) {
        graphics.drawString('• $note', normalFont, brush: blackBrush, bounds: Rect.fromLTWH(15, yPosition, pageWidth, 15));
        yPosition += 17;
      }
      yPosition += 18;
    }
    
    // Workers section
    graphics.drawString('Työntekijät:', normalFont, brush: blackBrush, bounds: Rect.fromLTWH(15, yPosition, pageWidth, 15));
    yPosition += 17;
    
    // Filter profession cards to only include those with names for this tab
    final includedCards = <ProfessionCardData>[];
    final excludedGroups = <String>[];
    
    for (final card in professionCards) {
      String name1, name2;
      switch (pdfTabIndex) {
        case 0: // PDF tab
          name1 = card.pdfName1;
          name2 = card.pdfName2;
          break;
        case 1: // PDF2 tab
          name1 = card.pdf2Name1;
          name2 = card.pdf2Name2;
          break;
        case 2: // PDF3 tab
          name1 = card.pdf3Name1;
          name2 = card.pdf3Name2;
          break;
        default:
          name1 = card.pdfName1;
          name2 = card.pdfName2;
          break;
      }
      
      if (name1.isNotEmpty || name2.isNotEmpty) {
        includedCards.add(card);
      } else {
        final groupName = card.professionName.isEmpty ? 'Nimetön' : card.professionName;
        excludedGroups.add(groupName);
      }
    }
    
    // Process only included cards
    for (final card in includedCards) {
      // Check if we need a new page
      if (yPosition > pageHeight - 100) { // Better threshold for portrait pages
        // Start new page
        final newPage = document.pages.add();
        graphics = newPage.graphics;
        yPosition = 15; // Consistent top padding for new pages
      }
      
      // Get the correct names for this tab
      String name1, name2;
      switch (pdfTabIndex) {
        case 0: // PDF tab
          name1 = card.pdfName1;
          name2 = card.pdfName2;
          break;
        case 1: // PDF2 tab
          name1 = card.pdf2Name1;
          name2 = card.pdf2Name2;
          break;
        case 2: // PDF3 tab
          name1 = card.pdf3Name1;
          name2 = card.pdf3Name2;
          break;
        default:
          name1 = card.pdfName1;
          name2 = card.pdfName2;
          break;
      }
      
      // PDF workers (the ones that actually appear in the work cards for this tab)
      final pdfWorkers = [name1, name2]
          .where((name) => name.isNotEmpty)
          .join(', ');
      
      // Bold profession name with normal workers names on the same line
      final professionText = card.professionName.isEmpty ? 'Määrittelemätön' : card.professionName;
      
      // Draw profession name in bold
      graphics.drawString(
        '• $professionText',
        professionFont, // Bold font for profession only
        brush: blackBrush,
        bounds: Rect.fromLTWH(15, yPosition, pageWidth, 15),
      );
      
      // Draw worker names in normal font if any
      if (pdfWorkers.isNotEmpty) {
        final professionWidth = professionFont.measureString('• $professionText').width;
        graphics.drawString(
          ': $pdfWorkers',
          normalFont, // Normal font for worker names
          brush: blackBrush,
          bounds: Rect.fromLTWH(15 + professionWidth, yPosition, pageWidth - professionWidth, 15),
        );
      }
      yPosition += 15;
      
      // Tasks section with header
      final activeTasks = card.tasks.where((task) => task.task.isNotEmpty).toList();
      if (activeTasks.isNotEmpty) {
        graphics.drawString(
          '    Tehtävät:',
          normalFont, // Same size as profession text, not bold
          brush: blackBrush,
          bounds: Rect.fromLTWH(15, yPosition, pageWidth, 15),
        );
        yPosition += 12;
        
        for (final task in activeTasks) {
          final taskText = task.taskNotice.isNotEmpty ? '${task.task} - ${task.taskNotice}' : task.task;
          graphics.drawString(
            '      - $taskText',
            smallFont,
            brush: grayBrush,
            bounds: Rect.fromLTWH(15, yPosition, pageWidth, 15),
          );
          yPosition += 11; // More spacing between tasks
        }
        yPosition += 3; // Extra space after tasks section
      }
      
      // Work Site Conditions section with header
      final activeWorkSiteConditions = card.workSiteConditions.where((condition) => condition.isNotEmpty).toList();
      if (activeWorkSiteConditions.isNotEmpty) {
        graphics.drawString(
          '    Työkohteen tämänhetkinen tila:',
          normalFont, // Same size as profession text, not bold
          brush: blackBrush,
          bounds: Rect.fromLTWH(15, yPosition, pageWidth, 15),
        );
        yPosition += 12;
        
        for (final condition in activeWorkSiteConditions) {
          graphics.drawString(
            '      - $condition',
            smallFont,
            brush: grayBrush,
            bounds: Rect.fromLTWH(15, yPosition, pageWidth, 15),
          );
          yPosition += 11;
        }
        yPosition += 3; // Extra space after section
      }
      
      // Supervisor Risk Notes section with header
      final activeSupervisorRiskNotes = card.supervisorRiskNotes.where((note) => note.isNotEmpty).toList();
      if (activeSupervisorRiskNotes.isNotEmpty) {
        graphics.drawString(
          '    Työnjohtajan huomiot riskeistä:',
          normalFont, // Same size as profession text, not bold
          brush: blackBrush,
          bounds: Rect.fromLTWH(15, yPosition, pageWidth, 15),
        );
        yPosition += 12;
        
        for (final note in activeSupervisorRiskNotes) {
          graphics.drawString(
            '      - $note',
            smallFont,
            brush: grayBrush,
            bounds: Rect.fromLTWH(15, yPosition, pageWidth, 15),
          );
          yPosition += 11;
        }
        yPosition += 3; // Extra space after section
      }
      
      yPosition += 12; // Better space between cards
    }
    
    // Add excluded groups notice if there are any
    if (excludedGroups.isNotEmpty) {
      // Check if we need a new page for the excluded groups notice
      if (yPosition > pageHeight - 50) {
        final newPage = document.pages.add();
        graphics = newPage.graphics;
        yPosition = 15;
      }
      
      yPosition += 20; // Extra space before the notice
      final excludedText = 'Näitä ryhmiä ei sisällytetty koska nimiä ei määritelty: ${excludedGroups.join(', ')}';
      
      graphics.drawString(
        excludedText,
        normalFont,
        brush: grayBrush,
        bounds: Rect.fromLTWH(15, yPosition, pageWidth, 15),
      );
    }
    
    // Save the document
    final List<int> pdfBytes = await document.save();
    document.dispose();
    
    print('✅ Summary page generated successfully in portrait orientation');
    return Uint8List.fromList(pdfBytes);
  }
  
  /// Get Excel names grouped by profession
  static Map<String, List<String>> _getExcelNamesByProfession(List<ProfessionCardData> professionCards) {
    final Map<String, List<String>> result = {};
    
    for (final card in professionCards) {
      final profession = card.professionName.isEmpty ? '' : card.professionName;
      
      if (!result.containsKey(profession)) {
        result[profession] = [];
      }
      
      if (card.excelName1.isNotEmpty) {
        result[profession]!.add(card.excelName1);
      }
      if (card.excelName2.isNotEmpty) {
        result[profession]!.add(card.excelName2);
      }
    }
    
    // Remove empty profession entries with no workers
    result.removeWhere((key, value) => value.isEmpty);
    
    return result;
  }
  
  /// Add summary page to the main document
  static Future<Uint8List> _addSummaryPageToDocument(Uint8List mainPdfBytes, Uint8List summaryPdfBytes) async {
    print('🔗 Adding summary page to main document...');
    
    // Load main document
    final PdfDocument mainDocument = PdfDocument(inputBytes: mainPdfBytes);
    
    // Load summary document
    final PdfDocument summaryDocument = PdfDocument(inputBytes: summaryPdfBytes);
    
    // Add all pages from summary to main document
    for (int i = 0; i < summaryDocument.pages.count; i++) {
      final PdfPage summaryPage = summaryDocument.pages[i];
      final PdfTemplate template = summaryPage.createTemplate();
      
      // Add new page to main document with LANDSCAPE orientation (same as work cards)
      final PdfPage newPage = mainDocument.pages.add();
      PdfGraphics graphics = newPage.graphics;
      graphics.drawPdfTemplate(template, const Offset(0, 0), template.size);
    }
    
    // Save combined document
    final List<int> finalBytes = await mainDocument.save();
    
    mainDocument.dispose();
    summaryDocument.dispose();
    
    print('✅ Summary page added to main document with LANDSCAPE orientation');
    return Uint8List.fromList(finalBytes);
  }
  
  /// Create PDF without template (fallback)
  static Future<Uint8List> _createPdfWithoutTemplate({
    required String workerName,
    required String supervisor,
    required String shift,
    required String date,
    required String globalNotice,
    required ProfessionCardData workerCard,
    bool includeSuojapaikat = false, // For consistency, though not used in fallback
  }) async {
    // Create new PDF document
    final PdfDocument document = PdfDocument();
    
    // Add page
    final PdfPage page = document.pages.add();
    PdfGraphics graphics = page.graphics;
    
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

  /// Save summary PDF file with specific naming
  static Future<void> _saveSummaryPdfFile(Uint8List pdfBytes, String supervisor, String shift, String date) async {
    // Create filename: "Yhteenveto_supervisor_shift_date.pdf"
    final sanitizedDate = date.replaceAll('.', '-').replaceAll('/', '-');
    final sanitizedSupervisor = supervisor.replaceAll(' ', '_');
    final sanitizedShift = shift.replaceAll(' ', '_');
    
    final filename = 'Yhteenveto_${sanitizedSupervisor}_${sanitizedShift}_$sanitizedDate.pdf';
    
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
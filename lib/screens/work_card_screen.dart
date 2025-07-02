import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/info_input_row.dart';
import '../widgets/global_notice_field.dart';
import '../widgets/profession_card.dart';
import '../widgets/excel_specific_fields.dart';
import '../screens/settings_screen.dart';
import '../services/supabase_service.dart';
import '../services/local_storage_service.dart';
import '../services/excel_service.dart';
import '../services/pdf_service.dart';

class WorkCardScreen extends StatefulWidget {
  final ValueChanged<bool> onThemeChanged;
  final VoidCallback onShowAuth;

  const WorkCardScreen({
    super.key, 
    required this.onThemeChanged,
    required this.onShowAuth,
  });

  @override
  State<WorkCardScreen> createState() => _WorkCardScreenState();
}

class _WorkCardScreenState extends State<WorkCardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Tab-specific data - SEPARATE FOR EACH PDF TAB
  String pdfSupervisor = '';
  String pdfDate = '';
  String pdfShift = '';
  
  String pdf2Supervisor = '';
  String pdf2Date = '';
  String pdf2Shift = '';
  
  String pdf3Supervisor = '';
  String pdf3Date = '';
  String pdf3Shift = '';
  
  String excelSupervisor = '';
  String excelDate = '';
  String excelShift = '';
  
  // Shared data - SAME ACROSS ALL TABS
  String globalNotice = '';
  List<ProfessionCardData> professionCards = [];
  
  // Excel-specific
  List<String> comments = [''];
  List<String> extraWork = [''];
  
  // Shift notes (for PDF summary only, not Excel) - SEPARATE FOR EACH PDF TAB
  List<String> shiftNotes = [''];
  List<String> shiftNotes2 = [''];
  List<String> shiftNotes3 = [''];
  List<TextEditingController> _shiftNoteControllers = [];
  List<TextEditingController> _shiftNoteControllers2 = [];
  List<TextEditingController> _shiftNoteControllers3 = [];
  
  // Add flag to prevent syncing during initial load
  bool _isInitialLoad = true;
  
  // Add debouncing for saves
  Timer? _saveDebounceTimer;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // CHANGED FROM 2 TO 4 TABS
    
    // Initialize shift note controllers for all PDF tabs
    _initializeShiftNoteControllers();
    
    // Load saved data
    _loadData().then((_) {
      // Mark initial load as complete
      _isInitialLoad = false;
    });
  }

  void _initializeShiftNoteControllers() {
    // Dispose existing controllers
    for (var controller in _shiftNoteControllers) {
      controller.dispose();
    }
    for (var controller in _shiftNoteControllers2) {
      controller.dispose();
    }
    for (var controller in _shiftNoteControllers3) {
      controller.dispose();
    }
    _shiftNoteControllers.clear();
    _shiftNoteControllers2.clear();
    _shiftNoteControllers3.clear();
    
    // Create controllers for current shift notes for all PDF tabs
    for (int i = 0; i < shiftNotes.length; i++) {
      _shiftNoteControllers.add(TextEditingController(text: shiftNotes[i]));
    }
    for (int i = 0; i < shiftNotes2.length; i++) {
      _shiftNoteControllers2.add(TextEditingController(text: shiftNotes2[i]));
    }
    for (int i = 0; i < shiftNotes3.length; i++) {
      _shiftNoteControllers3.add(TextEditingController(text: shiftNotes3[i]));
    }
  }

  Future<void> _loadData() async {
    print('=== LOADING DATA (CLOUD ONLY) ===');
    
    if (!SupabaseService.isLoggedIn) {
      print('Not logged in - redirecting to auth');
      widget.onShowAuth();
      return;
    }
    
    try {
      // Load from cloud
      final cloudCards = await SupabaseService.loadWorkCards();
      final cloudSettings = await SupabaseService.loadUserSettings();
      
      print('Loaded ${cloudCards.length} cards from cloud');
      print('Cloud cards: ${cloudCards.map((c) => c.professionName).toList()}');
      
      // Use cloud data if available, otherwise create defaults
      if (cloudCards.isNotEmpty) {
        professionCards = cloudCards;
        print('Set professionCards to cloud data, count: ${professionCards.length}');
      } else {
        print('No cloud data found - creating default cards');
        professionCards = [
          ProfessionCardData(professionName: 'Varu1'),
          ProfessionCardData(professionName: 'Varu2'),
          ProfessionCardData(professionName: 'Varu3'),
          ProfessionCardData(professionName: 'Varu4'),
          ProfessionCardData(professionName: 'Pasta1'),
          ProfessionCardData(professionName: 'Pasta2'),
          ProfessionCardData(professionName: 'Pora'),
          ProfessionCardData(professionName: 'Tarvikeauto'),
          ProfessionCardData(professionName: 'Huoltomies'),
        ];
        print('Created default cards, count: ${professionCards.length}');
        // Save the defaults to cloud immediately
        await SupabaseService.saveWorkCards(professionCards);
        print('Saved default cards to cloud');
      }
      
      // Load settings from cloud
      if (cloudSettings != null) {
        print('Loaded settings from cloud');
        pdfSupervisor = cloudSettings['pdf_supervisor'] ?? '';
        pdfDate = cloudSettings['pdf_date'] ?? '';
        pdfShift = cloudSettings['pdf_shift'] ?? '';
        
        // Load PDF2/PDF3 fields from cloud
        pdf2Supervisor = cloudSettings['pdf2_supervisor'] ?? '';
        pdf2Date = cloudSettings['pdf2_date'] ?? '';
        pdf2Shift = cloudSettings['pdf2_shift'] ?? '';
        
        pdf3Supervisor = cloudSettings['pdf3_supervisor'] ?? '';
        pdf3Date = cloudSettings['pdf3_date'] ?? '';
        pdf3Shift = cloudSettings['pdf3_shift'] ?? '';
        
        excelSupervisor = cloudSettings['excel_supervisor'] ?? '';
        excelDate = cloudSettings['excel_date'] ?? '';
        excelShift = cloudSettings['excel_shift'] ?? '';
        globalNotice = cloudSettings['global_notice'] ?? '';
        
        shiftNotes = List<String>.from(cloudSettings['shift_notes'] ?? ['']);
        // Load PDF2/PDF3 shift notes from cloud
        shiftNotes2 = List<String>.from(cloudSettings['shift_notes2'] ?? ['']);
        shiftNotes3 = List<String>.from(cloudSettings['shift_notes3'] ?? ['']);
        
        comments = List<String>.from(cloudSettings['comments'] ?? ['']);
        extraWork = List<String>.from(cloudSettings['extra_work'] ?? ['']);
      } else {
        // Initialize empty settings for first time users
        shiftNotes = [''];
        shiftNotes2 = [''];
        shiftNotes3 = [''];
        comments = [''];
        extraWork = [''];
      }
      
      // Reinitialize controllers after loading from cloud
      _initializeShiftNoteControllers();
      
      print('Final professionCards count: ${professionCards.length}');
      print('Final cards: ${professionCards.map((c) => c.professionName).toList()}');
      setState(() {});
      print('Successfully loaded from cloud');
    } catch (e) {
      print('Failed to load from cloud: $e');
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Virhe ladattaessa pilvipalvelusta: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // Auto-save methods - UPDATED FOR MULTIPLE PDF TABS
  void _saveSupervisor(String value, int tabIndex) {
    switch (tabIndex) {
      case 0: // PDF tab
        pdfSupervisor = value;
        break;
      case 1: // PDF2 tab
        pdf2Supervisor = value;
        break;
      case 2: // PDF3 tab
        pdf3Supervisor = value;
        break;
      case 3: // Excel tab
        excelSupervisor = value;
        break;
    }
    
    // Auto-save to cloud if not during initial load
    if (!_isInitialLoad) {
      _debouncedSyncToCloud();
    }
  }

  void _saveDate(String value, int tabIndex) {
    switch (tabIndex) {
      case 0: // PDF tab
        pdfDate = value;
        break;
      case 1: // PDF2 tab
        pdf2Date = value;
        break;
      case 2: // PDF3 tab
        pdf3Date = value;
        break;
      case 3: // Excel tab
        excelDate = value;
        break;
    }
    
    // Auto-save to cloud if not during initial load
    if (!_isInitialLoad) {
      _debouncedSyncToCloud();
    }
  }

  void _saveShift(String value, int tabIndex) {
    switch (tabIndex) {
      case 0: // PDF tab
        pdfShift = value;
        break;
      case 1: // PDF2 tab
        pdf2Shift = value;
        break;
      case 2: // PDF3 tab
        pdf3Shift = value;
        break;
      case 3: // Excel tab
        excelShift = value;
        break;
    }
    
    // Auto-save to cloud if not during initial load
    if (!_isInitialLoad) {
      _debouncedSyncToCloud();
    }
  }

  void _saveGlobalNotice(String value) {
    globalNotice = value;
    
    // Auto-save to cloud if not during initial load
    if (!_isInitialLoad) {
      _debouncedSyncToCloud();
    }
  }

  void _saveProfessionCards() {
    print('=== SAVING PROFESSION CARDS (CLOUD ONLY) ===');
    print('Auto-saving ${professionCards.length} cards to cloud');
    
    // Debug: Print details about each card
    for (int i = 0; i < professionCards.length; i++) {
      final card = professionCards[i];
      print('Card $i: ${card.professionName} - Tasks: ${card.tasks.length} Equipment: "${card.equipment}"');
    }
    
    // Auto-save to cloud if not during initial load
    if (!_isInitialLoad) {
      print('Attempting cloud auto-save...');
      _debouncedSyncToCloud();
    } else {
      print('Skipping cloud sync - initial load');
    }
  }

  void _saveExcelFields() {
    // Auto-save to cloud if not during initial load
    if (!_isInitialLoad) {
      _debouncedSyncToCloud();
    }
  }

  void _saveShiftNotes(int tabIndex) {
    // Auto-save to cloud if not during initial load
    if (!_isInitialLoad) {
      _debouncedSyncToCloud();
    }
  }

  // Debounced sync to cloud to prevent race conditions
  Future<void> _debouncedSyncToCloud() async {
    // Cancel previous timer if it exists
    _saveDebounceTimer?.cancel();
    
    // Set a new timer for 500ms delay
    _saveDebounceTimer = Timer(Duration(milliseconds: 500), () async {
      if (!_isInitialLoad && SupabaseService.isLoggedIn && !_isSaving) {
        await _syncToCloud();
      }
    });
  }

  // Sync all data to cloud
  Future<void> _syncToCloud() async {
    if (!SupabaseService.isLoggedIn || _isSaving) {
      print('Not syncing - not logged in or already saving');
      return;
    }
    
    _isSaving = true;
    try {
      print('=== SYNCING TO CLOUD ===');
      
      // Save work cards
      print('Syncing ${professionCards.length} cards to cloud...');
      await SupabaseService.saveWorkCards(professionCards);
      
      // Save user settings
      final settings = {
        'pdf_supervisor': pdfSupervisor,
        'pdf_date': pdfDate,
        'pdf_shift': pdfShift,
        'pdf2_supervisor': pdf2Supervisor,
        'pdf2_date': pdf2Date,
        'pdf2_shift': pdf2Shift,
        'pdf3_supervisor': pdf3Supervisor,
        'pdf3_date': pdf3Date,
        'pdf3_shift': pdf3Shift,
        'excel_supervisor': excelSupervisor,
        'excel_date': excelDate,
        'excel_shift': excelShift,
        'global_notice': globalNotice,
        'shift_notes': shiftNotes,
        'shift_notes2': shiftNotes2,
        'shift_notes3': shiftNotes3,
        'comments': comments,
        'extra_work': extraWork,
      };
      
      print('Syncing settings to cloud...');
      await SupabaseService.saveUserSettings(settings);
      
      print('Successfully synced all data to cloud');
    } catch (e) {
      print('Failed to sync to cloud: $e');
      // Show error to user if context is available
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Virhe tallentaessa pilvipalveluun: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      _isSaving = false;
    }
  }

  // Manual save method for the save button
  Future<void> _manualSave() async {
    if (!SupabaseService.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Et ole kirjautunut sisään!'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 16),
            Text('Tallennetaan pilvipalveluun...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      await _syncToCloud();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Kaikki tiedot tallennettu pilvipalveluun!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Error already shown in _syncToCloud
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _saveDebounceTimer?.cancel();
    
    // Dispose shift note controllers
    for (var controller in _shiftNoteControllers) {
      controller.dispose();
    }
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // Authentication status indicator
            if (SupabaseService.isLoggedIn)
              Tooltip(
                message: 'Cloud sync enabled',
                child: Icon(Icons.cloud_done, color: Colors.green),
              )
            else if (SupabaseService.isAvailable)
              Tooltip(
                message: 'Cloud sync available. Press the user icon to log in.',
                child: Icon(Icons.cloud_queue, color: Colors.orange),
              )
            else
              Tooltip(
                message: 'Using local storage only. Cloud sync is not available.',
                child: Icon(Icons.cloud_off, color: Colors.red),
              ),
          ],
        ),
        actions: [
          // Info button
          IconButton(
            onPressed: _showUserGuide,
            icon: const Icon(Icons.help_outline),
            tooltip: 'Käyttöohje',
          ),
          // Manual Save button (always visible, disabled when not logged in)
          IconButton(
            onPressed: SupabaseService.isLoggedIn ? _manualSave : null,
            icon: Icon(
              Icons.cloud_upload,
              color: !SupabaseService.isLoggedIn 
                  ? Colors.grey.shade400
                  : _isSaving 
                      ? Colors.grey 
                      : Colors.blue.shade700,
            ),
            tooltip: SupabaseService.isLoggedIn 
                ? 'Tallenna pilvipalveluun' 
                : 'Kirjaudu sisään tallentaaksesi',
          ),
          const SizedBox(width: 8),
          // Authentication button
          IconButton(
            icon: Icon(SupabaseService.isLoggedIn ? Icons.logout : Icons.person),
            onPressed: () {
              if (SupabaseService.isLoggedIn) {
                _confirmLogout();
              } else {
                widget.onShowAuth();
              }
            },
          ),
          // Settings (right)
          IconButton(
            onPressed: () => _openSettings(isDarkMode),
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'PDF'),
            Tab(text: 'PDF2'),
            Tab(text: 'PDF3'),
            Tab(text: 'Excel'),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000), // Increased from 800px to 1000px
          child: Column(
            children: [
              // Input row - changes based on selected tab
              SizedBox(
                height: 70,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // PDF Tab content
                    InfoInputRow(
                      supervisor: pdfSupervisor,
                      date: pdfDate,
                      shift: pdfShift,
                      professionCards: professionCards,
                      isPDFTab: true,
                      tabIndex: 0,
                      onSupervisorChanged: (value) => setState(() => _saveSupervisor(value, 0)),
                      onDateChanged: (value) => setState(() => _saveDate(value, 0)),
                      onShiftChanged: (value) => setState(() => _saveShift(value, 0)),
                    ),
                    // PDF2 Tab content
                    InfoInputRow(
                      supervisor: pdf2Supervisor,
                      date: pdf2Date,
                      shift: pdf2Shift,
                      professionCards: professionCards,
                      isPDFTab: true,
                      tabIndex: 1,
                      onSupervisorChanged: (value) => setState(() => _saveSupervisor(value, 1)),
                      onDateChanged: (value) => setState(() => _saveDate(value, 1)),
                      onShiftChanged: (value) => setState(() => _saveShift(value, 1)),
                    ),
                    // PDF3 Tab content
                    InfoInputRow(
                      supervisor: pdf3Supervisor,
                      date: pdf3Date,
                      shift: pdf3Shift,
                      professionCards: professionCards,
                      isPDFTab: true,
                      tabIndex: 2,
                      onSupervisorChanged: (value) => setState(() => _saveSupervisor(value, 2)),
                      onDateChanged: (value) => setState(() => _saveDate(value, 2)),
                      onShiftChanged: (value) => setState(() => _saveShift(value, 2)),
                    ),
                    // Excel Tab content
                    InfoInputRow(
                      supervisor: excelSupervisor,
                      date: excelDate,
                      shift: excelShift,
                      professionCards: professionCards,
                      isPDFTab: false,
                      tabIndex: 3,
                      onSupervisorChanged: (value) => setState(() => _saveSupervisor(value, 3)),
                      onDateChanged: (value) => setState(() => _saveDate(value, 3)),
                      onShiftChanged: (value) => setState(() => _saveShift(value, 3)),
                    ),
                  ],
                ),
              ),
              
              // Profession Cards and Bottom Fields
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // PDF Tab - with print buttons
                    _buildPDFTabContent(tabIndex: 0),
                    // PDF2 Tab - with print buttons
                    _buildPDFTabContent(tabIndex: 1),
                    // PDF3 Tab - with print buttons  
                    _buildPDFTabContent(tabIndex: 2),
                    // Excel Tab - with export button
                    _buildExcelTabContent(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addProfessionCard,
        child: const Icon(Icons.add),
        tooltip: 'Add Profession Card',
      ),
    );
  }

  Widget _buildPDFTabContent({required int tabIndex}) {
    return Column(
      children: [
        // Print buttons for this PDF tab
        Container(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 180,
                child: ElevatedButton.icon(
                  onPressed: () => _exportPDFForTab(tabIndex),
                  icon: const Icon(Icons.picture_as_pdf, size: 18),
                  label: const Text('Työkortti'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 180,
                child: ElevatedButton.icon(
                  onPressed: () => _exportSummaryForTab(tabIndex),
                  icon: const Icon(Icons.summarize, size: 18),
                  label: const Text('Yhteenveto'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Profession cards list
        Expanded(
          child: _buildProfessionCardsList(isPDFTab: true, tabIndex: tabIndex),
        ),
      ],
    );
  }

  Widget _buildExcelTabContent() {
    return Column(
      children: [
        // Excel export button
        Container(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 180,
                child: ElevatedButton.icon(
                  onPressed: _exportExcel,
                  icon: const Icon(Icons.table_chart, size: 18),
                  label: const Text('Tulosta Excel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Profession cards list with Excel fields
        Expanded(
          child: _buildProfessionCardsList(isPDFTab: false),
        ),
      ],
    );
  }

  Widget _buildProfessionCardsList({required bool isPDFTab, int? tabIndex}) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: professionCards.length + 1, // +1 for the header fields
      itemBuilder: (context, index) {
        // First item: show the specific fields for each tab
        if (index == 0) {
          if (isPDFTab) {
            // PDF tab: Global Notice Field + Shift Notes for this specific tab
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlobalNoticeField(
                    value: globalNotice,
                    onChanged: (value) => setState(() => _saveGlobalNotice(value)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildShiftNotesSection(tabIndex: tabIndex!),
                ),
              ],
            );
          } else {
            // Excel tab: Excel Specific Fields
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ExcelSpecificFields(
                comments: comments,
                extraWork: extraWork,
                onCommentsChanged: (newComments) => setState(() {
                  comments = newComments;
                  _saveExcelFields();
                }),
                onExtraWorkChanged: (newExtraWork) => setState(() {
                  extraWork = newExtraWork;
                  _saveExcelFields();
                }),
              ),
            );
          }
        }
        
        // Profession cards (adjust index since first item is the fields)
        final cardIndex = index - 1;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ProfessionCard(
            data: professionCards[cardIndex],
            isPDFTab: isPDFTab,
            tabIndex: tabIndex,
            onDataChanged: (newData) {
              setState(() {
                professionCards[cardIndex] = newData;
                _saveProfessionCards();
              });
            },
            onDelete: () {
              setState(() {
                professionCards.removeAt(cardIndex);
                _saveProfessionCards();
              });
            },
          ),
        );
      },
    );
  }

  void _addProfessionCard() {
    if (professionCards.length < 10) {
      setState(() {
        professionCards.add(ProfessionCardData());
        _saveProfessionCards();
      });
    }
  }

  int _calculatePDFManpowerCount() {
    int count = 0;
    for (final card in professionCards) {
      if (card.pdfName1.isNotEmpty) count++;
      if (card.pdfName2.isNotEmpty) count++;
    }
    return count;
  }

  int _calculateExcelManpowerCount() {
    int count = 0;
    for (final card in professionCards) {
      if (card.excelName1.isNotEmpty) count++;
      if (card.excelName2.isNotEmpty) count++;
    }
    return count;
  }

  // Export methods for specific tabs
  void _exportPDFForTab(int tabIndex) async {
    String supervisor, shift, date;
    List<String> currentShiftNotes;
    
    switch (tabIndex) {
      case 0:
        supervisor = pdfSupervisor;
        shift = pdfShift;
        date = pdfDate;
        currentShiftNotes = shiftNotes;
        break;
      case 1:
        supervisor = pdf2Supervisor;
        shift = pdf2Shift;
        date = pdf2Date;
        currentShiftNotes = shiftNotes2;
        break;
      case 2:
        supervisor = pdf3Supervisor;
        shift = pdf3Shift;
        date = pdf3Date;
        currentShiftNotes = shiftNotes3;
        break;
      default:
        return;
    }

    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Luodaan PDF${tabIndex == 0 ? '' : tabIndex + 1}-tiedostoja...')),
      );

      await PdfService.exportToPdf(
        pdfSupervisor: supervisor,
        pdfShift: shift,
        pdfDate: date,
        globalNotice: globalNotice,
        professionCards: professionCards,
        shiftNotes: currentShiftNotes,
        pdfTabIndex: tabIndex,
      );

      // Success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF${tabIndex == 0 ? '' : tabIndex + 1}-tiedostot luotu onnistuneesti!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Error feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Virhe PDF${tabIndex == 0 ? '' : tabIndex + 1}-tiedostojen luonnissa: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _exportSummaryForTab(int tabIndex) async {
    String supervisor, shift, date;
    List<String> currentShiftNotes;
    
    switch (tabIndex) {
      case 0:
        supervisor = pdfSupervisor;
        shift = pdfShift;
        date = pdfDate;
        currentShiftNotes = shiftNotes;
        break;
      case 1:
        supervisor = pdf2Supervisor;
        shift = pdf2Shift;
        date = pdf2Date;
        currentShiftNotes = shiftNotes2;
        break;
      case 2:
        supervisor = pdf3Supervisor;
        shift = pdf3Shift;
        date = pdf3Date;
        currentShiftNotes = shiftNotes3;
        break;
      default:
        return;
    }

    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Luodaan yhteenveto-PDF${tabIndex == 0 ? '' : tabIndex + 1}...')),
      );

      await PdfService.exportSummaryOnly(
        supervisor: supervisor,
        shift: shift,
        date: date,
        professionCards: professionCards,
        shiftNotes: currentShiftNotes,
        pdfTabIndex: tabIndex,
      );

      // Success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Yhteenveto-PDF${tabIndex == 0 ? '' : tabIndex + 1} luotu onnistuneesti!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Error feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Virhe yhteenveto-PDF${tabIndex == 0 ? '' : tabIndex + 1}:n luonnissa: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _exportExcel() async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Luodaan Excel-tiedostoa...')),
      );

      await ExcelService.exportToExcel(
        excelSupervisor: excelSupervisor,
        excelShift: excelShift,
        excelDate: excelDate,
        comments: comments,
        extraWork: extraWork,
        professionCards: professionCards,
      );

      // Success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Excel-tiedosto luotu ja avattu onnistuneesti!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Error feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Virhe Excel-tiedoston luonnissa: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openSettings(bool isDarkMode) async {
    // Don't unfocus text fields when navigating to settings
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          isDarkMode: isDarkMode,
          onThemeChanged: widget.onThemeChanged,
        ),
      ),
    );
    // The focus state will be preserved when returning
  }

  Widget _buildShiftNotesSection({required int tabIndex}) {
    List<String> currentShiftNotes;
    List<TextEditingController> currentControllers;
    
    switch (tabIndex) {
      case 0:
        currentShiftNotes = shiftNotes;
        currentControllers = _shiftNoteControllers;
        break;
      case 1:
        currentShiftNotes = shiftNotes2;
        currentControllers = _shiftNoteControllers2;
        break;
      case 2:
        currentShiftNotes = shiftNotes3;
        currentControllers = _shiftNoteControllers3;
        break;
      default:
        currentShiftNotes = shiftNotes;
        currentControllers = _shiftNoteControllers;
        break;
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._buildShiftNotesFields(tabIndex: tabIndex, shiftNotes: currentShiftNotes, controllers: currentControllers),
        ],
      ),
    );
  }

  List<Widget> _buildShiftNotesFields({required int tabIndex, required List<String> shiftNotes, required List<TextEditingController> controllers}) {
    List<Widget> fields = [];
    int lastNonEmpty = _getLastNonEmptyShiftNoteIndex(shiftNotes);
    int fieldsToShow = (lastNonEmpty + 2).clamp(1, 100);

    // Ensure we have enough shift notes and controllers
    while (shiftNotes.length < fieldsToShow) {
      shiftNotes.add('');
    }
    while (controllers.length < fieldsToShow) {
      controllers.add(TextEditingController(text: shiftNotes[controllers.length]));
    }

    for (int i = 0; i < fieldsToShow; i++) {
      fields.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controllers[i],
                  onChanged: (value) => _updateShiftNote(i, value, tabIndex),
                  decoration: InputDecoration(
                    hintText: i == 0 ? 'Huomioita seuraavalle vuorolle (ei tule exceliin)' : 'Huomio ${i + 1}',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    isDense: true,
                  ),
                ),
              ),
              if (i == fieldsToShow - 1 && lastNonEmpty < 99)
                IconButton(
                  onPressed: () => _addShiftNote(tabIndex),
                  icon: const Icon(Icons.add_circle),
                  iconSize: 14,
                  padding: const EdgeInsets.only(left: 4),
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),
      );
    }

    return fields;
  }

  int _getLastNonEmptyShiftNoteIndex(List<String> shiftNotes) {
    for (int i = shiftNotes.length - 1; i >= 0; i--) {
      if (shiftNotes[i].isNotEmpty) {
        return i;
      }
    }
    return -1; // All empty
  }

  void _updateShiftNote(int index, String value, int tabIndex) {
    List<String> currentShiftNotes;
    List<TextEditingController> currentControllers;
    
    switch (tabIndex) {
      case 0:
        currentShiftNotes = shiftNotes;
        currentControllers = _shiftNoteControllers;
        break;
      case 1:
        currentShiftNotes = shiftNotes2;
        currentControllers = _shiftNoteControllers2;
        break;
      case 2:
        currentShiftNotes = shiftNotes3;
        currentControllers = _shiftNoteControllers3;
        break;
      default:
        return;
    }
    
    // Ensure list is large enough
    while (currentShiftNotes.length <= index) {
      currentShiftNotes.add('');
    }
    
    setState(() {
      currentShiftNotes[index] = value;
      _saveShiftNotes(tabIndex);
    });
  }

  void _addShiftNote(int tabIndex) {
    List<String> currentShiftNotes;
    List<TextEditingController> currentControllers;
    
    switch (tabIndex) {
      case 0:
        currentShiftNotes = shiftNotes;
        currentControllers = _shiftNoteControllers;
        break;
      case 1:
        currentShiftNotes = shiftNotes2;
        currentControllers = _shiftNoteControllers2;
        break;
      case 2:
        currentShiftNotes = shiftNotes3;
        currentControllers = _shiftNoteControllers3;
        break;
      default:
        return;
    }
    
    if (currentShiftNotes.length < 100) {
      setState(() {
        currentShiftNotes.add('');
        currentControllers.add(TextEditingController(text: ''));
        _saveShiftNotes(tabIndex);
      });
    }
  }

  void _confirmClearAll() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Tyhjennä kaikki'),
          content: const Text(
            'Haluatko varmasti tyhjentää kaikki tehtävät, koneet, koneiden sijainnit, vuorohuomiot, erityishuomiot ja lisätyöt molemmista välilehdistä?\n\nTämä toiminto ei vaikuta työntekijöiden nimiin tai ammattinimikkeisiin.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Peruuta'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Tyhjennä'),
            ),
          ],
        );
      },
    );

    if (shouldClear == true) {
      setState(() {
        // Clear all tasks, equipment, and equipment locations from all profession cards
        for (int i = 0; i < professionCards.length; i++) {
          professionCards[i] = ProfessionCardData(
            professionName: professionCards[i].professionName, // Keep profession name
            pdfName1: professionCards[i].pdfName1, // Keep PDF names
            pdfName2: professionCards[i].pdfName2,
            excelName1: professionCards[i].excelName1, // Keep Excel names
            excelName2: professionCards[i].excelName2,
            tasks: [], // Clear all tasks
            equipment: '', // Clear equipment
            equipmentLocation: '', // Clear equipment location
          );
        }
        
        // Clear shift notes
        shiftNotes = [''];
        
        // Clear Excel specific fields
        comments = [''];
        extraWork = [''];
        
        // Save all changes
        _saveProfessionCards();
        _saveExcelFields();
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kaikki tehtävät, koneet, vuorohuomiot ja Excel-kentät tyhjennetty!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Kirjaudu ulos'),
          content: const Text('Haluatko varmasti kirjautua ulos?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Peruuta'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Kirjaudu ulos'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      SupabaseService.signOut();
      widget.onShowAuth(); // Go back to auth screen
    }
  }

  void _confirmResetAccount() async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Account'),
          content: const Text(
            'Haluatko varmasti resetoida KAIKKI tiliin liittyvät tiedot pilvipalvelusta? \n\nTämä poistaa:\n• Kaikki työkorttitiedot\n• Kaikki asetukset\n• Kaikki tallennetut tiedot\n\nTätä toimintoa EI VOI peruuttaa!',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Peruuta'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('RESETOI KAIKKI'),
            ),
          ],
        );
      },
    );

    if (shouldReset == true) {
      try {
        // Show loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Resetoidaan tiliä...'),
            duration: Duration(seconds: 2),
          ),
        );

        // Reset cloud data
        await SupabaseService.resetUserData();
        
        // Reset local data
        setState(() {
          professionCards = [
            ProfessionCardData(professionName: 'Varu1'),
            ProfessionCardData(professionName: 'Varu2'),
            ProfessionCardData(professionName: 'Varu3'),
            ProfessionCardData(professionName: 'Varu4'),
            ProfessionCardData(professionName: 'Pasta1'),
            ProfessionCardData(professionName: 'Pasta2'),
            ProfessionCardData(professionName: 'Pora'),
            ProfessionCardData(professionName: 'Tarvikeauto'),
            ProfessionCardData(professionName: 'Huoltomies'),
          ];
          pdfSupervisor = '';
          pdfDate = '';
          pdfShift = '';
          pdf2Supervisor = '';
          pdf2Date = '';
          pdf2Shift = '';
          pdf3Supervisor = '';
          pdf3Date = '';
          pdf3Shift = '';
          excelSupervisor = '';
          excelDate = '';
          excelShift = '';
          globalNotice = '';
          shiftNotes = [''];
          shiftNotes2 = [''];
          shiftNotes3 = [''];
          comments = [''];
          extraWork = [''];
        });
        
        // Save the fresh defaults to cloud
        await _syncToCloud();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tili resetoitu onnistuneesti! Käytetään oletusmalleja.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } catch (e) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Virhe tilin resetoinnissa: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _saveData() async {
    print('=== SAVING DATA (CLOUD ONLY) ===');
    print('Is initial load: $_isInitialLoad');
    
    // Only save to cloud if user is logged in
    if (SupabaseService.isLoggedIn && !_isInitialLoad) {
      print('Syncing to cloud...');
      await _syncToCloud();
    } else {
      print('Skipping save - initial load: $_isInitialLoad, logged in: ${SupabaseService.isLoggedIn}');
    }
  }

  void _showUserGuide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('Käyttöohje'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sovelluksessa on 4 välilehteä. Jokaisella välilehdellä on omat:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                const Text('• Asentajat ja työnjohtaja'),
                const Text('• Päivämäärä'),
                const Text('• Vuoro'),
                const Text('• Vahvuus (henkilömäärä)'),
                const SizedBox(height: 16),
                const Text(
                  'Nämä vaihtelevat välilehdittäin.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 16),
                
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: const Text(
                    'Tehtävät ovat samat kaikissa välilehdissä. Jos muokkaat tehtävää yhdessä, se päivittyy muihinkin.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                
                const SizedBox(height: 16),
                const Text(
                  'Excelissä on pari lisäkenttää, jotka näkyvät vain Excelissä. Lisäksi Excel-välilehdeltä löytyy ajoneuvot ja niiden sijainnit.',
                ),
                
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Huomiot:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text('• "Huomio seuraavalle vuorolle" näkyy vain Yhteenveto-PDF:ssä'),
                      const Text('• "Yleinen huomio" näkyy kaikissa työkorteissa'),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                const Text(
                  'Välilehdillä on ammattinimikkeitä. Kaikki saman nimikkeen asentajat saavat samat tehtävät työkorttiin. Korttien määrä määräytyy nimien perusteella – tyhjät jätetään pois.',
                ),
                
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: const Text(
                    'Vahvuus-sarakkeessa näkyy automaattisesti montako nimeä on annettu vuoroon.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                
                const SizedBox(height: 16),
                const Text(
                  'Jos olet aina vain yhdessä vuorossa, riittää että käytät yhtä PDF-välilehteä. Voit halutessasi täyttää toisen välilehden seuraavaa vuoroa varten, jotta oman vastavuoron nimet eivät katoa.',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Sulje'),
          ),
        ],
      ),
    );
  }
}

class ProfessionCardData {
  String professionName;
  // Separate names for each PDF tab
  String pdfName1;
  String pdfName2;
  String pdf2Name1; // NEW - for PDF2 tab
  String pdf2Name2; // NEW - for PDF2 tab
  String pdf3Name1; // NEW - for PDF3 tab
  String pdf3Name2; // NEW - for PDF3 tab
  String excelName1;
  String excelName2;
  List<TaskData> tasks;
  String equipment;
  String equipmentLocation;
  // New dynamic fields for work site conditions and supervisor risk notes
  List<String> workSiteConditions;
  List<String> supervisorRiskNotes;

  ProfessionCardData({
    this.professionName = '',
    this.pdfName1 = '',
    this.pdfName2 = '',
    this.pdf2Name1 = '', // NEW
    this.pdf2Name2 = '', // NEW
    this.pdf3Name1 = '', // NEW
    this.pdf3Name2 = '', // NEW
    this.excelName1 = '',
    this.excelName2 = '',
    this.tasks = const [],
    this.equipment = '',
    this.equipmentLocation = '',
    this.workSiteConditions = const [],
    this.supervisorRiskNotes = const [],
  }) {
    if (tasks.isEmpty) {
      tasks = [TaskData()];
    }
    if (workSiteConditions.isEmpty) {
      workSiteConditions = [''];
    }
    if (supervisorRiskNotes.isEmpty) {
      supervisorRiskNotes = [''];
    }
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'professionName': professionName,
      'pdfName1': pdfName1,
      'pdfName2': pdfName2,
      'pdf2Name1': pdf2Name1,
      'pdf2Name2': pdf2Name2,
      'pdf3Name1': pdf3Name1,
      'pdf3Name2': pdf3Name2,
      'excelName1': excelName1,
      'excelName2': excelName2,
      'tasks': tasks.map((task) => task.toJson()).toList(),
      'equipment': equipment,
      'equipmentLocation': equipmentLocation,
      'workSiteConditions': workSiteConditions,
      'supervisorRiskNotes': supervisorRiskNotes,
    };
  }

  factory ProfessionCardData.fromJson(Map<String, dynamic> json) {
    return ProfessionCardData(
      professionName: json['professionName'] ?? '',
      pdfName1: json['pdfName1'] ?? '',
      pdfName2: json['pdfName2'] ?? '',
      pdf2Name1: json['pdf2Name1'] ?? '', // NEW
      pdf2Name2: json['pdf2Name2'] ?? '', // NEW
      pdf3Name1: json['pdf3Name1'] ?? '', // NEW
      pdf3Name2: json['pdf3Name2'] ?? '', // NEW
      excelName1: json['excelName1'] ?? '',
      excelName2: json['excelName2'] ?? '',
      tasks: (json['tasks'] as List<dynamic>?)
          ?.map((taskJson) => TaskData.fromJson(taskJson))
          .toList() ?? [TaskData()],
      equipment: json['equipment'] ?? '',
      equipmentLocation: json['equipmentLocation'] ?? '',
      workSiteConditions: List<String>.from(json['workSiteConditions'] ?? ['']),
      supervisorRiskNotes: List<String>.from(json['supervisorRiskNotes'] ?? ['']),
    );
  }
}

class TaskData {
  String task;
  String taskNotice;

  TaskData({
    this.task = '',
    this.taskNotice = '',
  });

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'task': task,
      'taskNotice': taskNotice,
    };
  }

  factory TaskData.fromJson(Map<String, dynamic> json) {
    return TaskData(
      task: json['task'] ?? '',
      taskNotice: json['taskNotice'] ?? '',
    );
  }
} 
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/info_input_row.dart';
import '../widgets/global_notice_field.dart';
import '../widgets/profession_card.dart';
import '../widgets/excel_specific_fields.dart';
import '../screens/settings_screen.dart';
import '../services/supabase_service.dart';
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
  
  // Tab-specific data
  String pdfSupervisor = '';
  String pdfDate = '';
  String pdfShift = '';
  
  String excelSupervisor = '';
  String excelDate = '';
  String excelShift = '';
  
  // Shared data
  String globalNotice = '';
  List<ProfessionCardData> professionCards = [];
  
  // Excel-specific
  List<String> comments = [''];
  List<String> extraWork = [''];
  
  // Shift notes (for PDF summary only, not Excel)
  List<String> shiftNotes = [''];
  List<TextEditingController> _shiftNoteControllers = [];
  
  // Add flag to prevent syncing during initial load
  bool _isInitialLoad = true;
  
  // Add debouncing for saves
  Timer? _saveDebounceTimer;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Initialize shift note controllers
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
    _shiftNoteControllers.clear();
    
    // Create controllers for current shift notes
    for (int i = 0; i < shiftNotes.length; i++) {
      _shiftNoteControllers.add(TextEditingController(text: shiftNotes[i]));
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
        excelSupervisor = cloudSettings['excel_supervisor'] ?? '';
        excelDate = cloudSettings['excel_date'] ?? '';
        excelShift = cloudSettings['excel_shift'] ?? '';
        globalNotice = cloudSettings['global_notice'] ?? '';
        shiftNotes = List<String>.from(cloudSettings['shift_notes'] ?? ['']);
        comments = List<String>.from(cloudSettings['comments'] ?? ['']);
        extraWork = List<String>.from(cloudSettings['extra_work'] ?? ['']);
      } else {
        // Initialize empty settings for first time users
        shiftNotes = [''];
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

  // Auto-save methods (cloud-only)
  void _saveSupervisor(String value, bool isPDF) {
    if (isPDF) {
      pdfSupervisor = value;
    } else {
      excelSupervisor = value;
    }
    
    // Auto-save to cloud if not during initial load
    if (!_isInitialLoad) {
      _debouncedSyncToCloud();
    }
  }

  void _saveDate(String value, bool isPDF) {
    if (isPDF) {
      pdfDate = value;
    } else {
      excelDate = value;
    }
    
    // Auto-save to cloud if not during initial load
    if (!_isInitialLoad) {
      _debouncedSyncToCloud();
    }
  }

  void _saveShift(String value, bool isPDF) {
    if (isPDF) {
      pdfShift = value;
    } else {
      excelShift = value;
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

  void _saveShiftNotes() {
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
        'excel_supervisor': excelSupervisor,
        'excel_date': excelDate,
        'excel_shift': excelShift,
        'global_notice': globalNotice,
        'shift_notes': shiftNotes,
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
          // Clear All button (moved to left side)
          IconButton(
            onPressed: _confirmClearAll,
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear All Tasks & Equipment',
            color: Colors.orange.shade700,
          ),
          const SizedBox(width: 8), // Add spacing between clear and save buttons
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
          const SizedBox(width: 8), // Add spacing between save and reset buttons
          // Reset Account button (only show if logged in)
          if (SupabaseService.isLoggedIn)
            IconButton(
              onPressed: _confirmResetAccount,
              icon: const Icon(Icons.delete_forever),
              tooltip: 'Reset Account Data',
              color: Colors.red.shade800,
            ),
          const SizedBox(width: 8),
          // PDF Export
          IconButton(
            onPressed: _exportPDF,
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export PDF',
          ),
          // Summary Export
          IconButton(
            onPressed: _exportSummary,
            icon: const Icon(Icons.summarize),
            tooltip: 'Export Summary',
          ),
          // Excel Export
          IconButton(
            onPressed: _exportExcel,
            icon: const Icon(Icons.table_chart),
            tooltip: 'Export Excel',
          ),
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
                      onSupervisorChanged: (value) => setState(() => _saveSupervisor(value, true)),
                      onDateChanged: (value) => setState(() => _saveDate(value, true)),
                      onShiftChanged: (value) => setState(() => _saveShift(value, true)),
                    ),
                    // Excel Tab content
                    InfoInputRow(
                      supervisor: excelSupervisor,
                      date: excelDate,
                      shift: excelShift,
                      professionCards: professionCards,
                      isPDFTab: false,
                      onSupervisorChanged: (value) => setState(() => _saveSupervisor(value, false)),
                      onDateChanged: (value) => setState(() => _saveDate(value, false)),
                      onShiftChanged: (value) => setState(() => _saveShift(value, false)),
                    ),
                  ],
                ),
              ),
              
              // Profession Cards and Bottom Fields
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // PDF Tab - Profession cards with global notice scrolling above
                    _buildProfessionCardsList(isPDFTab: true),
                    // Excel Tab - Profession cards with excel fields scrolling above
                    _buildProfessionCardsList(isPDFTab: false),
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

  Widget _buildProfessionCardsList({required bool isPDFTab}) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: professionCards.length + 1, // +1 for the header fields
      itemBuilder: (context, index) {
        // First item: show the specific fields for each tab
        if (index == 0) {
          if (isPDFTab) {
            // PDF tab: Global Notice Field + Shift Notes
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
                  child: _buildShiftNotesSection(),
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

  void _exportPDF() async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Luodaan PDF-tiedostoja...')),
      );

      await PdfService.exportToPdf(
        pdfSupervisor: pdfSupervisor,
        pdfShift: pdfShift,
        pdfDate: pdfDate,
        globalNotice: globalNotice,
        professionCards: professionCards,
        shiftNotes: shiftNotes,
      );

      // Success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF-tiedostot luotu onnistuneesti!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Error feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Virhe PDF-tiedostojen luonnissa: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _exportSummary() async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Luodaan yhteenveto-PDF...')),
      );

      await PdfService.exportSummaryOnly(
        supervisor: pdfSupervisor,
        shift: pdfShift,
        date: pdfDate,
        professionCards: professionCards,
        shiftNotes: shiftNotes,
      );

      // Success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yhteenveto-PDF luotu onnistuneesti!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Error feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Virhe yhteenveto-PDF:n luonnissa: $e'),
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

  Widget _buildShiftNotesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._buildShiftNotesFields(),
        ],
      ),
    );
  }

  List<Widget> _buildShiftNotesFields() {
    List<Widget> fields = [];
    int lastNonEmpty = _getLastNonEmptyShiftNoteIndex();
    int fieldsToShow = (lastNonEmpty + 2).clamp(1, 100); // Show at least 1, at most 100

    // Ensure we have enough shift notes and controllers
    while (shiftNotes.length < fieldsToShow) {
      shiftNotes.add('');
    }
    while (_shiftNoteControllers.length < fieldsToShow) {
      _shiftNoteControllers.add(TextEditingController(text: shiftNotes[_shiftNoteControllers.length]));
    }

    for (int i = 0; i < fieldsToShow; i++) {
      fields.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _shiftNoteControllers[i],
                  onChanged: (value) => _updateShiftNote(i, value),
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
                  onPressed: _addShiftNote,
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

  int _getLastNonEmptyShiftNoteIndex() {
    for (int i = shiftNotes.length - 1; i >= 0; i--) {
      if (shiftNotes[i].isNotEmpty) {
        return i;
      }
    }
    return -1; // All empty
  }

  void _updateShiftNote(int index, String value) {
    // Ensure list is large enough
    while (shiftNotes.length <= index) {
      shiftNotes.add('');
    }
    
    setState(() {
      shiftNotes[index] = value;
      _saveShiftNotes();
    });
  }

  void _addShiftNote() {
    if (shiftNotes.length < 100) {
      setState(() {
        shiftNotes.add('');
        _shiftNoteControllers.add(TextEditingController(text: ''));
        _saveShiftNotes();
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
        _saveShiftNotes();
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
          excelSupervisor = '';
          excelDate = '';
          excelShift = '';
          globalNotice = '';
          shiftNotes = [''];
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
}

class ProfessionCardData {
  String professionName;
  String pdfName1;
  String pdfName2;
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
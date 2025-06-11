import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/info_input_row.dart';
import '../widgets/global_notice_field.dart';
import '../widgets/profession_card.dart';
import '../widgets/excel_specific_fields.dart';
import '../screens/settings_screen.dart';
import '../services/local_storage_service.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Load saved data
    _loadData();
  }

  Future<void> _loadData() async {
    // Try to load from cloud first if logged in, fallback to local storage
    if (SupabaseService.isLoggedIn) {
      try {
        // Load from Supabase
        final cloudCards = await SupabaseService.loadWorkCards();
        final cloudSettings = await SupabaseService.loadUserSettings();
        
        if (cloudCards.isNotEmpty) {
          professionCards = cloudCards;
        }
        
        if (cloudSettings != null) {
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
        }
        
        setState(() {});
        return;
      } catch (e) {
        print('Failed to load from cloud, falling back to local: $e');
      }
    }
    
    // Fallback to local storage
    pdfSupervisor = await LocalStorageService.loadPdfSupervisor();
    pdfDate = await LocalStorageService.loadPdfDate();
    pdfShift = await LocalStorageService.loadPdfShift();
    
    excelSupervisor = await LocalStorageService.loadExcelSupervisor();
    excelDate = await LocalStorageService.loadExcelDate();
    excelShift = await LocalStorageService.loadExcelShift();
    
    // If Excel fields are empty, copy from PDF (for initial setup)
    if (excelSupervisor.isEmpty) excelSupervisor = pdfSupervisor;
    if (excelDate.isEmpty) excelDate = pdfDate;
    if (excelShift.isEmpty) excelShift = pdfShift;
    
    globalNotice = await LocalStorageService.loadGlobalNotice();
    
    final loadedCards = await LocalStorageService.loadProfessionCards();
    if (loadedCards.isNotEmpty) {
      professionCards = loadedCards;
    } else {
      // Create default profession cards if no saved cards exist
      professionCards.addAll([
        ProfessionCardData(professionName: 'Varu1'),
        ProfessionCardData(professionName: 'Varu2'),
        ProfessionCardData(professionName: 'Varu3'),
        ProfessionCardData(professionName: 'Varu4'),
        ProfessionCardData(professionName: 'Pasta1'),
        ProfessionCardData(professionName: 'Pasta2'),
        ProfessionCardData(professionName: 'Pora'),
        ProfessionCardData(professionName: 'Tarvikeauto'),
        ProfessionCardData(professionName: 'Huoltomies'),
      ]);
    }
    
    final excelFields = await LocalStorageService.loadExcelSpecificFields();
    if (excelFields.isNotEmpty) {
      comments = List<String>.from(excelFields['comments'] ?? ['']);
      extraWork = List<String>.from(excelFields['extraWork'] ?? ['']);
    }
    
    // Load shift notes
    final savedShiftNotes = await LocalStorageService.loadShiftNotes();
    if (savedShiftNotes.isNotEmpty) {
      shiftNotes = savedShiftNotes;
    }
    
    setState(() {});
  }

  // Auto-save methods with cloud sync
  void _saveSupervisor(String value, bool isPDF) {
    if (isPDF) {
      pdfSupervisor = value;
      LocalStorageService.savePdfSupervisor(value);
    } else {
      excelSupervisor = value;
      LocalStorageService.saveExcelSupervisor(value);
    }
    _syncToCloud();
  }

  void _saveDate(String value, bool isPDF) {
    if (isPDF) {
      pdfDate = value;
      LocalStorageService.savePdfDate(value);
    } else {
      excelDate = value;
      LocalStorageService.saveExcelDate(value);
    }
    _syncToCloud();
  }

  void _saveShift(String value, bool isPDF) {
    if (isPDF) {
      pdfShift = value;
      LocalStorageService.savePdfShift(value);
    } else {
      excelShift = value;
      LocalStorageService.saveExcelShift(value);
    }
    _syncToCloud();
  }

  void _saveGlobalNotice(String value) {
    globalNotice = value;
    LocalStorageService.saveGlobalNotice(value);
    _syncToCloud();
  }

  void _saveProfessionCards() {
    LocalStorageService.saveProfessionCards(professionCards);
    _syncToCloud();
  }

  void _saveExcelFields() {
    LocalStorageService.saveExcelSpecificFields({
      'comments': comments,
      'extraWork': extraWork,
    });
    _syncToCloud();
  }

  void _saveShiftNotes() {
    LocalStorageService.saveShiftNotes(shiftNotes);
    _syncToCloud();
  }

  // Sync all data to cloud
  Future<void> _syncToCloud() async {
    if (!SupabaseService.isLoggedIn) return;
    
    try {
      // Save work cards
      await SupabaseService.saveWorkCards(professionCards);
      
      // Save user settings
      await SupabaseService.saveUserSettings(
        pdfSupervisor: pdfSupervisor,
        pdfDate: pdfDate,
        pdfShift: pdfShift,
        excelSupervisor: excelSupervisor,
        excelDate: excelDate,
        excelShift: excelShift,
        globalNotice: globalNotice,
        shiftNotes: shiftNotes,
        comments: comments,
        extraWork: extraWork,
      );
    } catch (e) {
      print('Failed to sync to cloud: $e');
      // Show error to user if needed
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: ${e.toString()}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Työkorttisovellus'),
            const SizedBox(width: 8),
            // Authentication status indicator
            if (SupabaseService.isLoggedIn)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_done, size: 16, color: Colors.green.shade700),
                    const SizedBox(width: 4),
                    Text(
                      'Synced',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off, size: 16, color: Colors.orange.shade700),
                    const SizedBox(width: 4),
                    Text(
                      'Local',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
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
          const SizedBox(width: 8), // Add spacing between clear and export buttons
          // PDF Export
          IconButton(
            onPressed: _exportPDF,
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export PDF',
          ),
          // Excel Export
          IconButton(
            onPressed: _exportExcel,
            icon: const Icon(Icons.table_chart),
            tooltip: 'Export Excel',
          ),
          // Authentication button
          if (SupabaseService.isLoggedIn)
            PopupMenuButton<String>(
              icon: const Icon(Icons.account_circle),
              tooltip: 'Account',
              onSelected: (value) {
                if (value == 'logout') {
                  _confirmLogout();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'info',
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        SupabaseService.currentUser?.email ?? 'User',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'Logged in • Data synced',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout),
                      SizedBox(width: 8),
                      Text('Sign Out'),
                    ],
                  ),
                ),
              ],
            )
          else
            IconButton(
              onPressed: widget.onShowAuth,
              icon: const Icon(Icons.login),
              tooltip: 'Sign In to Sync',
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

    for (int i = 0; i < fieldsToShow; i++) {
      fields.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: i < shiftNotes.length ? shiftNotes[i] : ''),
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

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text(
            'Are you sure you want to sign out?\n\nYour data will remain saved in the cloud and you can sign back in anytime.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      try {
        await SupabaseService.signOut();
        setState(() {});
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Signed out successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to sign out: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
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

  ProfessionCardData({
    this.professionName = '',
    this.pdfName1 = '',
    this.pdfName2 = '',
    this.excelName1 = '',
    this.excelName2 = '',
    this.tasks = const [],
    this.equipment = '',
    this.equipmentLocation = '',
  }) {
    if (tasks.isEmpty) {
      tasks = [TaskData()];
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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/info_input_row.dart';
import '../widgets/global_notice_field.dart';
import '../widgets/profession_card.dart';
import '../widgets/excel_specific_fields.dart';
import '../screens/settings_screen.dart';
import '../services/local_storage_service.dart';
import '../services/excel_service.dart';
import '../services/pdf_service.dart';

class WorkCardScreen extends StatefulWidget {
  final ValueChanged<bool> onThemeChanged;

  const WorkCardScreen({super.key, required this.onThemeChanged});

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Load saved data
    _loadData();
  }

  Future<void> _loadData() async {
    // Load all data from local storage
    pdfSupervisor = await LocalStorageService.loadSupervisor();
    pdfDate = await LocalStorageService.loadDate();
    pdfShift = await LocalStorageService.loadShift();
    
    excelSupervisor = pdfSupervisor; // Start with same values
    excelDate = pdfDate;
    excelShift = pdfShift;
    
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
    
    setState(() {});
  }

  // Auto-save methods
  void _saveSupervisor(String value, bool isPDF) {
    if (isPDF) {
      pdfSupervisor = value;
    } else {
      excelSupervisor = value;
    }
    LocalStorageService.saveSupervisor(value);
  }

  void _saveDate(String value, bool isPDF) {
    if (isPDF) {
      pdfDate = value;
    } else {
      excelDate = value;
    }
    LocalStorageService.saveDate(value);
  }

  void _saveShift(String value, bool isPDF) {
    if (isPDF) {
      pdfShift = value;
    } else {
      excelShift = value;
    }
    LocalStorageService.saveShift(value);
  }

  void _saveGlobalNotice(String value) {
    globalNotice = value;
    LocalStorageService.saveGlobalNotice(value);
  }

  void _saveProfessionCards() {
    LocalStorageService.saveProfessionCards(professionCards);
  }

  void _saveExcelFields() {
    LocalStorageService.saveExcelSpecificFields({
      'comments': comments,
      'extraWork': extraWork,
    });
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
        title: const Text('Työkorttisovellus'),
        actions: [
          // PDF Export (left)
          IconButton(
            onPressed: _exportPDF,
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export PDF',
          ),
          // Excel Export (center)
          IconButton(
            onPressed: _exportExcel,
            icon: const Icon(Icons.table_chart),
            tooltip: 'Export Excel',
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
              
              // Global Notice (shared) - only show on PDF tab
              AnimatedBuilder(
                animation: _tabController,
                builder: (context, child) {
                  if (_tabController.index == 0) { // PDF tab
                    return GlobalNoticeField(
                      value: globalNotice,
                      onChanged: (value) => setState(() => _saveGlobalNotice(value)),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              
              // Excel-specific fields (only show when Excel tab is active)
              AnimatedBuilder(
                animation: _tabController,
                builder: (context, child) {
                  if (_tabController.index == 1) {
                    return ExcelSpecificFields(
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
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              
              // Profession Cards
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // PDF Tab - Profession cards
                    _buildProfessionCardsList(isPDFTab: true),
                    // Excel Tab - Profession cards  
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
      itemCount: professionCards.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ProfessionCard(
            data: professionCards[index],
            isPDFTab: isPDFTab,
            onDataChanged: (newData) {
              setState(() {
                professionCards[index] = newData;
                _saveProfessionCards();
              });
            },
            onDelete: () {
              setState(() {
                professionCards.removeAt(index);
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
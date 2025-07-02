import 'package:flutter/material.dart';
import '../screens/work_card_screen.dart';
import 'autocomplete_text_field.dart';

class ProfessionCard extends StatefulWidget {
  final ProfessionCardData data;
  final bool isPDFTab;
  final int? tabIndex; // NEW - to differentiate between PDF tabs (0=PDF, 1=PDF2, 2=PDF3, 3=Excel)
  final ValueChanged<ProfessionCardData> onDataChanged;
  final VoidCallback onDelete;

  const ProfessionCard({
    super.key,
    required this.data,
    required this.isPDFTab,
    this.tabIndex,
    required this.onDataChanged,
    required this.onDelete,
  });

  @override
  State<ProfessionCard> createState() => _ProfessionCardState();
}

class _ProfessionCardState extends State<ProfessionCard> {
  bool _isEditing = false;
  late TextEditingController _professionController;
  late TextEditingController _name1Controller;
  late TextEditingController _name2Controller;
  late TextEditingController _equipmentController;
  late TextEditingController _locationController;
  List<TextEditingController> _taskControllers = [];
  List<TextEditingController> _taskNoticeControllers = [];
  List<TextEditingController> _workSiteConditionControllers = [];
  List<TextEditingController> _supervisorRiskNoteControllers = [];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  // Helper methods to get the correct names based on tab
  String _getCurrentName1() {
    if (!widget.isPDFTab) return widget.data.excelName1;
    
    switch (widget.tabIndex) {
      case 0: return widget.data.pdfName1;
      case 1: return widget.data.pdf2Name1;
      case 2: return widget.data.pdf3Name1;
      default: return widget.data.pdfName1;
    }
  }
  
  String _getCurrentName2() {
    if (!widget.isPDFTab) return widget.data.excelName2;
    
    switch (widget.tabIndex) {
      case 0: return widget.data.pdfName2;
      case 1: return widget.data.pdf2Name2;
      case 2: return widget.data.pdf3Name2;
      default: return widget.data.pdfName2;
    }
  }

  void _initializeControllers() {
    _professionController = TextEditingController(text: widget.data.professionName);
    _name1Controller = TextEditingController(text: _getCurrentName1());
    _name2Controller = TextEditingController(text: _getCurrentName2());
    _equipmentController = TextEditingController(text: widget.data.equipment);
    _locationController = TextEditingController(text: widget.data.equipmentLocation);

    // Dispose old task controllers
    for (var controller in _taskControllers) {
      controller.dispose();
    }
    for (var controller in _taskNoticeControllers) {
      controller.dispose();
    }
    for (var controller in _workSiteConditionControllers) {
      controller.dispose();
    }
    for (var controller in _supervisorRiskNoteControllers) {
      controller.dispose();
    }

    _taskControllers = widget.data.tasks
        .map((task) => TextEditingController(text: task.task))
        .toList();
    _taskNoticeControllers = widget.data.tasks
        .map((task) => TextEditingController(text: task.taskNotice))
        .toList();
    _workSiteConditionControllers = widget.data.workSiteConditions
        .map((condition) => TextEditingController(text: condition))
        .toList();
    _supervisorRiskNoteControllers = widget.data.supervisorRiskNotes
        .map((note) => TextEditingController(text: note))
        .toList();
  }

  @override
  void didUpdateWidget(ProfessionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Only update controllers if tab changed or data structure changed
    if (oldWidget.isPDFTab != widget.isPDFTab || 
        oldWidget.tabIndex != widget.tabIndex ||  // ADD THIS LINE - check for tab changes
        oldWidget.data.tasks.length != widget.data.tasks.length ||
        oldWidget.data.workSiteConditions.length != widget.data.workSiteConditions.length ||
        oldWidget.data.supervisorRiskNotes.length != widget.data.supervisorRiskNotes.length) {
      _initializeControllers();
    } else {
      // Update individual controllers only if values actually changed
      _updateControllerIfNeeded(_professionController, widget.data.professionName);
      
      _updateControllerIfNeeded(_name1Controller, _getCurrentName1());
      _updateControllerIfNeeded(_name2Controller, _getCurrentName2());
      _updateControllerIfNeeded(_equipmentController, widget.data.equipment);
      _updateControllerIfNeeded(_locationController, widget.data.equipmentLocation);
      
      // Update task controllers
      for (int i = 0; i < widget.data.tasks.length; i++) {
        if (i < _taskControllers.length) {
          _updateControllerIfNeeded(_taskControllers[i], widget.data.tasks[i].task);
        }
        if (i < _taskNoticeControllers.length) {
          _updateControllerIfNeeded(_taskNoticeControllers[i], widget.data.tasks[i].taskNotice);
        }
      }
      
      // Update work site condition controllers
      for (int i = 0; i < widget.data.workSiteConditions.length; i++) {
        if (i < _workSiteConditionControllers.length) {
          _updateControllerIfNeeded(_workSiteConditionControllers[i], widget.data.workSiteConditions[i]);
        }
      }
      
      // Update supervisor risk note controllers
      for (int i = 0; i < widget.data.supervisorRiskNotes.length; i++) {
        if (i < _supervisorRiskNoteControllers.length) {
          _updateControllerIfNeeded(_supervisorRiskNoteControllers[i], widget.data.supervisorRiskNotes[i]);
        }
      }
    }
  }

  void _updateControllerIfNeeded(TextEditingController controller, String newValue) {
    if (controller.text != newValue) {
      final cursorPos = controller.selection.baseOffset;
      controller.text = newValue;
      controller.selection = TextSelection.fromPosition(
        TextPosition(offset: cursorPos.clamp(0, newValue.length)),
      );
    }
  }

  @override
  void dispose() {
    _professionController.dispose();
    _name1Controller.dispose();
    _name2Controller.dispose();
    _equipmentController.dispose();
    _locationController.dispose();
    for (var controller in _taskControllers) {
      controller.dispose();
    }
    for (var controller in _taskNoticeControllers) {
      controller.dispose();
    }
    for (var controller in _workSiteConditionControllers) {
      controller.dispose();
    }
    for (var controller in _supervisorRiskNoteControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: _isEditing ? _buildEditMode() : _buildDisplayMode(),
      ),
    );
  }

  Widget _buildDisplayMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with profession name and action buttons
        Row(
          children: [
            Expanded(
              child: Text(
                widget.data.professionName.isEmpty ? 'Nimetön aselaji' : widget.data.professionName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            // Edit button with background
            Container(
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: IconButton(
                onPressed: () => setState(() => _isEditing = true),
                icon: const Icon(Icons.edit, size: 20),
                color: Colors.blue.shade700,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ),
            const SizedBox(width: 8),
            // Delete button with background
            Container(
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: IconButton(
                onPressed: _confirmDelete,
                icon: const Icon(Icons.delete, size: 20),
                color: Colors.red.shade700,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ),
          ],
        ),
        
        if (widget.data.pdfName1.isNotEmpty || widget.data.pdfName2.isNotEmpty || 
            widget.data.excelName1.isNotEmpty || widget.data.excelName2.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Names: ${_getDisplayNames()}',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
        
        if (_hasAnyTasks()) ...[
          const SizedBox(height: 4),
          const Text(
            'Tehtävä:',
            style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          ..._getTasksDisplayVertical(),
        ],
        
        if (_hasAnyWorkSiteConditions()) ...[
          const SizedBox(height: 4),
          const Text(
            'Työkohteen tämänhetkinen tila:',
            style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          ..._getWorkSiteConditionsDisplayVertical(),
        ],
        
        if (_hasAnySupervisorRiskNotes()) ...[
          const SizedBox(height: 4),
          const Text(
            'Työnjohtajan huomiot riskeistä:',
            style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          ..._getSupervisorRiskNotesDisplayVertical(),
        ],
        
        if (!widget.isPDFTab && (widget.data.equipment.isNotEmpty || widget.data.equipmentLocation.isNotEmpty)) ...[
          const SizedBox(height: 4),
          Text(
            'Kone: ${_getEquipmentDisplay()}',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ],
    );
  }

  Widget _buildEditMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with profession name and action buttons
        Row(
          children: [
            Expanded(
              child: AutocompleteTextField(
                controller: _professionController,
                hintText: 'Aselaji',
                onChanged: (value) => _updateProfessionName(value),
                isProfession: true,
                decoration: const InputDecoration(
                  hintText: 'Aselaji',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Save button with background
            Container(
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: IconButton(
                onPressed: () => setState(() => _isEditing = false),
                icon: const Icon(Icons.check, size: 20),
                color: Colors.green.shade700,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ),
            const SizedBox(width: 8),
            // Delete button with background
            Container(
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: IconButton(
                onPressed: _confirmDelete,
                icon: const Icon(Icons.delete, size: 20),
                color: Colors.red.shade700,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Names row (side by side) - now with autocomplete
        Row(
          children: [
            Expanded(
              child: AutocompleteTextField(
                controller: _name1Controller,
                hintText: widget.isPDFTab ? 'PDF Name 1' : 'Excel Name 1',
                onChanged: (value) => _updateNames(value, _name2Controller.text),
                decoration: InputDecoration(
                  hintText: widget.isPDFTab ? 'PDF Name 1' : 'Excel Name 1',
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AutocompleteTextField(
                controller: _name2Controller,
                hintText: widget.isPDFTab ? 'PDF Name 2' : 'Excel Name 2',
                onChanged: (value) => _updateNames(_name1Controller.text, value),
                decoration: InputDecoration(
                  hintText: widget.isPDFTab ? 'PDF Name 2' : 'Excel Name 2',
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Tasks section
        _buildTasksSection(),
        const SizedBox(height: 8),
        
        // Work Site Conditions section
        _buildWorkSiteConditionsSection(),
        const SizedBox(height: 8),
        
        // Supervisor Risk Notes section
        _buildSupervisorRiskNotesSection(),
        const SizedBox(height: 8),
        
        // Equipment section - only show on Excel tab
        if (!widget.isPDFTab) _buildEquipmentSection(),
      ],
    );
  }

  Future<void> _confirmDelete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Poista aselaji'),
          content: Text(
            widget.data.professionName.isEmpty 
                ? 'Haluatko varmasti poistaa tämän aselaji kortin?'
                : 'Haluatko varmasti poistaa "${widget.data.professionName}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Peruuta'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Poista'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      widget.onDelete();
    }
  }

  String _getDisplayNames() {
    if (widget.isPDFTab) {
      return [_getCurrentName1(), _getCurrentName2()]
          .where((name) => name.isNotEmpty)
          .join(', ');
    } else {
      return [widget.data.excelName1, widget.data.excelName2]
          .where((name) => name.isNotEmpty)
          .join(', ');
    }
  }

  bool _hasAnyTasks() {
    return widget.data.tasks.any((task) => task.task.isNotEmpty || task.taskNotice.isNotEmpty);
  }

  List<Widget> _getTasksDisplayVertical() {
    return widget.data.tasks
        .where((task) => task.task.isNotEmpty)
        .map((task) => Text(
          task.taskNotice.isNotEmpty ? '${task.task} - ${task.taskNotice}' : task.task,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ))
        .toList();
  }

  bool _hasAnyWorkSiteConditions() {
    return widget.data.workSiteConditions.any((condition) => condition.isNotEmpty);
  }

  List<Widget> _getWorkSiteConditionsDisplayVertical() {
    return widget.data.workSiteConditions
        .where((condition) => condition.isNotEmpty)
        .map((condition) => Text(
          condition,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ))
        .toList();
  }

  bool _hasAnySupervisorRiskNotes() {
    return widget.data.supervisorRiskNotes.any((note) => note.isNotEmpty);
  }

  List<Widget> _getSupervisorRiskNotesDisplayVertical() {
    return widget.data.supervisorRiskNotes
        .where((note) => note.isNotEmpty)
        .map((note) => Text(
          note,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ))
        .toList();
  }

  String _getEquipmentDisplay() {
    if (widget.data.equipment.isNotEmpty && widget.data.equipmentLocation.isNotEmpty) {
      return '${widget.data.equipment} - ${widget.data.equipmentLocation}';
    } else if (widget.data.equipment.isNotEmpty) {
      return widget.data.equipment;
    } else if (widget.data.equipmentLocation.isNotEmpty) {
      return widget.data.equipmentLocation;
    }
    return '';
  }

  Widget _buildTasksSection() {
    // Auto-expanding logic: find last non-empty task
    int lastNonEmpty = -1;
    for (int i = 0; i < widget.data.tasks.length; i++) {
      if (widget.data.tasks[i].task.isNotEmpty || widget.data.tasks[i].taskNotice.isNotEmpty) {
        lastNonEmpty = i;
      }
    }
    
    // Show (lastNonEmpty + 2) fields, minimum 1, maximum 4
    int fieldsToShow = (lastNonEmpty + 2).clamp(1, 4);
    
    // Ensure we have enough tasks in the data structure
    while (widget.data.tasks.length < fieldsToShow) {
      _addTaskToData();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tehtävä',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        // Show only the calculated number of fields
        ...List.generate(fieldsToShow, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: index < _taskControllers.length ? _taskControllers[index] : null,
                    onChanged: (value) {
                      _updateTask(index, value, 
                          index < _taskNoticeControllers.length ? _taskNoticeControllers[index].text : '');
                      // Auto-expand when typing in the last visible field
                      if (index == fieldsToShow - 1 && value.isNotEmpty && fieldsToShow < 4) {
                        setState(() {}); // Trigger rebuild to show next field
                      }
                    },
                    decoration: const InputDecoration(
                      hintText: 'Tehtävä',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Text('-', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: index < _taskNoticeControllers.length ? _taskNoticeControllers[index] : null,
                    onChanged: (value) {
                      _updateTask(index, 
                          index < _taskControllers.length ? _taskControllers[index].text : '', value);
                      // Auto-expand when typing in the last visible field
                      if (index == fieldsToShow - 1 && value.isNotEmpty && fieldsToShow < 4) {
                        setState(() {}); // Trigger rebuild to show next field
                      }
                    },
                    decoration: const InputDecoration(
                      hintText: 'Lisätieto',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // Helper method to add task to data structure without triggering UI rebuild
  void _addTaskToData() {
    if (widget.data.tasks.length < 4) {
      widget.data.tasks.add(TaskData());
      // Add corresponding controllers
      _taskControllers.add(TextEditingController());
      _taskNoticeControllers.add(TextEditingController());
    }
  }

  Widget _buildEquipmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kone',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: AutocompleteTextField(
                controller: _equipmentController,
                hintText: 'Kone',
                onChanged: (value) => _updateEquipment(value, _locationController.text),
                isEquipment: true,
                decoration: const InputDecoration(
                  hintText: 'Kone',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Text('-', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _locationController,
                onChanged: (value) => _updateEquipment(_equipmentController.text, value),
                decoration: const InputDecoration(
                  hintText: 'Koneen sijainti',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _updateProfessionName(String value) {
    final newData = ProfessionCardData(
      professionName: value,
      pdfName1: widget.data.pdfName1,
      pdfName2: widget.data.pdfName2,
      excelName1: widget.data.excelName1,
      excelName2: widget.data.excelName2,
      tasks: widget.data.tasks,
      equipment: widget.data.equipment,
      equipmentLocation: widget.data.equipmentLocation,
      workSiteConditions: widget.data.workSiteConditions,
      supervisorRiskNotes: widget.data.supervisorRiskNotes,
    );
    widget.onDataChanged(newData);
  }

  void _updateNames(String name1, String name2) {
    // Determine which names to update based on tab
    String pdfName1 = widget.data.pdfName1;
    String pdfName2 = widget.data.pdfName2;
    String pdf2Name1 = widget.data.pdf2Name1;
    String pdf2Name2 = widget.data.pdf2Name2;
    String pdf3Name1 = widget.data.pdf3Name1;
    String pdf3Name2 = widget.data.pdf3Name2;
    String excelName1 = widget.data.excelName1;
    String excelName2 = widget.data.excelName2;
    
    if (widget.isPDFTab) {
      switch (widget.tabIndex) {
        case 0: // PDF tab
          pdfName1 = name1;
          pdfName2 = name2;
          break;
        case 1: // PDF2 tab
          pdf2Name1 = name1;
          pdf2Name2 = name2;
          break;
        case 2: // PDF3 tab
          pdf3Name1 = name1;
          pdf3Name2 = name2;
          break;
      }
    } else {
      // Excel tab
      excelName1 = name1;
      excelName2 = name2;
    }
    
    final newData = ProfessionCardData(
      professionName: widget.data.professionName,
      pdfName1: pdfName1,
      pdfName2: pdfName2,
      pdf2Name1: pdf2Name1,
      pdf2Name2: pdf2Name2,
      pdf3Name1: pdf3Name1,
      pdf3Name2: pdf3Name2,
      excelName1: excelName1,
      excelName2: excelName2,
      tasks: widget.data.tasks,
      equipment: widget.data.equipment,
      equipmentLocation: widget.data.equipmentLocation,
      workSiteConditions: widget.data.workSiteConditions,
      supervisorRiskNotes: widget.data.supervisorRiskNotes,
    );
    widget.onDataChanged(newData);
  }

  void _updateTask(int index, String task, String taskNotice) {
    final newTasks = List<TaskData>.from(widget.data.tasks);
    newTasks[index] = TaskData(task: task, taskNotice: taskNotice);
    final newData = ProfessionCardData(
      professionName: widget.data.professionName,
      pdfName1: widget.data.pdfName1,
      pdfName2: widget.data.pdfName2,
      pdf2Name1: widget.data.pdf2Name1,
      pdf2Name2: widget.data.pdf2Name2,
      pdf3Name1: widget.data.pdf3Name1,
      pdf3Name2: widget.data.pdf3Name2,
      excelName1: widget.data.excelName1,
      excelName2: widget.data.excelName2,
      tasks: newTasks,
      equipment: widget.data.equipment,
      equipmentLocation: widget.data.equipmentLocation,
      workSiteConditions: widget.data.workSiteConditions,
      supervisorRiskNotes: widget.data.supervisorRiskNotes,
    );
    widget.onDataChanged(newData);
  }

  void _updateEquipment(String equipment, String location) {
    final newData = ProfessionCardData(
      professionName: widget.data.professionName,
      pdfName1: widget.data.pdfName1,
      pdfName2: widget.data.pdfName2,
      pdf2Name1: widget.data.pdf2Name1,
      pdf2Name2: widget.data.pdf2Name2,
      pdf3Name1: widget.data.pdf3Name1,
      pdf3Name2: widget.data.pdf3Name2,
      excelName1: widget.data.excelName1,
      excelName2: widget.data.excelName2,
      tasks: widget.data.tasks,
      equipment: equipment,
      equipmentLocation: location,
      workSiteConditions: widget.data.workSiteConditions,
      supervisorRiskNotes: widget.data.supervisorRiskNotes,
    );
    widget.onDataChanged(newData);
  }

  Widget _buildWorkSiteConditionsSection() {
    // Auto-expanding logic: find last non-empty condition
    int lastNonEmpty = -1;
    for (int i = 0; i < widget.data.workSiteConditions.length; i++) {
      if (widget.data.workSiteConditions[i].isNotEmpty) {
        lastNonEmpty = i;
      }
    }
    
    // Show (lastNonEmpty + 2) fields, minimum 1, maximum 3
    int fieldsToShow = (lastNonEmpty + 2).clamp(1, 3);
    
    // Ensure we have enough conditions in the data structure
    while (widget.data.workSiteConditions.length < fieldsToShow) {
      _addWorkSiteConditionToData();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Työkohteen tämänhetkinen tila',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        // Show only the calculated number of fields
        ...List.generate(fieldsToShow, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: TextField(
              key: ValueKey('work_site_condition_$index'),
              controller: index < _workSiteConditionControllers.length ? _workSiteConditionControllers[index] : null,
              onChanged: (value) {
                _updateWorkSiteCondition(index, value);
                // Auto-expand when typing in the last visible field
                if (index == fieldsToShow - 1 && value.isNotEmpty && fieldsToShow < 3) {
                  setState(() {}); // Trigger rebuild to show next field
                }
              },
              textDirection: TextDirection.ltr, // Ensure left-to-right text direction
              decoration: InputDecoration(
                hintText: 'Työkohteen tila ${index + 1}',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                isDense: true,
              ),
            ),
          );
        }),
      ],
    );
  }

  // Helper method to add work site condition to data structure
  void _addWorkSiteConditionToData() {
    if (widget.data.workSiteConditions.length < 3) {
      widget.data.workSiteConditions.add('');
      // Add corresponding controller
      _workSiteConditionControllers.add(TextEditingController());
    }
  }

  void _updateWorkSiteCondition(int index, String value) {
    // Ensure list is large enough
    while (widget.data.workSiteConditions.length <= index) {
      widget.data.workSiteConditions.add('');
    }
    
    final newWorkSiteConditions = List<String>.from(widget.data.workSiteConditions);
    newWorkSiteConditions[index] = value;
    
    final newData = ProfessionCardData(
      professionName: widget.data.professionName,
      pdfName1: widget.data.pdfName1,
      pdfName2: widget.data.pdfName2,
      pdf2Name1: widget.data.pdf2Name1,
      pdf2Name2: widget.data.pdf2Name2,
      pdf3Name1: widget.data.pdf3Name1,
      pdf3Name2: widget.data.pdf3Name2,
      excelName1: widget.data.excelName1,
      excelName2: widget.data.excelName2,
      tasks: widget.data.tasks,
      equipment: widget.data.equipment,
      equipmentLocation: widget.data.equipmentLocation,
      workSiteConditions: newWorkSiteConditions,
      supervisorRiskNotes: widget.data.supervisorRiskNotes,
    );
    widget.onDataChanged(newData);
  }

  Widget _buildSupervisorRiskNotesSection() {
    // Auto-expanding logic: find last non-empty note
    int lastNonEmpty = -1;
    for (int i = 0; i < widget.data.supervisorRiskNotes.length; i++) {
      if (widget.data.supervisorRiskNotes[i].isNotEmpty) {
        lastNonEmpty = i;
      }
    }
    
    // Show (lastNonEmpty + 2) fields, minimum 1, maximum 3
    int fieldsToShow = (lastNonEmpty + 2).clamp(1, 3);
    
    // Ensure we have enough notes in the data structure
    while (widget.data.supervisorRiskNotes.length < fieldsToShow) {
      _addSupervisorRiskNoteToData();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Työnjohtajan huomiot riskeistä',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        // Show only the calculated number of fields
        ...List.generate(fieldsToShow, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: TextField(
              key: ValueKey('supervisor_risk_note_$index'),
              controller: index < _supervisorRiskNoteControllers.length ? _supervisorRiskNoteControllers[index] : null,
              onChanged: (value) {
                _updateSupervisorRiskNote(index, value);
                // Auto-expand when typing in the last visible field
                if (index == fieldsToShow - 1 && value.isNotEmpty && fieldsToShow < 3) {
                  setState(() {}); // Trigger rebuild to show next field
                }
              },
              textDirection: TextDirection.ltr, // Ensure left-to-right text direction
              decoration: InputDecoration(
                hintText: 'Riskihuomio ${index + 1}',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                isDense: true,
              ),
            ),
          );
        }),
      ],
    );
  }

  // Helper method to add supervisor risk note to data structure
  void _addSupervisorRiskNoteToData() {
    if (widget.data.supervisorRiskNotes.length < 3) {
      widget.data.supervisorRiskNotes.add('');
      // Add corresponding controller
      _supervisorRiskNoteControllers.add(TextEditingController());
    }
  }

  void _updateSupervisorRiskNote(int index, String value) {
    // Ensure list is large enough
    while (widget.data.supervisorRiskNotes.length <= index) {
      widget.data.supervisorRiskNotes.add('');
    }
    
    final newSupervisorRiskNotes = List<String>.from(widget.data.supervisorRiskNotes);
    newSupervisorRiskNotes[index] = value;
    
    final newData = ProfessionCardData(
      professionName: widget.data.professionName,
      pdfName1: widget.data.pdfName1,
      pdfName2: widget.data.pdfName2,
      pdf2Name1: widget.data.pdf2Name1,
      pdf2Name2: widget.data.pdf2Name2,
      pdf3Name1: widget.data.pdf3Name1,
      pdf3Name2: widget.data.pdf3Name2,
      excelName1: widget.data.excelName1,
      excelName2: widget.data.excelName2,
      tasks: widget.data.tasks,
      equipment: widget.data.equipment,
      equipmentLocation: widget.data.equipmentLocation,
      workSiteConditions: widget.data.workSiteConditions,
      supervisorRiskNotes: newSupervisorRiskNotes,
    );
    widget.onDataChanged(newData);
  }
} 
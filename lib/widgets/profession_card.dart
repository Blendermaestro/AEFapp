import 'package:flutter/material.dart';
import '../screens/work_card_screen.dart';
import 'autocomplete_text_field.dart';

class ProfessionCard extends StatefulWidget {
  final ProfessionCardData data;
  final bool isPDFTab;
  final ValueChanged<ProfessionCardData> onDataChanged;
  final VoidCallback onDelete;

  const ProfessionCard({
    super.key,
    required this.data,
    required this.isPDFTab,
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

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _professionController = TextEditingController(text: widget.data.professionName);
    _name1Controller = TextEditingController(
      text: widget.isPDFTab ? widget.data.pdfName1 : widget.data.excelName1,
    );
    _name2Controller = TextEditingController(
      text: widget.isPDFTab ? widget.data.pdfName2 : widget.data.excelName2,
    );
    _equipmentController = TextEditingController(text: widget.data.equipment);
    _locationController = TextEditingController(text: widget.data.equipmentLocation);

    // Dispose old task controllers
    for (var controller in _taskControllers) {
      controller.dispose();
    }
    for (var controller in _taskNoticeControllers) {
      controller.dispose();
    }

    _taskControllers = widget.data.tasks
        .map((task) => TextEditingController(text: task.task))
        .toList();
    _taskNoticeControllers = widget.data.tasks
        .map((task) => TextEditingController(text: task.taskNotice))
        .toList();
  }

  @override
  void didUpdateWidget(ProfessionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Only update controllers if tab changed or data structure changed
    if (oldWidget.isPDFTab != widget.isPDFTab || 
        oldWidget.data.tasks.length != widget.data.tasks.length) {
      _initializeControllers();
    } else {
      // Update individual controllers only if values actually changed
      _updateControllerIfNeeded(_professionController, widget.data.professionName);
      
      final currentName1 = widget.isPDFTab ? widget.data.pdfName1 : widget.data.excelName1;
      final currentName2 = widget.isPDFTab ? widget.data.pdfName2 : widget.data.excelName2;
      _updateControllerIfNeeded(_name1Controller, currentName1);
      _updateControllerIfNeeded(_name2Controller, currentName2);
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
      return [widget.data.pdfName1, widget.data.pdfName2]
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
    );
    widget.onDataChanged(newData);
  }

  void _updateNames(String name1, String name2) {
    final newData = ProfessionCardData(
      professionName: widget.data.professionName,
      pdfName1: widget.isPDFTab ? name1 : widget.data.pdfName1,
      pdfName2: widget.isPDFTab ? name2 : widget.data.pdfName2,
      excelName1: !widget.isPDFTab ? name1 : widget.data.excelName1,
      excelName2: !widget.isPDFTab ? name2 : widget.data.excelName2,
      tasks: widget.data.tasks,
      equipment: widget.data.equipment,
      equipmentLocation: widget.data.equipmentLocation,
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
      excelName1: widget.data.excelName1,
      excelName2: widget.data.excelName2,
      tasks: newTasks,
      equipment: widget.data.equipment,
      equipmentLocation: widget.data.equipmentLocation,
    );
    widget.onDataChanged(newData);
  }

  void _updateEquipment(String equipment, String location) {
    final newData = ProfessionCardData(
      professionName: widget.data.professionName,
      pdfName1: widget.data.pdfName1,
      pdfName2: widget.data.pdfName2,
      excelName1: widget.data.excelName1,
      excelName2: widget.data.excelName2,
      tasks: widget.data.tasks,
      equipment: equipment,
      equipmentLocation: location,
    );
    widget.onDataChanged(newData);
  }
} 
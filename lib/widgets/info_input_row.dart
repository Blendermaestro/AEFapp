import 'package:flutter/material.dart';
import '../screens/work_card_screen.dart';
import 'autocomplete_text_field.dart';

class InfoInputRow extends StatefulWidget {
  final String supervisor;
  final String date;
  final String shift;
  final List<ProfessionCardData> professionCards;
  final bool isPDFTab;
  final ValueChanged<String> onSupervisorChanged;
  final ValueChanged<String> onDateChanged;
  final ValueChanged<String> onShiftChanged;

  const InfoInputRow({
    super.key,
    required this.supervisor,
    required this.date,
    required this.shift,
    required this.professionCards,
    required this.isPDFTab,
    required this.onSupervisorChanged,
    required this.onDateChanged,
    required this.onShiftChanged,
  });

  @override
  State<InfoInputRow> createState() => _InfoInputRowState();
}

class _InfoInputRowState extends State<InfoInputRow> {
  late TextEditingController _supervisorController;
  late TextEditingController _dateController;
  late TextEditingController _shiftController;

  @override
  void initState() {
    super.initState();
    _supervisorController = TextEditingController(text: widget.supervisor);
    
    // Set current date if date is empty
    final currentDate = widget.date.isEmpty ? _getCurrentDateString() : widget.date;
    _dateController = TextEditingController(text: currentDate);
    
    // Auto-set current date if empty
    if (widget.date.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onDateChanged(currentDate);
      });
    }
    
    _shiftController = TextEditingController(text: widget.shift);
  }

  String _getCurrentDateString() {
    final now = DateTime.now();
    return '${now.day}.${now.month}.${now.year}';
  }

  int _calculateManpowerCount() {
    int count = 0;
    for (final card in widget.professionCards) {
      if (widget.isPDFTab) {
        if (card.pdfName1.isNotEmpty) count++;
        if (card.pdfName2.isNotEmpty) count++;
      } else {
        if (card.excelName1.isNotEmpty) count++;
        if (card.excelName2.isNotEmpty) count++;
      }
    }
    return count;
  }

  @override
  void didUpdateWidget(InfoInputRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Only update controllers if the values are significantly different
    // and avoid updates during active typing
    if (widget.supervisor != oldWidget.supervisor && 
        widget.supervisor != _supervisorController.text) {
      _supervisorController.text = widget.supervisor;
    }
    
    if (widget.date != oldWidget.date && 
        widget.date != _dateController.text) {
      _dateController.text = widget.date;
    }
    
    if (widget.shift != oldWidget.shift && 
        widget.shift != _shiftController.text) {
      _shiftController.text = widget.shift;
    }
  }

  @override
  void dispose() {
    _supervisorController.dispose();
    _dateController.dispose();
    _shiftController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          // Supervisor - now with autocomplete
          Expanded(
            child: AutocompleteTextField(
              controller: _supervisorController,
              hintText: 'TJ',
              onChanged: widget.onSupervisorChanged,
              isSupervisor: true,
              decoration: const InputDecoration(
                labelText: 'TJ',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          
          // Date input
          Expanded(
            child: InkWell(
              onTap: () => _selectDate(context),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.grey.shade600 
                      : Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.date.isEmpty ? 'Valitse päivämäärä' : widget.date,
                        style: TextStyle(
                          fontSize: 16,
                          color: widget.date.isEmpty 
                              ? Theme.of(context).hintColor
                              : Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          
          // Shift input
          Expanded(
            child: AutocompleteTextField(
              controller: _shiftController,
              hintText: 'Vuoro',
              onChanged: widget.onShiftChanged,
              isShift: true,
              decoration: const InputDecoration(
                labelText: 'Vuoro',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          
          // Manpower Count - simplified
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.grey.shade600 
                  : Colors.grey.shade400),
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Text(
              '${_calculateManpowerCount()}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      widget.onDateChanged('${picked.day}.${picked.month}.${picked.year}');
    }
  }
} 
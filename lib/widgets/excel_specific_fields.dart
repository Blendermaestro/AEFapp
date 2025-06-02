import 'package:flutter/material.dart';

class ExcelSpecificFields extends StatefulWidget {
  final List<String> comments;
  final List<String> extraWork;
  final ValueChanged<List<String>> onCommentsChanged;
  final ValueChanged<List<String>> onExtraWorkChanged;

  const ExcelSpecificFields({
    super.key,
    required this.comments,
    required this.extraWork,
    required this.onCommentsChanged,
    required this.onExtraWorkChanged,
  });

  @override
  State<ExcelSpecificFields> createState() => _ExcelSpecificFieldsState();
}

class _ExcelSpecificFieldsState extends State<ExcelSpecificFields> {
  List<TextEditingController> _commentControllers = [];
  List<TextEditingController> _extraWorkControllers = [];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void didUpdateWidget(ExcelSpecificFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.comments.length != widget.comments.length ||
        oldWidget.extraWork.length != widget.extraWork.length) {
      _initializeControllers();
    }
  }

  void _initializeControllers() {
    // Dispose old controllers
    for (var controller in _commentControllers) {
      controller.dispose();
    }
    for (var controller in _extraWorkControllers) {
      controller.dispose();
    }

    // Create new controllers
    _commentControllers = widget.comments
        .map((comment) => TextEditingController(text: comment))
        .toList();
    _extraWorkControllers = widget.extraWork
        .map((work) => TextEditingController(text: work))
        .toList();
  }

  @override
  void dispose() {
    for (var controller in _commentControllers) {
      controller.dispose();
    }
    for (var controller in _extraWorkControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Comments Section - removed header row
          ..._buildCommentFields(),
          const SizedBox(height: 8),

          // Extra Work Section - removed header row
          ..._buildExtraWorkFields(),
        ],
      ),
    );
  }

  List<Widget> _buildCommentFields() {
    List<Widget> fields = [];
    int lastNonEmpty = _getLastNonEmptyIndex(widget.comments);
    int fieldsToShow = (lastNonEmpty + 2).clamp(1, 3); // Show at least 1, at most 3

    for (int i = 0; i < fieldsToShow; i++) {
      fields.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: i < _commentControllers.length ? _commentControllers[i] : null,
                  onChanged: (value) => _updateComment(i, value),
                  decoration: InputDecoration(
                    hintText: 'Erityishuomio ${i + 1}',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    isDense: true,
                  ),
                ),
              ),
              if (i == fieldsToShow - 1 && _getLastNonEmptyIndex(widget.comments) < 2)
                IconButton(
                  onPressed: _addComment,
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

  List<Widget> _buildExtraWorkFields() {
    List<Widget> fields = [];
    int lastNonEmpty = _getLastNonEmptyIndex(widget.extraWork);
    int fieldsToShow = (lastNonEmpty + 2).clamp(1, 3); // Show at least 1, at most 3

    for (int i = 0; i < fieldsToShow; i++) {
      fields.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: i < _extraWorkControllers.length ? _extraWorkControllers[i] : null,
                  onChanged: (value) => _updateExtraWork(i, value),
                  decoration: InputDecoration(
                    hintText: 'Lisätyö ${i + 1}',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    isDense: true,
                  ),
                ),
              ),
              if (i == fieldsToShow - 1 && _getLastNonEmptyIndex(widget.extraWork) < 2)
                IconButton(
                  onPressed: _addExtraWork,
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

  int _getLastNonEmptyIndex(List<String> list) {
    for (int i = list.length - 1; i >= 0; i--) {
      if (list[i].isNotEmpty) {
        return i;
      }
    }
    return -1; // All empty
  }

  void _addComment() {
    if (widget.comments.length < 3) {
      final newComments = List<String>.from(widget.comments)..add('');
      widget.onCommentsChanged(newComments);
    }
  }

  void _addExtraWork() {
    if (widget.extraWork.length < 3) {
      final newExtraWork = List<String>.from(widget.extraWork)..add('');
      widget.onExtraWorkChanged(newExtraWork);
    }
  }

  void _updateComment(int index, String value) {
    // Ensure list is large enough
    while (widget.comments.length <= index) {
      widget.comments.add('');
    }
    
    final newComments = List<String>.from(widget.comments);
    newComments[index] = value;
    widget.onCommentsChanged(newComments);
  }

  void _updateExtraWork(int index, String value) {
    // Ensure list is large enough
    while (widget.extraWork.length <= index) {
      widget.extraWork.add('');
    }
    
    final newExtraWork = List<String>.from(widget.extraWork);
    newExtraWork[index] = value;
    widget.onExtraWorkChanged(newExtraWork);
  }
} 
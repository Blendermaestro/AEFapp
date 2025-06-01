import 'package:flutter/material.dart';

class GlobalNoticeField extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const GlobalNoticeField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<GlobalNoticeField> createState() => _GlobalNoticeFieldState();
}

class _GlobalNoticeFieldState extends State<GlobalNoticeField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(GlobalNoticeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Only update if values are different and avoid updates during typing
    if (widget.value != oldWidget.value && 
        widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        decoration: const InputDecoration(
          hintText: 'Yleinen huomio, tulostuu jokaiseen korttiin',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          isDense: true,
        ),
      ),
    );
  }
} 
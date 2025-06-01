import 'package:flutter/material.dart';
import '../screens/settings_screen.dart';

class AutocompleteTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final bool isEquipment;
  final bool isSupervisor;
  final bool isShift;
  final bool isProfession;
  final InputDecoration? decoration;

  const AutocompleteTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.isEquipment = false,
    this.isSupervisor = false,
    this.isShift = false,
    this.isProfession = false,
    this.decoration,
  });

  @override
  State<AutocompleteTextField> createState() => _AutocompleteTextFieldState();
}

class _AutocompleteTextFieldState extends State<AutocompleteTextField> {
  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          // For shifts, show all options even when empty
          if (widget.isShift) {
            return getShiftSuggestions('');
          }
          return const Iterable<String>.empty();
        }
        
        // Get suggestions based on field type
        if (widget.isShift) {
          return getShiftSuggestions(textEditingValue.text);
        } else if (widget.isSupervisor) {
          return getSupervisorSuggestions(textEditingValue.text);
        } else if (widget.isEquipment) {
          return getEquipmentSuggestions(textEditingValue.text);
        } else if (widget.isProfession) {
          return getProfessionSuggestions(textEditingValue.text);
        } else {
          return getNameSuggestions(textEditingValue.text);
        }
      },
      onSelected: (String selection) {
        // Use WidgetsBinding to avoid focus conflicts
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.controller.text = selection;
            widget.controller.selection = TextSelection.fromPosition(
              TextPosition(offset: selection.length),
            );
            widget.onChanged(selection);
          }
        });
      },
      fieldViewBuilder: (BuildContext context, TextEditingController fieldController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
        // Sync controllers carefully to avoid conflicts
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && fieldController.text != widget.controller.text) {
            fieldController.text = widget.controller.text;
            if (widget.controller.selection.isValid && 
                widget.controller.selection.end <= fieldController.text.length) {
              fieldController.selection = widget.controller.selection;
            }
          }
        });
        
        return TextField(
          controller: fieldController,
          focusNode: focusNode,
          onChanged: (value) {
            if (mounted) {
              widget.controller.text = value;
              if (fieldController.selection.isValid) {
                widget.controller.selection = fieldController.selection;
              }
              widget.onChanged(value);
            }
          },
          onSubmitted: (value) {
            onFieldSubmitted();
            // For shifts, no need to add to database - it's a fixed list
            if (!widget.isShift && value.trim().isNotEmpty) {
              bool exists;
              if (widget.isSupervisor) {
                exists = supervisorDatabase.contains(value.trim());
              } else if (widget.isEquipment) {
                exists = equipmentDatabase.contains(value.trim());
              } else if (widget.isProfession) {
                exists = professionDatabase.contains(value.trim());
              } else {
                exists = nameDatabase.contains(value.trim());
              }
              
              if (!exists) {
                _showAddToDbDialog(value.trim());
              }
            }
          },
          decoration: widget.decoration ?? InputDecoration(
            hintText: widget.hintText,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            isDense: true,
          ),
        );
      },
      optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final String option = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    title: Text(
                      option,
                      style: const TextStyle(fontSize: 13),
                    ),
                    onTap: () {
                      onSelected(option);
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getBackgroundColor() {
    if (widget.isShift) {
      return Colors.purple.withValues(alpha: 0.1);
    } else if (widget.isSupervisor) {
      return Colors.green.withValues(alpha: 0.1);
    } else if (widget.isEquipment) {
      return Colors.orange.withValues(alpha: 0.1);
    } else if (widget.isProfession) {
      return Colors.blue.withValues(alpha: 0.1);
    } else {
      return Theme.of(context).primaryColor.withValues(alpha: 0.1);
    }
  }

  Widget _getIcon(String option) {
    if (widget.isShift) {
      return Text(
        option,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.purple,
        ),
      );
    } else if (widget.isSupervisor) {
      return const Icon(Icons.supervisor_account, size: 12, color: Colors.green);
    } else if (widget.isEquipment) {
      return const Icon(Icons.precision_manufacturing, size: 12, color: Colors.orange);
    } else if (widget.isProfession) {
      return const Icon(Icons.build, size: 12, color: Colors.blue);
    } else {
      return Text(
        option.substring(0, 1),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      );
    }
  }

  void _addToDatabase(String value) {
    if (widget.isSupervisor) {
      addNewSupervisor(value);
    } else if (widget.isEquipment) {
      addNewEquipment(value);
    } else if (widget.isProfession) {
      addNewProfession(value);
    } else {
      addNewName(value);
    }
  }

  void _showAddToDbDialog(String value) {
    // Don't show dialog for shifts - they're fixed
    if (widget.isShift) return;
    
    String itemType;
    if (widget.isSupervisor) {
      itemType = 'työnjohtajiin';
    } else if (widget.isEquipment) {
      itemType = 'koneisiin';
    } else if (widget.isProfession) {
      itemType = 'alaisuuksiin';
    } else {
      itemType = 'asentajiin';
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Lisää $itemType?'),
          content: Text('Haluatko lisätä "$value" tietokantaan tulevaisuuden ehdotuksia varten?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Peruuta'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _addToDatabase(value);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lisätty "$value" tietokantaan')),
                );
              },
              child: const Text('Lisää'),
            ),
          ],
        );
      },
    );
  }
} 
import 'package:flutter/material.dart';

// Name database - now mutable
List<String> nameDatabase = [
  'Sauli Juntikka', 'Teijo Alatalo', 'Jari Kapraali', 'Toni Kortesalmi',
  'Janne Joensuu', 'Sauli Mustajärvi', 'Ville Seilola', 'Mikko Tammela',
  'Arttu Lahdenperä', 'Joni Väätäinen', 'Mikko Pirttimaa', 'Tuomas Laakso',
  'Mikko Yritys', 'Tino Koivisto', 'Pekka Palosaari', 'Teemu Soininen',
  'Sami Svenn', 'Pekka Piittinen', 'Jussi Satta', 'Aleksi Jolma',
  'Miika Keto-Tokoi', 'Mikko Arpi', 'Juho Keinänen', 'Marko Keränen',
  'Ville Valppu', 'Anssi Tumelius', 'Antti Lehto', 'Mika Kumpulainen',
  'Eemeli Körkkö', 'Esa Vaattovaara', 'Eetu Vaattovaara', 'Valtteri Ylisaukko-oja',
  'Henrik Vaattovaara', 'Juho Laitakari', 'Janne Haara', 'Ossi Littow',
  'Timo Saariniemi', 'Asko Tammela', 'Mika Niilonen', 'Morten Labba',
  'Eemeli Kirkkala', 'Eetu Savunen', 'Julius Kasurinen', 'Tomi Peltoniemi',
  'Arttu Örn', 'Henry Mehtälä', 'Joona Yliperttula', 'Miikka Ylitalo',
  'Niko Wallen', 'Henri Tyrväinen', 'Ella-Maria Heikinmatti'
];

// Supervisor database - selected supervisors only
List<String> supervisorDatabase = [
  'Ossi Littow', 'Sauli Juntikka', 'Mikko Tammela', 'Mika Kumpulainen',
  'Jari Kapraali', 'Ella-Maria Heikinmatti', 'Anssi Tumelius'
];

// Shift database
const List<String> shiftDatabase = ['A', 'B', 'C', 'D'];

// Equipment database - now mutable
List<String> equipmentDatabase = [
  'Vario 30', 'Vario 31', 'Volvo', 'Komatsu/pora', 'Scania', 
  'Merlo Tönkkö', 'Bobcat 7', 'Bobcat 8', 'Giamec', 'Hydrema', 
  'Merlo Vaattovaara', 'Giamek 35', 'Merlo Pyörivä'
];

// Profession database - now mutable
List<String> professionDatabase = [
  'Varu1', 'Varu2', 'Varu3', 'Varu4', 'Pasta1', 'Pasta2', 'Pora', 'Tarvikeauto', 'Huoltomies'
];

// Add new name to database
void addNewName(String name) {
  if (name.trim().isNotEmpty && !nameDatabase.contains(name.trim())) {
    nameDatabase.add(name.trim());
    nameDatabase.sort(); // Keep alphabetically sorted
  }
}

// Remove name from database
void removeName(String name) {
  nameDatabase.remove(name);
  // Also remove from supervisor database if present
  supervisorDatabase.remove(name);
}

// Add new supervisor to database
void addNewSupervisor(String supervisor) {
  if (supervisor.trim().isNotEmpty && !supervisorDatabase.contains(supervisor.trim())) {
    supervisorDatabase.add(supervisor.trim());
    supervisorDatabase.sort(); // Keep alphabetically sorted
    
    // Also add to general name database if not already there
    if (!nameDatabase.contains(supervisor.trim())) {
      nameDatabase.add(supervisor.trim());
      nameDatabase.sort();
    }
  }
}

// Remove supervisor from database
void removeSupervisor(String supervisor) {
  supervisorDatabase.remove(supervisor);
}

// Add new equipment to database
void addNewEquipment(String equipment) {
  if (equipment.trim().isNotEmpty && !equipmentDatabase.contains(equipment.trim())) {
    equipmentDatabase.add(equipment.trim());
    equipmentDatabase.sort(); // Keep alphabetically sorted
  }
}

// Remove equipment from database
void removeEquipment(String equipment) {
  equipmentDatabase.remove(equipment);
}

// Add new profession to database
void addNewProfession(String profession) {
  if (profession.trim().isNotEmpty && !professionDatabase.contains(profession.trim())) {
    professionDatabase.add(profession.trim());
    professionDatabase.sort(); // Keep alphabetically sorted
  }
}

// Get name suggestions based on first letters
List<String> getNameSuggestions(String query) {
  if (query.isEmpty) return [];
  
  // First try exact starts with match
  var exactMatches = nameDatabase
      .where((name) => name.toLowerCase().startsWith(query.toLowerCase()))
      .take(5)
      .toList();
  
  // If we don't have enough matches, add contains matches
  if (exactMatches.length < 5) {
    var containsMatches = nameDatabase
        .where((name) => 
            name.toLowerCase().contains(query.toLowerCase()) &&
            !name.toLowerCase().startsWith(query.toLowerCase()))
        .take(5 - exactMatches.length)
        .toList();
    exactMatches.addAll(containsMatches);
  }
  
  return exactMatches;
}

// Get supervisor suggestions based on first letters
List<String> getSupervisorSuggestions(String query) {
  if (query.isEmpty) return [];
  
  // First try exact starts with match
  var exactMatches = supervisorDatabase
      .where((supervisor) => supervisor.toLowerCase().startsWith(query.toLowerCase()))
      .take(5)
      .toList();
  
  // If we don't have enough matches, add contains matches
  if (exactMatches.length < 5) {
    var containsMatches = supervisorDatabase
        .where((supervisor) => 
            supervisor.toLowerCase().contains(query.toLowerCase()) &&
            !supervisor.toLowerCase().startsWith(query.toLowerCase()))
        .take(5 - exactMatches.length)
        .toList();
    exactMatches.addAll(containsMatches);
  }
  
  return exactMatches;
}

// Get shift suggestions
List<String> getShiftSuggestions(String query) {
  if (query.isEmpty) return shiftDatabase;
  return shiftDatabase
      .where((shift) => shift.toLowerCase().startsWith(query.toLowerCase()))
      .toList();
}

// Get equipment suggestions based on first letters
List<String> getEquipmentSuggestions(String query) {
  if (query.isEmpty) return [];
  
  // First try exact starts with match
  var exactMatches = equipmentDatabase
      .where((equipment) => equipment.toLowerCase().startsWith(query.toLowerCase()))
      .take(5)
      .toList();
  
  // If we don't have enough matches, add contains matches
  if (exactMatches.length < 5) {
    var containsMatches = equipmentDatabase
        .where((equipment) => 
            equipment.toLowerCase().contains(query.toLowerCase()) &&
            !equipment.toLowerCase().startsWith(query.toLowerCase()))
        .take(5 - exactMatches.length)
        .toList();
    exactMatches.addAll(containsMatches);
  }
  
  return exactMatches;
}

// Get profession suggestions based on first letters
List<String> getProfessionSuggestions(String query) {
  if (query.isEmpty) return [];
  
  // First try exact starts with match
  var exactMatches = professionDatabase
      .where((profession) => profession.toLowerCase().startsWith(query.toLowerCase()))
      .take(5)
      .toList();
  
  // If we don't have enough matches, add contains matches
  if (exactMatches.length < 5) {
    var containsMatches = professionDatabase
        .where((profession) => 
            profession.toLowerCase().contains(query.toLowerCase()) &&
            !profession.toLowerCase().startsWith(query.toLowerCase()))
        .take(5 - exactMatches.length)
        .toList();
    exactMatches.addAll(containsMatches);
  }
  
  return exactMatches;
}

class SettingsScreen extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  const SettingsScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _nameSearchQuery = '';
  String _supervisorSearchQuery = '';
  String _equipmentSearchQuery = '';
  final TextEditingController _newNameController = TextEditingController();
  final TextEditingController _newSupervisorController = TextEditingController();
  final TextEditingController _newEquipmentController = TextEditingController();
  
  late bool _localDarkMode;

  @override
  void initState() {
    super.initState();
    _localDarkMode = widget.isDarkMode;
  }

  @override
  void dispose() {
    _newNameController.dispose();
    _newSupervisorController.dispose();
    _newEquipmentController.dispose();
    super.dispose();
  }

  // Get filtered names based on search query
  List<String> get filteredNames {
    if (_nameSearchQuery.isEmpty) return nameDatabase;
    return nameDatabase
        .where((name) => name.toLowerCase().contains(_nameSearchQuery.toLowerCase()))
        .toList();
  }

  // Get filtered supervisors based on search query
  List<String> get filteredSupervisors {
    if (_supervisorSearchQuery.isEmpty) return supervisorDatabase;
    return supervisorDatabase
        .where((supervisor) => supervisor.toLowerCase().contains(_supervisorSearchQuery.toLowerCase()))
        .toList();
  }

  // Get filtered equipment based on search query
  List<String> get filteredEquipment {
    if (_equipmentSearchQuery.isEmpty) return equipmentDatabase;
    return equipmentDatabase
        .where((equipment) => equipment.toLowerCase().contains(_equipmentSearchQuery.toLowerCase()))
        .toList();
  }

  void _addNewName() {
    final newName = _newNameController.text.trim();
    if (newName.isNotEmpty) {
      if (nameDatabase.contains(newName)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Asentaja "$newName" on jo olemassa')),
        );
      } else {
        setState(() {
          addNewName(newName);
          _newNameController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lisätty "$newName" tietokantaan')),
        );
      }
    }
  }

  void _addNewSupervisor() {
    final newSupervisor = _newSupervisorController.text.trim();
    if (newSupervisor.isNotEmpty) {
      if (supervisorDatabase.contains(newSupervisor)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Työnjohtaja "$newSupervisor" on jo olemassa')),
        );
      } else {
        setState(() {
          addNewSupervisor(newSupervisor);
          _newSupervisorController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lisätty "$newSupervisor" työnjohtajiin')),
        );
      }
    }
  }

  void _addNewEquipment() {
    final newEquipment = _newEquipmentController.text.trim();
    if (newEquipment.isNotEmpty) {
      if (equipmentDatabase.contains(newEquipment)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kone "$newEquipment" on jo olemassa')),
        );
      } else {
        setState(() {
          addNewEquipment(newEquipment);
          _newEquipmentController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lisätty "$newEquipment" tietokantaan')),
        );
      }
    }
  }

  void _confirmRemoveName(String name) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Poista asentaja'),
          content: Text('Haluatko varmasti poistaa "$name" tietokannasta?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Peruuta'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  removeName(name);
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Poistettu "$name" tietokannasta')),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Poista'),
            ),
          ],
        );
      },
    );
  }

  void _confirmRemoveSupervisor(String supervisor) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Poista työnjohtaja'),
          content: Text('Haluatko varmasti poistaa "$supervisor" työnjohtajista?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Peruuta'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  removeSupervisor(supervisor);
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Poistettu "$supervisor" työnjohtajista')),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Poista'),
            ),
          ],
        );
      },
    );
  }

  void _confirmRemoveEquipment(String equipment) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Poista kone'),
          content: Text('Haluatko varmasti poistaa "$equipment" tietokannasta?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Peruuta'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  removeEquipment(equipment);
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Poistettu "$equipment" tietokannasta')),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Poista'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Theme Section
                _buildSectionTitle('Theme'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.palette),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tumma tila',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _localDarkMode ? 'Tumma tila käytössä' : 'Vaalea tila käytössä',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _localDarkMode,
                          onChanged: (bool value) {
                            setState(() {
                              _localDarkMode = value;
                            });
                            widget.onThemeChanged(value);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Supervisor Database Section
                _buildSectionTitle('Työnjohtajat (${supervisorDatabase.length} työnjohtajaa)'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Add new supervisor section
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _newSupervisorController,
                                decoration: const InputDecoration(
                                  hintText: 'Lisää uusi työnjohtaja...',
                                  prefixIcon: Icon(Icons.supervisor_account),
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                onSubmitted: (_) => _addNewSupervisor(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _addNewSupervisor,
                              child: const Text('Lisää'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Search existing supervisors
                        TextField(
                          decoration: const InputDecoration(
                            hintText: 'Etsi työnjohtajia...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _supervisorSearchQuery = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 150,
                          child: ListView.builder(
                            itemCount: filteredSupervisors.length,
                            itemBuilder: (context, index) {
                              final supervisor = filteredSupervisors[index];
                              return ListTile(
                                dense: true,
                                leading: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.green.withValues(alpha: 0.1),
                                  child: const Icon(
                                    Icons.supervisor_account,
                                    size: 16,
                                    color: Colors.green,
                                  ),
                                ),
                                title: Text(supervisor, style: const TextStyle(fontSize: 14)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                  onPressed: () => _confirmRemoveSupervisor(supervisor),
                                ),
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Valittu työnjohtaja: $supervisor'),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Name Database Section
                _buildSectionTitle('Asentajat (${nameDatabase.length} asentajaa)'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Add new name section
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _newNameController,
                                decoration: const InputDecoration(
                                  hintText: 'Lisää uusi asentaja...',
                                  prefixIcon: Icon(Icons.person_add),
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                onSubmitted: (_) => _addNewName(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _addNewName,
                              child: const Text('Lisää'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Search existing names
                        TextField(
                          decoration: const InputDecoration(
                            hintText: 'Etsi asentajia...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _nameSearchQuery = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            itemCount: filteredNames.length,
                            itemBuilder: (context, index) {
                              final name = filteredNames[index];
                              return ListTile(
                                dense: true,
                                leading: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                  child: Text(
                                    name.substring(0, 1),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ),
                                title: Text(name, style: const TextStyle(fontSize: 14)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                  onPressed: () => _confirmRemoveName(name),
                                ),
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Valittu: $name'),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Equipment Database Section
                _buildSectionTitle('Koneet (${equipmentDatabase.length} konetta)'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Add new equipment section
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _newEquipmentController,
                                decoration: const InputDecoration(
                                  hintText: 'Lisää uusi kone...',
                                  prefixIcon: Icon(Icons.add_box),
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                onSubmitted: (_) => _addNewEquipment(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _addNewEquipment,
                              child: const Text('Lisää'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Search existing equipment
                        TextField(
                          decoration: const InputDecoration(
                            hintText: 'Etsi koneita...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _equipmentSearchQuery = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            itemCount: filteredEquipment.length,
                            itemBuilder: (context, index) {
                              final equipment = filteredEquipment[index];
                              return ListTile(
                                dense: true,
                                leading: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.orange.withValues(alpha: 0.1),
                                  child: const Icon(
                                    Icons.precision_manufacturing,
                                    size: 16,
                                    color: Colors.orange,
                                  ),
                                ),
                                title: Text(equipment, style: const TextStyle(fontSize: 14)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                  onPressed: () => _confirmRemoveEquipment(equipment),
                                ),
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Valittu: $equipment'),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Database Statistics Section
                _buildSectionTitle('Tietokannan tilastot'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.supervisor_account, color: Colors.green),
                            const SizedBox(width: 12),
                            const Text('Työnjohtajia yhteensä:', style: TextStyle(fontWeight: FontWeight.w500)),
                            const Spacer(),
                            Text('${supervisorDatabase.length}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.people, color: Colors.blue),
                            const SizedBox(width: 12),
                            const Text('Asentajia yhteensä:', style: TextStyle(fontWeight: FontWeight.w500)),
                            const Spacer(),
                            Text('${nameDatabase.length}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.precision_manufacturing, color: Colors.orange),
                            const SizedBox(width: 12),
                            const Text('Koneita yhteensä:', style: TextStyle(fontWeight: FontWeight.w500)),
                            const Spacer(),
                            Text('${equipmentDatabase.length}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.schedule, color: Colors.purple),
                            const SizedBox(width: 12),
                            const Text('Vuoroja yhteensä:', style: TextStyle(fontWeight: FontWeight.w500)),
                            const Spacer(),
                            Text('${shiftDatabase.length}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
} 
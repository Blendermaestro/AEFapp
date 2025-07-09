import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _senderNameController = TextEditingController();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedFeedbackType = 'feedback';
  String _selectedTable = 'General';
  bool _isSubmitting = false;
  bool _hasConsented = false;

  final List<Map<String, String>> _feedbackTypes = [
    {'value': 'feedback', 'label': 'Palaute'},
    {'value': 'bug', 'label': 'Virheraportti'},
    {'value': 'suggestion', 'label': 'Parannusehdotus'},
  ];

  final List<Map<String, String>> _relatedTables = [
    {'value': 'General', 'label': 'Yleinen'},
    {'value': 'PDF', 'label': 'PDF-välilehti'},
    {'value': 'PDF2', 'label': 'PDF2-välilehti'},
    {'value': 'PDF3', 'label': 'PDF3-välilehti'},
    {'value': 'Excel', 'label': 'Excel-välilehti'},
    {'value': 'Settings', 'label': 'Asetukset'},
    {'value': 'Auth', 'label': 'Kirjautuminen'},
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _senderNameController.dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }



  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_hasConsented) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sinun tulee hyväksyä tietosuojaehdot ennen lähettämistä.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await SupabaseService.submitFeedback(
        senderName: _senderNameController.text,
        feedbackType: _selectedFeedbackType,
        relatedTable: _selectedTable,
        subject: _subjectController.text,
        description: _descriptionController.text,
      );

      // Clear form
      _subjectController.clear();
      _descriptionController.clear();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Palaute lähetetty onnistuneesti! Kiitos palautteestasi.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Virhe palautteen lähetyksessä: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Palaute ja virheraportointi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.feedback, color: Theme.of(context).primaryColor),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Lähetä palautetta',
                                    style: Theme.of(context).textTheme.headlineSmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Kerro mielipiteesi, raportoi virheitä tai ehdota parannuksia.',
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Feedback Form
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Uusi palaute',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),

                          // Sender Name (optional)
                          TextFormField(
                            controller: _senderNameController,
                            decoration: const InputDecoration(
                              labelText: 'Lähettäjä (valinnainen)',
                              hintText: 'Syötä nimesi tai jätä tyhjäksi',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Feedback Type
                          Text(
                            'Palautteen tyyppi',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: _feedbackTypes.map((type) {
                              final isSelected = _selectedFeedbackType == type['value'];
                              return FilterChip(
                                label: Text(type['label']!),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedFeedbackType = type['value']!;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),

                          // Related Table
                          Text(
                            'Liittyy osa-alueeseen',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _relatedTables.map((table) {
                              final isSelected = _selectedTable == table['value'];
                              return FilterChip(
                                label: Text(table['label']!),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedTable = table['value']!;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),

                          // Subject
                          TextFormField(
                            controller: _subjectController,
                            decoration: const InputDecoration(
                              labelText: 'Aihe *',
                              hintText: 'Lyhyt kuvaus palautteesta',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.title),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Aihe on pakollinen';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Description
                          TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Kuvaus *',
                              hintText: 'Kerro yksityiskohtaisesti palautteestasi...',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.description),
                            ),
                            maxLines: 6,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Kuvaus on pakollinen';
                              }
                              if (value.trim().length < 10) {
                                return 'Kuvauksen on oltava vähintään 10 merkkiä pitkä';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // GDPR Compliance Section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.privacy_tip, color: Theme.of(context).primaryColor),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Tietosuoja',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Käsiteltävät tiedot:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '• Lähettäjän nimi (valinnainen)\n• Palautteen sisältö\n• Lähetysaika\n• Käyttäjätunnus (tekninen)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Käyttötarkoitus:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Sovelluksen kehittäminen ja virheiden korjaaminen.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Säilytysaika:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Palautteet säilytetään 2 vuotta, jonka jälkeen ne poistetaan automaattisesti.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Oikeutesi:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Voit pyytää tietojesi tarkastelua, oikaisua tai poistamista ottamalla yhteyttä sovelluksen ylläpitäjään.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _hasConsented,
                                      onChanged: (value) {
                                        setState(() {
                                          _hasConsented = value ?? false;
                                        });
                                      },
                                    ),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _hasConsented = !_hasConsented;
                                          });
                                        },
                                        child: Text(
                                          'Hyväksyn yllä kuvatun henkilötietojeni käsittelyn palautteen lähettämiseksi.',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _submitFeedback,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: _isSubmitting
                                  ? const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text('Lähetetään...'),
                                      ],
                                    )
                                  : const Text('Lähetä palaute'),
                            ),
                          ),
                        ],
                      ),
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
} 
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
  List<Map<String, dynamic>> _previousFeedback = [];
  bool _isLoadingPrevious = false;

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
    _loadPreviousFeedback();
  }

  @override
  void dispose() {
    _senderNameController.dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadPreviousFeedback() async {
    setState(() {
      _isLoadingPrevious = true;
    });

    try {
      final feedback = await SupabaseService.loadUserFeedback();
      setState(() {
        _previousFeedback = feedback;
      });
    } catch (e) {
      print('Error loading previous feedback: $e');
    } finally {
      setState(() {
        _isLoadingPrevious = false;
      });
    }
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

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
      
      // Reload previous feedback
      await _loadPreviousFeedback();

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

  String _getStatusText(String status) {
    switch (status) {
      case 'open':
        return 'Avoin';
      case 'in_progress':
        return 'Käsittelyssä';
      case 'resolved':
        return 'Ratkaistu';
      case 'closed':
        return 'Suljettu';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
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

                const SizedBox(height: 24),

                // Previous Feedback
                if (_previousFeedback.isNotEmpty) ...[
                  Text(
                    'Aiemmat palautteesi',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ..._previousFeedback.map((feedback) {
                    final createdAt = DateTime.parse(feedback['created_at']);
                    final formattedDate = '${createdAt.day}.${createdAt.month}.${createdAt.year}';
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(feedback['status']).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: _getStatusColor(feedback['status'])),
                                  ),
                                  child: Text(
                                    _getStatusText(feedback['status']),
                                    style: TextStyle(
                                      color: _getStatusColor(feedback['status']),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  formattedDate,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              feedback['subject'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  _feedbackTypes.firstWhere(
                                    (type) => type['value'] == feedback['feedback_type'],
                                    orElse: () => {'label': feedback['feedback_type']},
                                  )['label']!,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                                const Text(' • '),
                                Text(
                                  _relatedTables.firstWhere(
                                    (table) => table['value'] == feedback['related_table'],
                                    orElse: () => {'label': feedback['related_table']},
                                  )['label']!,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              feedback['description'],
                              style: TextStyle(color: Colors.grey.shade800),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],

                if (_isLoadingPrevious)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
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
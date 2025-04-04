import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../widgets/custom_app_bar.dart';
import '../utils/theme_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class MedicalConditionsScreen extends StatefulWidget {
  const MedicalConditionsScreen({super.key});

  @override
  State<MedicalConditionsScreen> createState() => _MedicalConditionsScreenState();
}

class _MedicalConditionsScreenState extends State<MedicalConditionsScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _searchQuery = '';
  String _severityFilter = 'All';

  // Form controllers
  final _conditionController = TextEditingController();
  final _diagnosisDateController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _notesController = TextEditingController();

  // List of medical conditions
  final List<Map<String, dynamic>> _conditions = [];

  // Stream subscription for real-time updates
  StreamSubscription<QuerySnapshot>? _conditionsSubscription;

  @override
  void initState() {
    super.initState();
    _setupRealtimeUpdates();
  }

  void _setupRealtimeUpdates() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      _conditionsSubscription = FirebaseFirestore.instance
          .collection('medical_conditions')
          .doc(userId)
          .collection('conditions')
          .snapshots()
          .listen((snapshot) {
        setState(() {
          _conditions.clear();
          for (var doc in snapshot.docs) {
            _conditions.add(doc.data());
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _conditionsSubscription?.cancel();
    _conditionController.dispose();
    _diagnosisDateController.dispose();
    _medicationsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredConditions {
    return _conditions.where((condition) {
      final matchesSearch = condition['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesSeverity = _severityFilter == 'All' || condition['severity'] == _severityFilter;
      return matchesSearch && matchesSeverity;
    }).toList();
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search conditions...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Theme.of(context).cardColor,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildSeverityFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          const Text('Filter by severity: '),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _severityFilter,
            items: ['All', 'Low', 'Medium', 'High'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _severityFilter = newValue;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildConditionCard(Map<String, dynamic> condition, int index) {
    final severity = condition['severity'] ?? 'Low';
    final severityColor = _getSeverityColor(severity);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    condition['name'] ?? '',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: severityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    severity,
                    style: TextStyle(
                      color: severityColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Diagnosed: ${condition['diagnosisDate'] ?? 'N/A'}',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
            if (condition['medications']?.isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              Text(
                'Medications: ${condition['medications']}',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
            ],
            if (condition['notes']?.isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              Text(
                'Notes: ${condition['notes']}',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _editCondition(index),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red,
                  onPressed: () => _deleteCondition(index),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _editCondition(int index) {
    final condition = _conditions[index];
    _conditionController.text = condition['name'] ?? '';
    _diagnosisDateController.text = condition['diagnosisDate'] ?? '';
    _medicationsController.text = condition['medications'] ?? '';
    _notesController.text = condition['notes'] ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Medical Condition'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _conditionController,
                  decoration: const InputDecoration(
                    labelText: 'Condition Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the condition name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _diagnosisDateController,
                  decoration: const InputDecoration(
                    labelText: 'Diagnosis Date',
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      _diagnosisDateController.text = date.toString().split(' ')[0];
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _medicationsController,
                  decoration: const InputDecoration(
                    labelText: 'Medications (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _updateCondition(index),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateCondition(int index) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final updatedCondition = {
      'name': _conditionController.text,
      'diagnosisDate': _diagnosisDateController.text,
      'medications': _medicationsController.text,
      'notes': _notesController.text,
    };

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('medical_conditions')
            .doc(userId)
            .collection('conditions')
            .where('name', isEqualTo: _conditions[index]['name'])
            .where('diagnosisDate', isEqualTo: _conditions[index]['diagnosisDate'])
            .get();

        for (var doc in snapshot.docs) {
          await doc.reference.update(updatedCondition);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Condition updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating condition: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Medical Conditions',
        showBackButton: true,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildSeverityFilter(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredConditions.length,
                    itemBuilder: (context, index) {
                      return _buildConditionCard(_filteredConditions[index], index);
                    },
                  ),
          ),
          _buildAddConditionButton(),
        ],
      ),
    );
  }

  Widget _buildAddConditionButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: _showAddConditionDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Medical Condition'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _showAddConditionDialog() {
    _conditionController.clear();
    _diagnosisDateController.clear();
    _medicationsController.clear();
    _notesController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Medical Condition'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _conditionController,
                  decoration: const InputDecoration(
                    labelText: 'Condition Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the condition name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _diagnosisDateController,
                  decoration: const InputDecoration(
                    labelText: 'Diagnosis Date',
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      _diagnosisDateController.text = date.toString().split(' ')[0];
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _medicationsController,
                  decoration: const InputDecoration(
                    labelText: 'Medications (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _addCondition,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addCondition() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final newCondition = {
      'name': _conditionController.text,
      'diagnosisDate': _diagnosisDateController.text,
      'medications': _medicationsController.text,
      'notes': _notesController.text,
    };

    setState(() {
      _conditions.add(newCondition);
    });

    _saveConditionToFirestore(newCondition);

    Navigator.pop(context);
  }

  Future<void> _saveConditionToFirestore(Map<String, dynamic> condition) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await FirebaseFirestore.instance
            .collection('medical_conditions')
            .doc(userId)
            .collection('conditions')
            .add(condition);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Condition added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding condition: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteCondition(int index) {
    final condition = _conditions[index];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Condition'),
        content: const Text('Are you sure you want to delete this condition?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _deleteConditionFromFirestore(condition);
              setState(() {
                _conditions.removeAt(index);
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteConditionFromFirestore(Map<String, dynamic> condition) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('medical_conditions')
            .doc(userId)
            .collection('conditions')
            .where('name', isEqualTo: condition['name'])
            .where('diagnosisDate', isEqualTo: condition['diagnosisDate'])
            .get();

        for (var doc in snapshot.docs) {
          await doc.reference.delete();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Condition deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting condition: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 
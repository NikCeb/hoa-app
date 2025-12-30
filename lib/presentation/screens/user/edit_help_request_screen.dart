import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hoa_application/core/utils/message_alert.dart';
import '../../../../data/models/help_request.dart';
import '../../../core/constants/app_colors.dart';

/// Edit Help Request Screen - Edit an existing help request
///
/// Features:
/// - Pre-filled form with existing data
/// - Update title, description, category, helpers needed
/// - Save changes to Firestore
class EditHelpRequestScreen extends StatefulWidget {
  final HelpRequest request;

  const EditHelpRequestScreen({
    super.key,
    required this.request,
  });

  @override
  State<EditHelpRequestScreen> createState() => _EditHelpRequestScreenState();
}

class _EditHelpRequestScreenState extends State<EditHelpRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late RequestCategory _selectedCategory; // Changed to enum type
  late int _helpersNeeded;

  bool _isLoading = false;

  // Categories - using the enum values
  final List<Map<String, dynamic>> _categories = [
    {
      'value': RequestCategory.handyman,
      'label': 'Handyman',
      'icon': Icons.build
    },
    {'value': RequestCategory.petCare, 'label': 'Pet Care', 'icon': Icons.pets},
    {
      'value': RequestCategory.errand,
      'label': 'Errands',
      'icon': Icons.shopping_basket
    },
    {
      'value': RequestCategory.emergency,
      'label': 'Emergency',
      'icon': Icons.emergency
    },
    {
      'value': RequestCategory.transportation,
      'label': 'Transportation',
      'icon': Icons.directions_car
    },
    {
      'value': RequestCategory.other,
      'label': 'Other',
      'icon': Icons.help_outline
    },
  ];

  @override
  void initState() {
    super.initState();

    // Pre-fill form with existing data
    _titleController = TextEditingController(text: widget.request.title);
    _descriptionController =
        TextEditingController(text: widget.request.description);
    _selectedCategory = widget.request.category; // Now correctly using enum
    _helpersNeeded = widget.request.helpersNeeded;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Update request in Firestore
      // Convert enum to string using .name property
      await FirebaseFirestore.instance
          .collection('help_requests')
          .doc(widget.request.id)
          .update({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory.name, // Convert enum to string
        'helpersNeeded': _helpersNeeded,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        // Go back to previous screen
        Navigator.pop(context);

        // Show success message
        showMessage(context, 'Request updated successfully',
            bgColor: Colors.green);
      }
    } catch (e) {
      if (mounted) {
        showMessage(context, 'Error updating request: $e', bgColor: Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        title: const Text('Edit Request'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info message
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.blue[700], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Edit your request details',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Title field
                    const Text(
                      'Title',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'e.g., Need help moving furniture',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      maxLength: 100,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a title';
                        }
                        if (value.trim().length < 10) {
                          return 'Title must be at least 10 characters';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Description field
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        hintText: 'Describe what you need help with...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      maxLines: 5,
                      maxLength: 500,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a description';
                        }
                        if (value.trim().length < 20) {
                          return 'Description must be at least 20 characters';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Category field
                    const Text(
                      'Category',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<RequestCategory>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem<RequestCategory>(
                          value: category['value'] as RequestCategory,
                          child: Row(
                            children: [
                              Icon(
                                category['icon'] as IconData,
                                size: 20,
                                color: const Color(0xFF2563EB),
                              ),
                              const SizedBox(width: 12),
                              Text(category['label'] as String),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a category';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Helpers needed field
                    const Text(
                      'Helpers Needed',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.people_outline,
                              color: Color(0xFF2563EB)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '$_helpersNeeded ${_helpersNeeded == 1 ? 'person' : 'people'}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: _helpersNeeded > 1
                                ? () {
                                    setState(() {
                                      _helpersNeeded--;
                                    });
                                  }
                                : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: _helpersNeeded < 10
                                ? () {
                                    setState(() {
                                      _helpersNeeded++;
                                    });
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Cancel button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed:
                            _isLoading ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2563EB),
                          side: const BorderSide(
                            color: Color(0xFF2563EB),
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

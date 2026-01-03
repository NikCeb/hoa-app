import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAddToMasterlistScreen extends StatefulWidget {
  const AdminAddToMasterlistScreen({Key? key}) : super(key: key);

  @override
  State<AdminAddToMasterlistScreen> createState() =>
      _AdminAddToMasterlistScreenState();
}

class _AdminAddToMasterlistScreenState
    extends State<AdminAddToMasterlistScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _lotNumberController = TextEditingController();

  bool _isSubmitting = false;
  String _selectedPhase = 'Phase 1';
  String _selectedBlock = 'Block 1';
  String _selectedLot = 'Lot 1';
  String _selectedStatus = 'occupied';

  final List<String> _phases = ['Phase 1', 'Phase 2', 'Phase 3'];
  final List<String> _blocks = List.generate(5, (i) => 'Block ${i + 1}');
  final List<String> _lots = List.generate(20, (i) => 'Lot ${i + 1}');

  final List<String> _statuses = [
    'occupied',
    'available',
    'reserved',
  ];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _lotNumberController.dispose();
    super.dispose();
  }

  Future<void> _addToMasterlist() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final lotNumber = int.tryParse(_lotNumberController.text.trim());
      if (lotNumber == null) {
        throw Exception('Lot number must be a valid integer (e.g., 1001)');
      }

      // Check if lot number already exists
      final existingLot = await FirebaseFirestore.instance
          .collection('master_residents')
          .where('lotNumber', isEqualTo: lotNumber)
          .get();

      if (existingLot.docs.isNotEmpty) {
        throw Exception('Lot number $lotNumber already exists in master list');
      }

      // Add to master_residents collection
      await FirebaseFirestore.instance.collection('master_residents').add({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'lotNumber': lotNumber,
        'phase': _selectedPhase,
        'status': _selectedStatus,
        'residentId': null, // Will be filled when user registers
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lot $lotNumber added to master list successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add to Master List',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Add verified residents directly to master list. They can register and login immediately.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // First Name
            _buildLabel('First Name *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _firstNameController,
              decoration: _buildInputDecoration('e.g., Maria'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter first name';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Last Name
            _buildLabel('Last Name *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _lastNameController,
              decoration: _buildInputDecoration('e.g., Santos'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter last name';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Email
            _buildLabel('Email Address *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: _buildInputDecoration('e.g., maria@example.com'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter email';
                }
                if (!value.contains('@')) {
                  return 'Please enter valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Phone
            _buildLabel('Phone Number'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: _buildInputDecoration('e.g., +63 912 345 6789'),
            ),
            const SizedBox(height: 20),

            // Lot Number
            _buildLabel('Lot Number * (Integer only)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _lotNumberController,
              keyboardType: TextInputType.number,
              decoration: _buildInputDecoration('e.g., 1001'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter lot number';
                }
                if (int.tryParse(value) == null) {
                  return 'Lot number must be a valid integer';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Phase Selection
            _buildLabel('Phase *'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedPhase,
                  isExpanded: true,
                  items: _phases.map((phase) {
                    return DropdownMenuItem(
                      value: phase,
                      child: Text(phase),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedPhase = value!);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Block Selection
            _buildLabel('Block *'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedBlock,
                  isExpanded: true,
                  items: _blocks.map((block) {
                    return DropdownMenuItem(
                      value: block,
                      child: Text(block),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedBlock = value!);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Lot Selection
            _buildLabel('Lot *'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedLot,
                  isExpanded: true,
                  items: _lots.map((lot) {
                    return DropdownMenuItem(
                      value: lot,
                      child: Text(lot),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedLot = value!);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Status Selection
            _buildLabel('Status *'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedStatus,
                  isExpanded: true,
                  items: _statuses.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Row(
                        children: [
                          Icon(
                            _getStatusIcon(status),
                            size: 16,
                            color: _getStatusColor(status),
                          ),
                          const SizedBox(width: 8),
                          Text(_formatStatus(status)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedStatus = value!);
                  },
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _addToMasterlist,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Add to Master List',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'occupied':
        return Icons.home;
      case 'available':
        return Icons.home_outlined;
      case 'reserved':
        return Icons.bookmark;
      default:
        return Icons.help;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'occupied':
        return Colors.green;
      case 'available':
        return Colors.blue;
      case 'reserved':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatStatus(String status) {
    return status[0].toUpperCase() + status.substring(1);
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hoa_application/core/utils/message_alert.dart';
import '../../../../../data/repositories/financial_repository.dart';

/// Admin Bill Generation Screen - Generate monthly bills for all residents
///
/// Features:
/// - Select billing period (month/year)
/// - Preview: number of bills to be generated
/// - Generate bills button
/// - View generated bills history
class AdminBillGenerationScreen extends StatefulWidget {
  const AdminBillGenerationScreen({super.key});

  @override
  State<AdminBillGenerationScreen> createState() =>
      _AdminBillGenerationScreenState();
}

class _AdminBillGenerationScreenState extends State<AdminBillGenerationScreen> {
  final FinancialRepository _repository = FinancialRepository();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DateTime _selectedDate = DateTime.now();
  bool _isGenerating = false;
  int? _lastGeneratedCount;

  String get _selectedPeriod {
    return '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}';
  }

  String get _selectedMonthName {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[_selectedDate.month - 1]} ${_selectedDate.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        title: const Text('Bill Generation'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Automated Bill Generation',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Generate bills for all occupied lots based on active payment categories.',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Billing period selection
            const Text(
              'Select Billing Period',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_month,
                            color: Color(0xFF2563EB)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Billing Period',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                _selectedMonthName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: _selectDate,
                          child: const Text('Change'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Preview section
            const Text(
              'Generation Preview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            FutureBuilder<_GenerationPreview>(
              future: _getGenerationPreview(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Error: ${snapshot.error}'),
                    ),
                  );
                }

                final preview = snapshot.data!;

                return Column(
                  children: [
                    _buildPreviewCard(
                      'Occupied Lots',
                      preview.occupiedLots.toString(),
                      Icons.home,
                      Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _buildPreviewCard(
                      'Active Categories',
                      preview.activeCategories.toString(),
                      Icons.category,
                      Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _buildPreviewCard(
                      'Bills to Generate',
                      preview.totalBills.toString(),
                      Icons.receipt,
                      Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    _buildPreviewCard(
                      'Existing Bills',
                      preview.existingBills.toString(),
                      Icons.check_circle,
                      Colors.grey,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Warning if bills already exist
            FutureBuilder<_GenerationPreview>(
              future: _getGenerationPreview(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.existingBills > 0) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Bills already exist for this period. Only missing bills will be generated.',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // Generate button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateBills,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(
                  _isGenerating ? 'Generating...' : 'Generate Bills',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            // Success message
            if (_lastGeneratedCount != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Successfully generated $_lastGeneratedCount bills!',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
        _lastGeneratedCount = null; // Reset success message
      });
    }
  }

  Future<_GenerationPreview> _getGenerationPreview() async {
    // Get occupied lots count
    final residentsSnapshot = await _firestore
        .collection('master_residents')
        .where('status', isEqualTo: 'occupied')
        .get();
    final occupiedLots = residentsSnapshot.docs.length;

    // Get active categories count
    final categoriesSnapshot = await _firestore
        .collection('payment_categories')
        .where('isActive', isEqualTo: true)
        .where('isRecurring', isEqualTo: true)
        .get();
    final activeCategories = categoriesSnapshot.docs.length;

    // Get existing bills for this period
    final existingBillsSnapshot = await _firestore
        .collection('payments')
        .where('billingPeriod', isEqualTo: _selectedPeriod)
        .get();
    final existingBills = existingBillsSnapshot.docs.length;

    // Calculate total bills to generate
    final totalBills = (occupiedLots * activeCategories) - existingBills;

    return _GenerationPreview(
      occupiedLots: occupiedLots,
      activeCategories: activeCategories,
      totalBills: totalBills > 0 ? totalBills : 0,
      existingBills: existingBills,
    );
  }

  Future<void> _generateBills() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Bills'),
        content: Text(
          'Generate bills for $_selectedMonthName?\n\nThis will create payment records for all occupied lots.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
            ),
            child: const Text('Generate'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isGenerating = true;
      _lastGeneratedCount = null;
    });

    try {
      final count = await _repository.generateBills(_selectedPeriod);

      setState(() {
        _isGenerating = false;
        _lastGeneratedCount = count;
      });

      if (mounted) {
        showMessage(
          context,
          'Successfully generated $count bills!',
          bgColor: Colors.green,
        );
      }
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });

      if (mounted) {
        showMessage(
          context,
          'Error generating bills: $e',
          bgColor: Colors.red,
        );
      }
    }
  }
}

class _GenerationPreview {
  final int occupiedLots;
  final int activeCategories;
  final int totalBills;
  final int existingBills;

  _GenerationPreview({
    required this.occupiedLots,
    required this.activeCategories,
    required this.totalBills,
    required this.existingBills,
  });
}

import 'package:flutter/material.dart';
import 'package:hoa_application/core/utils/message_alert.dart';
import '../../../../../data/models/payment_category.dart';
import '../../../../../data/repositories/financial_repository.dart';

/// Admin Fee Definition Screen - Manage payment categories and fees
///
/// Features:
/// - View all payment categories
/// - Add new category
/// - Edit existing category
/// - Toggle active/inactive
class AdminFeeDefinitionScreen extends StatefulWidget {
  const AdminFeeDefinitionScreen({super.key});

  @override
  State<AdminFeeDefinitionScreen> createState() =>
      _AdminFeeDefinitionScreenState();
}

class _AdminFeeDefinitionScreenState extends State<AdminFeeDefinitionScreen> {
  final FinancialRepository _repository = FinancialRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        title: const Text('Fee Definition'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Manage Payment Categories',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Define standard fees for bill generation',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Categories list
          Expanded(
            child: StreamBuilder<List<PaymentCategory>>(
              stream: _repository.getPaymentCategories(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final categories = snapshot.data ?? [];

                if (categories.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No payment categories',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to add your first category',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return _buildCategoryCard(category);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategoryDialog(),
        backgroundColor: const Color(0xFF2563EB),
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
      ),
    );
  }

  Widget _buildCategoryCard(PaymentCategory category) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.categoryName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Active/Inactive badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        category.isActive ? Colors.green[50] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    category.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: category.isActive
                          ? Colors.green[700]
                          : Colors.grey[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Fee and due day info
            Row(
              children: [
                Expanded(
                  child: _buildInfoChip(
                    icon: Icons.payments_outlined,
                    label: 'Default Fee',
                    value: category.formattedFee,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoChip(
                    icon: Icons.calendar_today,
                    label: 'Due Day',
                    value: 'Day ${category.dueDayOfMonth}',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildInfoChip(
                    icon:
                        category.isRecurring ? Icons.repeat : Icons.event_note,
                    label: 'Type',
                    value: category.isRecurring ? 'Recurring' : 'One-time',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showCategoryDialog(category: category),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2563EB),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _toggleActive(category),
                    icon: Icon(
                      category.isActive ? Icons.toggle_on : Icons.toggle_off,
                      size: 18,
                    ),
                    label: Text(category.isActive ? 'Deactivate' : 'Activate'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          category.isActive ? Colors.orange : Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF2563EB)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCategoryDialog({PaymentCategory? category}) {
    final isEdit = category != null;
    final nameController = TextEditingController(text: category?.categoryName);
    final descController = TextEditingController(text: category?.description);
    final feeController = TextEditingController(
      text: category?.defaultFee.toStringAsFixed(2) ?? '',
    );
    int selectedDay = category?.dueDayOfMonth ?? 15;
    bool isRecurring = category?.isRecurring ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Category' : 'Add Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    hintText: 'e.g., Monthly HOA Dues',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'e.g., Regular monthly assessment',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: feeController,
                  decoration: const InputDecoration(
                    labelText: 'Default Fee (₱)',
                    hintText: '0.00',
                    border: OutlineInputBorder(),
                    prefixText: '₱ ',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: selectedDay,
                  decoration: const InputDecoration(
                    labelText: 'Due Day of Month',
                    border: OutlineInputBorder(),
                  ),
                  items: List.generate(28, (index) => index + 1)
                      .map((day) => DropdownMenuItem(
                            value: day,
                            child: Text('Day $day'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedDay = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Recurring (Monthly)'),
                  subtitle: Text(
                    isRecurring
                        ? 'Bills generated every month'
                        : 'One-time assessment',
                  ),
                  value: isRecurring,
                  onChanged: (value) {
                    setDialogState(() {
                      isRecurring = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _saveCategory(
                category?.id,
                nameController.text,
                descController.text,
                feeController.text,
                selectedDay,
                isRecurring,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
              ),
              child: Text(isEdit ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveCategory(
    String? id,
    String name,
    String description,
    String feeText,
    int dueDay,
    bool isRecurring,
  ) async {
    if (name.trim().isEmpty) {
      showMessage(context, 'Please enter category name', bgColor: Colors.red);
      return;
    }

    final fee = double.tryParse(feeText) ?? 0;
    if (fee <= 0) {
      showMessage(context, 'Please enter valid fee amount',
          bgColor: Colors.red);
      return;
    }

    try {
      if (id == null) {
        // Create new
        await _repository.createPaymentCategory(
          PaymentCategory(
            id: '',
            categoryName: name.trim(),
            description: description.trim(),
            defaultFee: fee,
            dueDayOfMonth: dueDay,
            isRecurring: isRecurring,
            isActive: true,
            createdAt: DateTime.now(),
          ),
        );
        if (mounted) {
          Navigator.pop(context);
          showMessage(context, 'Category created successfully',
              bgColor: Colors.green);
        }
      } else {
        // Update existing
        await _repository.updatePaymentCategory(
          id,
          PaymentCategory(
            id: id,
            categoryName: name.trim(),
            description: description.trim(),
            defaultFee: fee,
            dueDayOfMonth: dueDay,
            isRecurring: isRecurring,
            isActive: true,
            createdAt: DateTime.now(),
          ),
        );
        if (mounted) {
          Navigator.pop(context);
          showMessage(context, 'Category updated successfully',
              bgColor: Colors.green);
        }
      }
    } catch (e) {
      if (mounted) {
        showMessage(context, 'Error: $e', bgColor: Colors.red);
      }
    }
  }

  Future<void> _toggleActive(PaymentCategory category) async {
    try {
      await _repository.updatePaymentCategory(
        category.id,
        category.copyWith(
          isActive: !category.isActive,
          updatedAt: DateTime.now(),
        ),
      );
      if (mounted) {
        showMessage(
          context,
          category.isActive ? 'Category deactivated' : 'Category activated',
          bgColor: Colors.green,
        );
      }
    } catch (e) {
      if (mounted) {
        showMessage(context, 'Error: $e', bgColor: Colors.red);
      }
    }
  }
}

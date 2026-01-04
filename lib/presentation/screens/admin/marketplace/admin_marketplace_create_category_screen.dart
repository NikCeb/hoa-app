import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../data/repositories/marketplace_repository.dart';

class AdminMarketplaceCreateCategoryScreen extends StatefulWidget {
  const AdminMarketplaceCreateCategoryScreen({Key? key}) : super(key: key);

  @override
  State<AdminMarketplaceCreateCategoryScreen> createState() =>
      _AdminMarketplaceCreateCategoryScreenState();
}

class _AdminMarketplaceCreateCategoryScreenState
    extends State<AdminMarketplaceCreateCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _sortOrderController = TextEditingController();
  bool _isSubmitting = false;

  final _repository = MarketplaceRepository();

  @override
  void dispose() {
    _nameController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  Future<void> _submitCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await _repository.createCategory(
        categoryName: _nameController.text.trim(),
        sortOrder: int.parse(_sortOrderController.text.trim()),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Category created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create category: $e'),
            backgroundColor: Colors.red,
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
          'Create Category',
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
            // Category Name Input
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Category Name *',
                hintText: 'e.g., Electronics, Furniture',
                prefixIcon: const Icon(Icons.category),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLength: 50,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a category name';
                }
                if (value.trim().length < 3) {
                  return 'Category name must be at least 3 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Sort Order Input
            TextFormField(
              controller: _sortOrderController,
              decoration: InputDecoration(
                labelText: 'Sort Order *',
                hintText: 'e.g., 1, 2, 3...',
                prefixIcon: const Icon(Icons.sort),
                helperText: 'Lower numbers appear first',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a sort order';
                }
                final order = int.tryParse(value);
                if (order == null || order < 1) {
                  return 'Sort order must be a positive number';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitCategory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Create Category',
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
    );
  }
}

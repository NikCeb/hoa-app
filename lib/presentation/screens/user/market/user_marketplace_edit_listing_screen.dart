import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../data/models/marketplace_listing.dart';
import '../../../../data/models/marketplace_category.dart';
import '../../../../data/repositories/marketplace_repository.dart';

class UserMarketplaceEditListingScreen extends StatefulWidget {
  final MarketplaceListing listing;

  const UserMarketplaceEditListingScreen({
    Key? key,
    required this.listing,
  }) : super(key: key);

  @override
  State<UserMarketplaceEditListingScreen> createState() =>
      _UserMarketplaceEditListingScreenState();
}

class _UserMarketplaceEditListingScreenState
    extends State<UserMarketplaceEditListingScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _locationController;

  String? _selectedCategoryId;
  late ItemCondition _selectedCondition;
  late bool _isNegotiable;
  late bool _allowsDelivery;
  List<File> _newImages = [];
  List<String> _existingImageUrls = [];
  bool _isSubmitting = false;

  final _repository = MarketplaceRepository();
  final _imagePicker = ImagePicker();

  List<MarketplaceCategory> _categories = [];

  @override
  void initState() {
    super.initState();

    // Pre-fill with existing data
    _titleController = TextEditingController(text: widget.listing.title);
    _descriptionController =
        TextEditingController(text: widget.listing.description);
    _priceController =
        TextEditingController(text: widget.listing.price.toStringAsFixed(0));
    _locationController =
        TextEditingController(text: widget.listing.location ?? '');

    _selectedCategoryId = widget.listing.categoryId;
    _selectedCondition = widget.listing.condition;
    _isNegotiable = widget.listing.isNegotiable;
    _allowsDelivery = widget.listing.allowsDelivery;
    _existingImageUrls = List.from(widget.listing.photosRef);

    _loadCategories();
  }

  Future<void> _loadCategories() async {
    _repository.getActiveCategories().listen((categories) {
      if (mounted) {
        setState(() {
          _categories = categories;
        });
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final totalImages = _existingImageUrls.length + _newImages.length;
    if (totalImages >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 5 photos allowed'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final pickedFiles = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFiles.isNotEmpty) {
        final remainingSlots = 5 - totalImages;
        final filesToAdd = pickedFiles.take(remainingSlots).toList();

        setState(() {
          _newImages.addAll(filesToAdd.map((xFile) => File(xFile.path)));
        });

        if (pickedFiles.length > remainingSlots) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Only ${remainingSlots} photo${remainingSlots > 1 ? 's' : ''} added (limit: 5)'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  Future<void> _submitUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // TODO: Implement update with photo management
      // For now, just update text fields
      await _repository.updateListing(widget.listing.id, {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'categoryId': _selectedCategoryId!,
        'condition': _selectedCondition.name.toUpperCase(),
        'isNegotiable': _isNegotiable,
        'location': _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        'allowsDelivery': _allowsDelivery,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Listing updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update listing: $e'),
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
          'Edit Listing',
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
            // Photos Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.photo_library, color: Color(0xFF2563EB)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Photos (${_existingImageUrls.length + _newImages.length}/5)',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Existing Photos Grid
                  if (_existingImageUrls.isNotEmpty) ...[
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _existingImageUrls.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                _existingImageUrls[index],
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeExistingImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                  ],

                  // New Photos Grid
                  if (_newImages.isNotEmpty) ...[
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _newImages.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _newImages[index],
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeNewImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Add Photos Button
                  OutlinedButton.icon(
                    onPressed:
                        (_existingImageUrls.length + _newImages.length) < 5
                            ? _pickImages
                            : null,
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('Add More Photos'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      foregroundColor: const Color(0xFF2563EB),
                      side: const BorderSide(color: Color(0xFF2563EB)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Rest of the form (same as create listing)
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title *',
                prefixIcon: const Icon(Icons.title),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLength: 100,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description *',
                prefixIcon: const Icon(Icons.description),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: 5,
              maxLength: 500,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: 'Price *',
                prefixIcon: const Icon(Icons.attach_money),
                prefixText: '₱ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a price';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: _isNegotiable,
                    onChanged: (value) {
                      setState(() => _isNegotiable = value ?? false);
                    },
                    activeColor: const Color(0xFF2563EB),
                  ),
                  const Expanded(
                    child: Text('Price is negotiable',
                        style: TextStyle(fontSize: 15)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Category, Condition, etc. (same as create)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: _categories.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : DropdownButtonFormField<String>(
                      value: _selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Category *',
                        prefixIcon: Icon(Icons.category),
                        border: InputBorder.none,
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category.id,
                          child: Text(category.categoryName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedCategoryId = value);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a category';
                        }
                        return null;
                      },
                    ),
            ),
            const SizedBox(height: 20),

            // Condition
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Condition *',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Brand New'),
                        selected: _selectedCondition == ItemCondition.brandNew,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() =>
                                _selectedCondition = ItemCondition.brandNew);
                          }
                        },
                        selectedColor: const Color(0xFF2563EB),
                        labelStyle: TextStyle(
                          color: _selectedCondition == ItemCondition.brandNew
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                      ChoiceChip(
                        label: const Text('Like New'),
                        selected: _selectedCondition == ItemCondition.likeNew,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() =>
                                _selectedCondition = ItemCondition.likeNew);
                          }
                        },
                        selectedColor: const Color(0xFF2563EB),
                        labelStyle: TextStyle(
                          color: _selectedCondition == ItemCondition.likeNew
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                      ChoiceChip(
                        label: const Text('Used'),
                        selected: _selectedCondition == ItemCondition.used,
                        onSelected: (selected) {
                          if (selected) {
                            setState(
                                () => _selectedCondition = ItemCondition.used);
                          }
                        },
                        selectedColor: const Color(0xFF2563EB),
                        labelStyle: TextStyle(
                          color: _selectedCondition == ItemCondition.used
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Pickup Location (Optional)',
                prefixIcon: const Icon(Icons.location_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: _allowsDelivery,
                    onChanged: (value) {
                      setState(() => _allowsDelivery = value ?? false);
                    },
                    activeColor: const Color(0xFF2563EB),
                  ),
                  const Expanded(
                    child: Text('I can deliver this item',
                        style: TextStyle(fontSize: 15)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitUpdate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Update Listing',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

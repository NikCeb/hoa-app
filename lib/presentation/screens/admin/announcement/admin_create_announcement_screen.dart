import 'package:flutter/material.dart';
import '../../../../data/models/announcement.dart';
import '../../../../data/repositories/announcement_repository.dart';

class AdminCreateAnnouncementScreen extends StatefulWidget {
  const AdminCreateAnnouncementScreen({Key? key}) : super(key: key);

  @override
  State<AdminCreateAnnouncementScreen> createState() =>
      _AdminCreateAnnouncementScreenState();
}

class _AdminCreateAnnouncementScreenState
    extends State<AdminCreateAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  AnnouncementType _selectedType = AnnouncementType.general;
  TargetAudience _selectedAudience = TargetAudience.all;
  bool _isCritical = false;
  bool _hasExpiration = false;
  DateTime? _expirationDate;
  bool _isSubmitting = false;

  final _repository = AnnouncementRepository();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _selectExpirationDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _expirationDate = date;
      });
    }
  }

  Future<void> _submitAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;

    if (_hasExpiration && _expirationDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an expiration date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _repository.createAnnouncement(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        type: _selectedType,
        isCritical: _isCritical,
        targetAudience: _selectedAudience,
        expiresAt: _hasExpiration ? _expirationDate : null,
        tags: [],
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Announcement created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create announcement: $e'),
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
          'Create Announcement',
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
            // Title Input
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title *',
                hintText: 'Enter announcement title',
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
                if (value.trim().length < 5) {
                  return 'Title must be at least 5 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Content Input
            TextFormField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: 'Content *',
                hintText: 'Enter announcement content',
                prefixIcon: const Icon(Icons.description),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: 6,
              maxLength: 1000,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter content';
                }
                if (value.trim().length < 10) {
                  return 'Content must be at least 10 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Type Selection
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
                    'Announcement Type *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildTypeChip(
                        label: 'General',
                        icon: '📢',
                        type: AnnouncementType.general,
                      ),
                      _buildTypeChip(
                        label: 'Urgent',
                        icon: '🚨',
                        type: AnnouncementType.urgent,
                      ),
                      _buildTypeChip(
                        label: 'Event',
                        icon: '📅',
                        type: AnnouncementType.event,
                      ),
                      _buildTypeChip(
                        label: 'Maintenance',
                        icon: '🔧',
                        type: AnnouncementType.maintenance,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Target Audience
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
                    'Target Audience *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildAudienceChip(
                        label: 'Everyone',
                        audience: TargetAudience.all,
                      ),
                      _buildAudienceChip(
                        label: 'Residents',
                        audience: TargetAudience.residents,
                      ),
                      _buildAudienceChip(
                        label: 'Owners',
                        audience: TargetAudience.owners,
                      ),
                      _buildAudienceChip(
                        label: 'Tenants',
                        audience: TargetAudience.tenants,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Critical Toggle
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
                    value: _isCritical,
                    onChanged: (value) {
                      setState(() {
                        _isCritical = value ?? false;
                      });
                    },
                    activeColor: Colors.red,
                  ),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mark as Critical',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Critical announcements appear at the top',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Expiration Toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _hasExpiration,
                        onChanged: (value) {
                          setState(() {
                            _hasExpiration = value ?? false;
                            if (!_hasExpiration) {
                              _expirationDate = null;
                            }
                          });
                        },
                        activeColor: const Color(0xFF2563EB),
                      ),
                      const Expanded(
                        child: Text(
                          'Set Expiration Date',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_hasExpiration) ...[
                    const Divider(),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _selectExpirationDate,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                color: Color(0xFF2563EB)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _expirationDate == null
                                    ? 'Select expiration date'
                                    : '${_expirationDate!.day}/${_expirationDate!.month}/${_expirationDate!.year}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _expirationDate == null
                                      ? Colors.grey[600]
                                      : Colors.black87,
                                ),
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitAnnouncement,
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
                        'Create Announcement',
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

  Widget _buildTypeChip({
    required String label,
    required String icon,
    required AnnouncementType type,
  }) {
    final isSelected = _selectedType == type;

    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedType = type);
        }
      },
      selectedColor: const Color(0xFF2563EB),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildAudienceChip({
    required String label,
    required TargetAudience audience,
  }) {
    final isSelected = _selectedAudience == audience;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedAudience = audience);
        }
      },
      selectedColor: const Color(0xFF2563EB),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}

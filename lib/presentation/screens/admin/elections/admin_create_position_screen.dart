import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../data/models/election.dart';
import '../../../../data/repositories/elections_repository.dart';

class AdminCreatePositionScreen extends StatefulWidget {
  final Election election;

  const AdminCreatePositionScreen({
    Key? key,
    required this.election,
  }) : super(key: key);

  @override
  State<AdminCreatePositionScreen> createState() =>
      _AdminCreatePositionScreenState();
}

class _AdminCreatePositionScreenState extends State<AdminCreatePositionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _maxWinnersController = TextEditingController(text: '1');
  final _sortOrderController = TextEditingController();

  DateTime? _nominationStart;
  DateTime? _nominationEnd;
  DateTime? _votingStart;
  DateTime? _votingEnd;

  TimeOfDay? _nominationStartTime;
  TimeOfDay? _nominationEndTime;
  TimeOfDay? _votingStartTime;
  TimeOfDay? _votingEndTime;

  bool _isSubmitting = false;

  final _repository = ElectionsRepository();

  @override
  void dispose() {
    _nameController.dispose();
    _maxWinnersController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, String type) async {
    DateTime initialDate = DateTime.now();
    DateTime firstDate = DateTime.now();
    DateTime lastDate = DateTime.now().add(const Duration(days: 365));

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (date != null) {
      setState(() {
        switch (type) {
          case 'nominationStart':
            _nominationStart = date;
            break;
          case 'nominationEnd':
            _nominationEnd = date;
            break;
          case 'votingStart':
            _votingStart = date;
            break;
          case 'votingEnd':
            _votingEnd = date;
            break;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, String type) async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );

    if (time != null) {
      setState(() {
        switch (type) {
          case 'nominationStart':
            _nominationStartTime = time;
            break;
          case 'nominationEnd':
            _nominationEndTime = time;
            break;
          case 'votingStart':
            _votingStartTime = time;
            break;
          case 'votingEnd':
            _votingEndTime = time;
            break;
        }
      });
    }
  }

  Future<void> _submitPosition() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate dates
    if (_nominationStart == null ||
        _nominationEnd == null ||
        _votingStart == null ||
        _votingEnd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select all dates'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate times
    if (_nominationStartTime == null ||
        _nominationEndTime == null ||
        _votingStartTime == null ||
        _votingEndTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select all times'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final nominationStart = DateTime(
        _nominationStart!.year,
        _nominationStart!.month,
        _nominationStart!.day,
        _nominationStartTime!.hour,
        _nominationStartTime!.minute,
      );

      final nominationEnd = DateTime(
        _nominationEnd!.year,
        _nominationEnd!.month,
        _nominationEnd!.day,
        _nominationEndTime!.hour,
        _nominationEndTime!.minute,
      );

      final votingStart = DateTime(
        _votingStart!.year,
        _votingStart!.month,
        _votingStart!.day,
        _votingStartTime!.hour,
        _votingStartTime!.minute,
      );

      final votingEnd = DateTime(
        _votingEnd!.year,
        _votingEnd!.month,
        _votingEnd!.day,
        _votingEndTime!.hour,
        _votingEndTime!.minute,
      );

      // Validate logical order
      if (nominationEnd.isBefore(nominationStart)) {
        throw 'Nomination end must be after nomination start';
      }
      if (votingStart.isBefore(nominationEnd)) {
        throw 'Voting start must be after nomination end';
      }
      if (votingEnd.isBefore(votingStart)) {
        throw 'Voting end must be after voting start';
      }

      await _repository.createPositionForElection(
        electionId: widget.election.id,
        positionName: _nameController.text.trim(),
        maxWinners: int.parse(_maxWinnersController.text.trim()),
        sortOrder: int.parse(_sortOrderController.text.trim()),
        nominationStart: nominationStart,
        nominationEnd: nominationEnd,
        votingStart: votingStart,
        votingEnd: votingEnd,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Position created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
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
        backgroundColor: const Color(0xFF8B5CF6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Position',
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
            // Election Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF8B5CF6).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.how_to_vote,
                    color: Color(0xFF8B5CF6),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.election.electionName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8B5CF6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Position Name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Position Name *',
                hintText: 'e.g., President, Treasurer',
                prefixIcon: const Icon(Icons.workspace_premium),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter position name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Max Winners & Sort Order
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _maxWinnersController,
                    decoration: InputDecoration(
                      labelText: 'Max Winners *',
                      prefixIcon: const Icon(Icons.numbers),
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
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _sortOrderController,
                    decoration: InputDecoration(
                      labelText: 'Sort Order *',
                      prefixIcon: const Icon(Icons.sort),
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
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Nomination Period
            _buildPeriodSection(
              title: 'Nomination Period',
              icon: Icons.person_add,
              color: Colors.blue,
              startDate: _nominationStart,
              endDate: _nominationEnd,
              startTime: _nominationStartTime,
              endTime: _nominationEndTime,
              onSelectStartDate: () => _selectDate(context, 'nominationStart'),
              onSelectEndDate: () => _selectDate(context, 'nominationEnd'),
              onSelectStartTime: () => _selectTime(context, 'nominationStart'),
              onSelectEndTime: () => _selectTime(context, 'nominationEnd'),
            ),
            const SizedBox(height: 24),

            // Voting Period
            _buildPeriodSection(
              title: 'Voting Period',
              icon: Icons.how_to_vote,
              color: Colors.green,
              startDate: _votingStart,
              endDate: _votingEnd,
              startTime: _votingStartTime,
              endTime: _votingEndTime,
              onSelectStartDate: () => _selectDate(context, 'votingStart'),
              onSelectEndDate: () => _selectDate(context, 'votingEnd'),
              onSelectStartTime: () => _selectTime(context, 'votingStart'),
              onSelectEndTime: () => _selectTime(context, 'votingEnd'),
            ),
            const SizedBox(height: 24),

            // Info Note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline,
                      color: Colors.orange, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Nomination period must end before voting period starts. Ensure adequate time for candidate approval.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitPosition,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add),
                label: Text(
                  _isSubmitting ? 'Creating...' : 'Create Position',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSection({
    required String title,
    required IconData icon,
    required Color color,
    required DateTime? startDate,
    required DateTime? endDate,
    required TimeOfDay? startTime,
    required TimeOfDay? endTime,
    required VoidCallback onSelectStartDate,
    required VoidCallback onSelectEndDate,
    required VoidCallback onSelectStartTime,
    required VoidCallback onSelectEndTime,
  }) {
    return Container(
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
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Start Date & Time
          const Text(
            'Start',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onSelectStartDate,
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    startDate == null
                        ? 'Date'
                        : '${startDate.month}/${startDate.day}/${startDate.year}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onSelectStartTime,
                  icon: const Icon(Icons.access_time, size: 18),
                  label: Text(
                    startTime == null ? 'Time' : startTime.format(context),
                    style: const TextStyle(fontSize: 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // End Date & Time
          const Text(
            'End',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onSelectEndDate,
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    endDate == null
                        ? 'Date'
                        : '${endDate.month}/${endDate.day}/${endDate.year}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onSelectEndTime,
                  icon: const Icon(Icons.access_time, size: 18),
                  label: Text(
                    endTime == null ? 'Time' : endTime.format(context),
                    style: const TextStyle(fontSize: 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../data/models/election.dart';
import '../../../../data/models/election_position.dart';

class UserNominateForPositionScreen extends StatefulWidget {
  final Election election;
  final ElectionPosition position;

  const UserNominateForPositionScreen({
    Key? key,
    required this.election,
    required this.position,
  }) : super(key: key);

  @override
  State<UserNominateForPositionScreen> createState() =>
      _UserNominateForPositionScreenState();
}

class _UserNominateForPositionScreenState
    extends State<UserNominateForPositionScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String _selectedOption = 'self'; // 'self' or 'other'
  String? _selectedUserId;
  List<Map<String, dynamic>> _residents = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadResidents();
  }

  Future<void> _loadResidents() async {
    try {
      print('🔍 Loading residents...');

      // Load verified residents with user accounts
      final residentsSnapshot =
          await _firestore.collection('master_residents').get();

      print('✅ Found ${residentsSnapshot.docs.length} master residents');

      final residents = <Map<String, dynamic>>[];

      for (var doc in residentsSnapshot.docs) {
        try {
          final data = doc.data();

          // Find linked user account
          final userSnapshot = await _firestore
              .collection('users')
              .where('masterResidentId', isEqualTo: doc.id)
              .limit(1)
              .get();

          if (userSnapshot.docs.isNotEmpty) {
            final userId = userSnapshot.docs.first.id;
            final userData = userSnapshot.docs.first.data();

            residents.add({
              'userId': userId,
              'firstName': userData['firstName'] ?? data['firstName'] ?? '',
              'lastName': userData['lastName'] ?? data['lastName'] ?? '',
              'lotNumber': userData['lotNumber'] ?? data['lotNumber'] ?? '',
            });
          }
        } catch (e) {
          print('❌ Error processing resident ${doc.id}: $e');
        }
      }

      print('✅ Total verified residents: ${residents.length}');

      if (mounted) {
        setState(() {
          _residents = residents;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading residents: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading residents: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitNomination() async {
    if (_selectedOption == 'other' && _selectedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a resident to nominate'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final currentUser = _auth.currentUser!;
      String targetUserId;
      String candidateName;
      String? lotNumber;

      if (_selectedOption == 'other') {
        // Nominating someone else
        targetUserId = _selectedUserId!;
        final resident =
            _residents.firstWhere((r) => r['userId'] == targetUserId);
        candidateName = '${resident['firstName']} ${resident['lastName']}';
        lotNumber = resident['lotNumber'];
      } else {
        // Nominating self
        targetUserId = currentUser.uid;
        final userDoc =
            await _firestore.collection('users').doc(currentUser.uid).get();
        final userData = userDoc.data()!;
        candidateName = '${userData['firstName']} ${userData['lastName']}';
        lotNumber = userData['lotNumber'];
      }

      // Check if already nominated
      final existingNomination = await _firestore
          .collection('elections_candidates')
          .where('electionId', isEqualTo: widget.election.id)
          .where('positionId', isEqualTo: widget.position.id)
          .where('userId', isEqualTo: targetUserId)
          .get();

      if (existingNomination.docs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _selectedOption == 'self'
                    ? 'You have already applied for this position'
                    : 'This person has already been nominated for this position',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Create candidate
      await _firestore.collection('elections_candidates').add({
        'electionId': widget.election.id,
        'positionId': widget.position.id,
        'userId': targetUserId,
        'candidateName': candidateName,
        'lotNumber': lotNumber,
        'photoUrl': null,
        'voteCount': 0,
        'status': 'PENDING',
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedOption == 'self'
                  ? 'Application submitted for approval!'
                  : 'Nomination submitted for approval!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error submitting nomination: $e');
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
          'Nominate Candidate',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Info Card
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
                        Icons.info_outline,
                        color: Color(0xFF8B5CF6),
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.position.positionName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF8B5CF6),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.election.electionName,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF8B5CF6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Selection Options
                const Text(
                  'Who do you want to nominate?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                // Self Option
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: _selectedOption == 'self'
                          ? const Color(0xFF8B5CF6)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: RadioListTile<String>(
                    value: 'self',
                    groupValue: _selectedOption,
                    onChanged: (value) {
                      setState(() => _selectedOption = value!);
                    },
                    activeColor: const Color(0xFF8B5CF6),
                    title: const Text(
                      'Apply for Myself',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      'Run for this position',
                      style: TextStyle(fontSize: 13),
                    ),
                    secondary: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.how_to_reg,
                        color: Color(0xFF8B5CF6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Other Option
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: _selectedOption == 'other'
                          ? const Color(0xFF8B5CF6)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: RadioListTile<String>(
                    value: 'other',
                    groupValue: _selectedOption,
                    onChanged: (value) {
                      setState(() => _selectedOption = value!);
                    },
                    activeColor: const Color(0xFF8B5CF6),
                    title: const Text(
                      'Nominate Someone Else',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      'Nominate a fellow resident',
                      style: TextStyle(fontSize: 13),
                    ),
                    secondary: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.person_add,
                        color: Color(0xFF8B5CF6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Resident Selection (only for 'other')
                if (_selectedOption == 'other') ...[
                  const Text(
                    'Select Resident',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_residents.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'No residents available to nominate',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedUserId,
                          isExpanded: true,
                          hint: const Text('Choose a resident'),
                          items: _residents.map((resident) {
                            return DropdownMenuItem<String>(
                              value: resident['userId'],
                              child: Text(
                                '${resident['firstName']} ${resident['lastName']} (Lot ${resident['lotNumber']})',
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedUserId = value);
                          },
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                ],

                // Notice
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.orange,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedOption == 'self'
                              ? 'Your application will be reviewed by the admin. You will be notified once approved.'
                              : 'The nomination will be sent to the admin for approval. The resident will be notified if approved.',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.orange,
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
                    onPressed: _isSubmitting ? null : _submitNomination,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            _selectedOption == 'self'
                                ? Icons.how_to_reg
                                : Icons.person_add,
                          ),
                    label: Text(
                      _isSubmitting
                          ? 'Submitting...'
                          : _selectedOption == 'self'
                              ? 'Submit Application'
                              : 'Submit Nomination',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

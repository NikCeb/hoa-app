import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../data/models/election.dart';
import '../../../../data/models/election_position.dart';
import '../../../../data/repositories/elections_repository.dart';

class UserNominateScreen extends StatefulWidget {
  final Election election;
  final bool isNominatingOther;

  const UserNominateScreen({
    Key? key,
    required this.election,
    required this.isNominatingOther,
  }) : super(key: key);

  @override
  State<UserNominateScreen> createState() => _UserNominateScreenState();
}

class _UserNominateScreenState extends State<UserNominateScreen> {
  final _repository = ElectionsRepository();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String? _selectedPositionId;
  String? _selectedUserId;
  List<ElectionPosition> _positions = [];
  List<Map<String, dynamic>> _residents = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      print('🔍 Starting to load data...');

      // Load positions
      print('📍 Loading positions...');
      final positions = await _repository.getActivePositions().first;
      print('✅ Loaded ${positions.length} positions');

      // Load verified residents
      print('👥 Loading residents from master_residents...');
      final residentsSnapshot = await _firestore
          .collection('master_residents')
          .get(); // Remove the where clause temporarily to see all data

      print('✅ Found ${residentsSnapshot.docs.length} master residents');

      final residents = <Map<String, dynamic>>[];

      for (var doc in residentsSnapshot.docs) {
        try {
          final data = doc.data();
          print('👤 Processing resident: ${doc.id}');

          // Check if this resident has a linked user account
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
            print(
                '✅ Added resident: ${userData['firstName']} ${userData['lastName']}');
          } else {
            print('⚠️ No user account found for master resident: ${doc.id}');
          }
        } catch (e) {
          print('❌ Error processing resident ${doc.id}: $e');
        }
      }

      print(
          '✅ Total verified residents with user accounts: ${residents.length}');

      if (mounted) {
        setState(() {
          _positions = positions;
          _residents = residents;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitNomination() async {
    if (_selectedPositionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a position'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (widget.isNominatingOther && _selectedUserId == null) {
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

      if (widget.isNominatingOther) {
        // Nominating someone else
        targetUserId = _selectedUserId!;
        final resident =
            _residents.firstWhere((r) => r['userId'] == targetUserId);
        candidateName = '${resident['firstName']} ${resident['lastName']}';
        lotNumber = resident['lotNumber'];
      } else {
        // Applying for self
        targetUserId = currentUser.uid;
        final userDoc =
            await _firestore.collection('users').doc(currentUser.uid).get();
        final userData = userDoc.data()!;
        candidateName = '${userData['firstName']} ${userData['lastName']}';
        lotNumber = userData['lotNumber'];
      }

      // Create candidate
      await _firestore.collection('elections_candidates').add({
        'electionId': widget.election.id,
        'positionId': _selectedPositionId!,
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
              widget.isNominatingOther
                  ? 'Nomination submitted for approval!'
                  : 'Application submitted for approval!',
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
        title: Text(
          widget.isNominatingOther ? 'Nominate Resident' : 'Apply for Position',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _positions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No Positions Available',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please wait for positions to be created',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : widget.isNominatingOther && _residents.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No Residents Available',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No verified residents with user accounts found',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
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
                              Icon(
                                widget.isNominatingOther
                                    ? Icons.person_add
                                    : Icons.how_to_reg,
                                color: const Color(0xFF8B5CF6),
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  widget.isNominatingOther
                                      ? 'Nominate a fellow resident for the ${widget.election.electionName}'
                                      : 'Apply to run for a position in the ${widget.election.electionName}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF8B5CF6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Position Selection
                        const Text(
                          'Select Position *',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
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
                              value: _selectedPositionId,
                              isExpanded: true,
                              hint: const Text('Choose a position'),
                              items: _positions.map((position) {
                                return DropdownMenuItem<String>(
                                  value: position.id,
                                  child: Text(position.positionName),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _selectedPositionId = value);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Resident Selection (only for nominating others)
                        if (widget.isNominatingOther) ...[
                          const Text(
                            'Select Resident *',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
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
                                  widget.isNominatingOther
                                      ? 'The nomination will be sent to the admin for approval. The resident will be notified if approved.'
                                      : 'Your application will be reviewed by the admin. You will be notified once approved.',
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
                                    widget.isNominatingOther
                                        ? Icons.person_add
                                        : Icons.how_to_reg,
                                  ),
                            label: Text(
                              _isSubmitting
                                  ? 'Submitting...'
                                  : widget.isNominatingOther
                                      ? 'Submit Nomination'
                                      : 'Submit Application',
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

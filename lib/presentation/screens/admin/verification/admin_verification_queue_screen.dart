import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminVerificationQueueScreen extends StatefulWidget {
  const AdminVerificationQueueScreen({Key? key}) : super(key: key);

  @override
  State<AdminVerificationQueueScreen> createState() =>
      _AdminVerificationQueueScreenState();
}

class _AdminVerificationQueueScreenState
    extends State<AdminVerificationQueueScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification Queue'),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('verification_queue')
            .where('status', isEqualTo: 'pending')
            .orderBy('requestedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final pendingRequests = snapshot.data!.docs;

          if (pendingRequests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No pending verifications',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All verification requests have been processed',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pendingRequests.length,
            itemBuilder: (context, index) {
              final doc = pendingRequests[index];
              final data = doc.data() as Map<String, dynamic>;

              return _buildVerificationCard(
                requestId: doc.id,
                data: data,
              );
            },
          );
        },
      ),
    );
  }

  // ============================================================================
  // VERIFICATION CARD
  // ============================================================================
  Widget _buildVerificationCard({
    required String requestId,
    required Map<String, dynamic> data,
  }) {
    final firstName = data['firstName'] ?? '';
    final lastName = data['lastName'] ?? '';
    final email = data['email'] ?? '';
    final block = data['block'] ?? '';
    final lotNumber = data['lotNumber'] ?? '';
    final phase = data['phase'] ?? '';
    final requestedAt = (data['requestedAt'] as Timestamp?)?.toDate();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Name and Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '$firstName $lastName',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (requestedAt != null)
                  Text(
                    _formatDate(requestedAt),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),

            // Email
            Row(
              children: [
                Icon(Icons.email_outlined,
                    size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    email,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Property Information
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.home_outlined,
                          size: 18, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      const Text(
                        'Requested Property',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$lotNumber, $block, $phase',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRejectDialog(requestId, data),
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showApproveDialog(requestId, data),
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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

  // ============================================================================
  // APPROVE VERIFICATION
  // ============================================================================
  void _showApproveDialog(String requestId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Approve Verification'),
        content: Text(
          'Approve ${data['firstName']} ${data['lastName']} for '
          '${data['lotNumber']}, ${data['block']}, ${data['phase']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _approveVerification(requestId, data);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  Future<void> _approveVerification(
    String requestId,
    Map<String, dynamic> data,
  ) async {
    try {
      final userId = data['userId'];

      // Check if lot exists in master_residents
      final masterSnapshot = await _firestore
          .collection('master_residents')
          .where('block', isEqualTo: data['block'])
          .where('lotNumber', isEqualTo: data['lotNumber'])
          .where('phase', isEqualTo: data['phase'])
          .limit(1)
          .get();

      String? masterResidentId;

      if (masterSnapshot.docs.isNotEmpty) {
        // Lot exists - use existing document
        masterResidentId = masterSnapshot.docs.first.id;
      } else {
        // Lot doesn't exist - create new master_residents document
        final newMasterDoc =
            await _firestore.collection('master_residents').add({
          'firstName': data['firstName'],
          'lastName': data['lastName'],
          'block': data['block'],
          'lotNumber': data['lotNumber'],
          'phase': data['phase'],
          'status': 'occupied',
          'residentId': userId,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        masterResidentId = newMasterDoc.id;
      }

      // Use batch to update everything atomically
      final batch = _firestore.batch();

      // Update user: Verify and connect to lot
      final userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {
        'isVerified': true,
        'lotId': masterResidentId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update master_residents: Connect to user
      final masterRef =
          _firestore.collection('master_residents').doc(masterResidentId);
      batch.update(masterRef, {
        'residentId': userId,
        'status': 'occupied',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update verification request: Mark as approved
      final requestRef =
          _firestore.collection('verification_queue').doc(requestId);
      batch.update(requestRef, {
        'status': 'approved',
        'processedAt': FieldValue.serverTimestamp(),
        'processedBy': _auth.currentUser?.uid,
      });

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Verified ${data['firstName']} ${data['lastName']}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving verification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ============================================================================
  // REJECT VERIFICATION
  // ============================================================================
  void _showRejectDialog(String requestId, Map<String, dynamic> data) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reject Verification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reject verification for ${data['firstName']} ${data['lastName']}?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Rejection Reason',
                hintText: 'e.g., Property information does not match records',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a rejection reason'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              Navigator.pop(context);
              await _rejectVerification(
                requestId,
                data,
                reasonController.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _rejectVerification(
    String requestId,
    Map<String, dynamic> data,
    String reason,
  ) async {
    try {
      // Update verification request
      await _firestore.collection('verification_queue').doc(requestId).update({
        'status': 'rejected',
        'rejectionReason': reason,
        'processedAt': FieldValue.serverTimestamp(),
        'processedBy': _auth.currentUser?.uid,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Rejected verification for ${data['firstName']} ${data['lastName']}',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting verification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

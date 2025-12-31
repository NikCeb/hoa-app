import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';

/// Admin Verification & Master List Screen
///
/// COMPLETE FIXED VERSION - NO HARDCODED DATA!
///
/// Two tabs:
/// 1. Manual Verification - Approve/reject verification requests (REAL FIREBASE DATA)
/// 2. Master List - View/add/edit official resident directory (WITH ADD BUTTON)
class AdminVerificationQueueScreen extends StatefulWidget {
  const AdminVerificationQueueScreen({Key? key}) : super(key: key);

  @override
  State<AdminVerificationQueueScreen> createState() =>
      _AdminVerificationQueueScreenState();
}

class _AdminVerificationQueueScreenState
    extends State<AdminVerificationQueueScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Verification & Master List',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          tabs: const [
            Tab(text: 'Manual Verification'),
            Tab(text: 'Master List'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVerificationTab(),
          _buildMasterListTab(),
        ],
      ),
    );
  }

  // ============================================
  // TAB 1: VERIFICATION QUEUE (REAL FIREBASE DATA)
  // ============================================
  Widget _buildVerificationTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('verification_requests')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data!.docs;

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No Pending Verifications',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'All verification requests have been processed',
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
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            final data = request.data() as Map<String, dynamic>;
            return _buildVerificationCard(request.id, data);
          },
        );
      },
    );
  }

  Widget _buildVerificationCard(String requestId, Map<String, dynamic> data) {
    final userName = data['userName'] ?? 'Unknown';
    final email = data['email'] ?? '';
    final claimedLot = data['claimedLotNumber'] ?? '';
    final userId = data['userId'] ?? '';
    final idPhotoUrl = data['idPhotoUrl'];
    final timestamp = data['createdAt'] as Timestamp?;
    final dateRegistered = timestamp != null
        ? '${timestamp.toDate().month}/${timestamp.toDate().day}/${timestamp.toDate().year}'
        : 'Unknown';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primaryBlue,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        claimedLot,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Email
            Text(
              email,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),

            // Registration Date
            Text(
              'Registered: $dateRegistered',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
              ),
            ),

            // ID Photo (if available)
            if (idPhotoUrl != null) ...[
              const SizedBox(height: 12),
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    idPhotoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(Icons.image, color: Colors.grey[400]),
                      );
                    },
                  ),
                ),
              ),
            ],

            // Check against Master List
            const SizedBox(height: 12),
            FutureBuilder<QuerySnapshot>(
              future: _firestore
                  .collection('master_residents')
                  .where('lotNumber', isEqualTo: claimedLot)
                  .limit(1)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  final masterData =
                      snapshot.data!.docs.first.data() as Map<String, dynamic>;
                  final masterName = masterData['name'] ?? '';
                  final similarity = _checkNameSimilarity(userName, masterName);

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: similarity > 0.7
                          ? Colors.green[50]
                          : Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: similarity > 0.7
                            ? Colors.green[200]!
                            : Colors.orange[200]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          similarity > 0.7 ? Icons.check_circle : Icons.warning,
                          color: similarity > 0.7
                              ? Colors.green[700]
                              : Colors.orange[700],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Master List Match',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: similarity > 0.7
                                      ? Colors.green[700]
                                      : Colors.orange[700],
                                ),
                              ),
                              Text(
                                'Registered: $masterName',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: similarity > 0.7
                                      ? Colors.green[700]
                                      : Colors.orange[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No match in Master List for lot: $claimedLot',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.red[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _approveVerification(requestId, userId, claimedLot),
                    icon: const Icon(Icons.check, size: 20),
                    label: const Text(
                      'Approve',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _rejectVerification(requestId, userId),
                    icon: const Icon(Icons.close, size: 20),
                    label: const Text(
                      'Reject',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
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

  // ============================================
  // TAB 2: MASTER LIST WITH ADD BUTTON
  // ============================================
  Widget _buildMasterListTab() {
    return Column(
      children: [
        // Action Buttons
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showAddResidentDialog,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add Resident'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('CSV upload feature coming soon!'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload CSV'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Master List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('master_residents')
                .orderBy('lotNumber')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final residents = snapshot.data!.docs;

              if (residents.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Residents in Master List',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add residents manually or upload a CSV file',
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
                itemCount: residents.length,
                itemBuilder: (context, index) {
                  final resident = residents[index];
                  final data = resident.data() as Map<String, dynamic>;
                  return _buildMasterListCard(resident.id, data);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMasterListCard(String residentId, Map<String, dynamic> data) {
    final name = data['name'] ?? 'Unknown';
    final lotNumber = data['lotNumber'] ?? '';
    final email = data['email'] ?? '';
    final status = data['status'] ?? 'available';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: status == 'occupied' ? Colors.green : Colors.grey,
          child: Icon(
            status == 'occupied' ? Icons.check : Icons.home_outlined,
            color: Colors.white,
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lotNumber),
            if (email.isNotEmpty) Text(email),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: status == 'occupied' ? Colors.green[50] : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status == 'occupied' ? 'Verified' : 'Available',
            style: TextStyle(
              color:
                  status == 'occupied' ? Colors.green[700] : Colors.grey[700],
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: () => _showResidentDetails(residentId, data),
      ),
    );
  }

  // ============================================
  // HELPER FUNCTIONS
  // ============================================

  double _checkNameSimilarity(String name1, String name2) {
    final n1 = name1.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    final n2 = name2.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');

    if (n1 == n2) return 1.0;
    if (n2.contains(n1) || n1.contains(n2)) return 0.8;

    int matches = 0;
    for (int i = 0; i < n1.length && i < n2.length; i++) {
      if (n1[i] == n2[i]) matches++;
    }
    return matches / (n1.length > n2.length ? n1.length : n2.length);
  }

  Future<void> _approveVerification(
      String requestId, String userId, String claimedLot) async {
    try {
      // Find matching master resident
      final masterQuery = await _firestore
          .collection('master_residents')
          .where('lotNumber', isEqualTo: claimedLot)
          .limit(1)
          .get();

      if (masterQuery.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No matching lot in Master List'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final masterDoc = masterQuery.docs.first;

      // Batch update - CONNECTS USER TO LOT!
      final batch = _firestore.batch();

      // 1. Update verification request
      batch.update(
          _firestore.collection('verification_requests').doc(requestId), {
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
      });

      // 2. Update user - LINK TO LOT
      batch.update(_firestore.collection('users').doc(userId), {
        'isVerified': true,
        'lotId': masterDoc.id, // ← CONNECTS USER TO MASTER RESIDENT
        'verifiedAt': FieldValue.serverTimestamp(),
      });

      // 3. Update master resident - MARK AS OCCUPIED
      batch
          .update(_firestore.collection('master_residents').doc(masterDoc.id), {
        'status': 'occupied',
        'residentId': userId, // ← CONNECTS MASTER RESIDENT TO USER
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ User verified and connected to lot!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectVerification(String requestId, String userId) async {
    try {
      await _firestore
          .collection('verification_requests')
          .doc(requestId)
          .update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification rejected'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddResidentDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final lotController = TextEditingController();
    String status = 'available';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Resident to Master List'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: lotController,
                decoration: const InputDecoration(
                  labelText: 'Lot Number *',
                  hintText: 'e.g. Lot 1-A or Block 1, Lot 8',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'available', child: Text('Available')),
                  DropdownMenuItem(value: 'occupied', child: Text('Occupied')),
                  DropdownMenuItem(value: 'reserved', child: Text('Reserved')),
                ],
                onChanged: (value) {
                  status = value ?? 'available';
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
            onPressed: () async {
              if (nameController.text.trim().isEmpty ||
                  lotController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Name and Lot Number are required')),
                );
                return;
              }

              try {
                await _firestore.collection('master_residents').add({
                  'name': nameController.text.trim(),
                  'email': emailController.text.trim(),
                  'phone': phoneController.text.trim(),
                  'lotNumber': lotController.text.trim(),
                  'status': status,
                  'createdAt': FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Resident added to Master List!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showResidentDetails(String residentId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(data['name'] ?? 'Resident Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lot: ${data['lotNumber'] ?? ''}'),
            Text('Email: ${data['email'] ?? 'N/A'}'),
            Text('Phone: ${data['phone'] ?? 'N/A'}'),
            Text('Status: ${data['status'] ?? 'available'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';

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
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Verification & Queue',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Review user registrations',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Manual Verification (3)'),
            Tab(text: 'Payment Queue (0)'),
            Tab(text: 'Master List (8)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildManualVerificationTab(),
          _buildPaymentQueueTab(),
          _buildMasterListTab(),
        ],
      ),
    );
  }

  Widget _buildManualVerificationTab() {
    // Sample pending verifications
    final pendingUsers = [
      {
        'name': 'Juan dela Cruz',
        'houseNo': 'Lot 1-A',
        'email': 'juan.delacruz@email.com',
        'dateRegistered': 'Nov 28, 2024',
        'reason': 'Name spelling mismatch',
        'uid': 'user1',
      },
      {
        'name': 'Maria R Santos',
        'houseNo': 'Lot 2-B',
        'email': 'maria.santos@email.com',
        'dateRegistered': 'Nov 29, 2024',
        'reason': 'Middle initial not in master list',
        'uid': 'user2',
      },
      {
        'name': 'Pedro Reyes Jr',
        'houseNo': 'Lot 3-C',
        'email': 'pedro.reyes@email.com',
        'dateRegistered': 'Nov 30, 2024',
        'reason': 'Suffix not in master list',
        'uid': 'user3',
      },
    ];

    return Column(
      children: [
        // Security Notice
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange[800]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Security Notice: These users have submitted information that doesn\'t exactly match the Master List. Review carefully before approving.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[900],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Pending List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: pendingUsers.length,
            itemBuilder: (context, index) {
              return _buildVerificationCard(pendingUsers[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationCard(Map<String, dynamic> user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Text(
                      user['name'][0],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user['houseNo'],
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Details
            _buildDetailRow(Icons.email_outlined, user['email']),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.calendar_today, user['dateRegistered']),
            const SizedBox(height: 12),

            // Reason Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.orange[800]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      user['reason'],
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange[900],
                        fontWeight: FontWeight.w500,
                      ),
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
                  child: ElevatedButton.icon(
                    onPressed: () => _approveUser(user),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectUser(user),
                    icon: const Icon(Icons.cancel, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentQueueTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Pending Payment Verifications',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All payment submissions are up to date',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterListTab() {
    // Sample master list
    final masterList = [
      {'lot': 'Lot 1-A', 'name': 'Juan Dela Cruz', 'status': 'Verified'},
      {'lot': 'Lot 1-B', 'name': 'Maria Santos', 'status': 'Verified'},
      {'lot': 'Lot 2-A', 'name': 'Pedro Reyes', 'status': 'Verified'},
      {'lot': 'Lot 2-B', 'name': 'Rosa Mendoza', 'status': 'Verified'},
      {'lot': 'Lot 3-A', 'name': 'Luis Garcia', 'status': 'Pending'},
      {'lot': 'Lot 3-B', 'name': 'Anna Cruz', 'status': 'Verified'},
      {'lot': 'Lot 4-A', 'name': 'Roberto Tan', 'status': 'Verified'},
      {'lot': 'Lot 4-B', 'name': 'Carmen Flores', 'status': 'Verified'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: masterList.length,
      itemBuilder: (context, index) {
        final resident = masterList[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: resident['status'] == 'Verified'
                  ? Colors.green[100]
                  : Colors.orange[100],
              child: Icon(
                resident['status'] == 'Verified' ? Icons.check : Icons.pending,
                color: resident['status'] == 'Verified'
                    ? Colors.green
                    : Colors.orange,
                size: 20,
              ),
            ),
            title: Text(
              resident['name']!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              resident['lot']!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: resident['status'] == 'Verified'
                    ? Colors.green[50]
                    : Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                resident['status']!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: resident['status'] == 'Verified'
                      ? Colors.green[700]
                      : Colors.orange[700],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _approveUser(Map<String, dynamic> user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve User'),
        content: Text(
          'Approve ${user['name']} for registration?\n\nThey will be granted access to the system.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // TODO: Update user status in Firestore
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user['name']} approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _rejectUser(Map<String, dynamic> user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject User'),
        content: Text(
          'Reject ${user['name']}\'s registration?\n\nThey will need to register again with correct information.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // TODO: Reject user in Firestore
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user['name']} rejected'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

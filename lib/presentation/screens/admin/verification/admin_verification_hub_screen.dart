import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_add_to_master_list_screen.dart';
import 'admin_upload_master_list_screen.dart';
import 'admin_master_list_detail_screen.dart';

class AdminVerificationHubScreen extends StatefulWidget {
  const AdminVerificationHubScreen({Key? key}) : super(key: key);

  @override
  State<AdminVerificationHubScreen> createState() =>
      _AdminVerificationHubScreenState();
}

class _AdminVerificationHubScreenState
    extends State<AdminVerificationHubScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Track which view is active: 'queue' or 'master'
  String _activeView = 'queue';

  String _searchQuery = '';
  String _selectedFilter = 'all';

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
          'Resident Management',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildToggleCards(),
          Expanded(
            child: _activeView == 'queue'
                ? _buildVerificationQueueView()
                : _buildMasterListView(),
          ),
        ],
      ),
      floatingActionButton: _activeView == 'master'
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  heroTag: 'upload',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const AdminUploadMasterListScreen(),
                      ),
                    );
                  },
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF2563EB),
                  child: const Icon(Icons.upload_file),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  heroTag: 'add',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const AdminAddToMasterlistScreen(),
                      ),
                    );
                  },
                  backgroundColor: const Color(0xFF2563EB),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add Resident'),
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildToggleCards() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              title: 'Pending',
              subtitle: 'Verifications',
              icon: Icons.pending_actions,
              color: Colors.orange,
              isActive: _activeView == 'queue',
              onTap: () {
                setState(() {
                  _activeView = 'queue';
                });
              },
              stream: _firestore
                  .collection('users')
                  .where('isVerified', isEqualTo: false)
                  .snapshots(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              title: 'Residents',
              subtitle: 'Master List',
              icon: Icons.people,
              color: const Color(0xFF2563EB),
              isActive: _activeView == 'master',
              onTap: () {
                setState(() {
                  _activeView = 'master';
                });
              },
              stream: _firestore.collection('master_residents').snapshots(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
    required Stream<QuerySnapshot> stream,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = MediaQuery.of(context).size.height;

        return SizedBox(
          height: screenHeight * 0.16, // smaller footprint
          child: StreamBuilder<QuerySnapshot>(
            stream: stream,
            builder: (context, snapshot) {
              final count = snapshot.hasData ? snapshot.data!.docs.length : 0;

              return Card(
                elevation: isActive ? 6 : 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: isActive
                      ? BorderSide(color: color, width: 2)
                      : BorderSide.none,
                ),
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: isActive
                          ? LinearGradient(
                              colors: [color, color.withOpacity(0.75)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        /// ICON + COUNT INLINE
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              icon,
                              size: 28,
                              color: isActive ? Colors.white : color,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              count.toString(),
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: isActive ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isActive ? Colors.white : Colors.grey[700],
                          ),
                        ),

                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 11,
                            color: isActive ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // VERIFICATION QUEUE VIEW
  Widget _buildVerificationQueueView() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .where('isVerified', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final pendingUsers = snapshot.data?.docs ?? [];

        if (pendingUsers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline,
                    size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No Pending Verifications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'All users have been verified',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pendingUsers.length,
          itemBuilder: (context, index) {
            final doc = pendingUsers[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildVerificationCard(doc.id, data);
          },
        );
      },
    );
  }

  Widget _buildVerificationCard(String userId, Map<String, dynamic> userData) {
    final name = userData['firstName'] != null && userData['lastName'] != null
        ? '${userData['firstName']} ${userData['lastName']}'
        : userData['name'] ?? 'Unknown User';
    final email = userData['email'] ?? 'No email';
    final phone = userData['phone'] ?? 'No phone';
    final lotNumber = userData['lotNumber'] ?? 'No lot assigned';
    final createdAt = (userData['createdAt'] as Timestamp?)?.toDate();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.orange[100],
                  child: Text(
                    name[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (createdAt != null)
                        Text(
                          _formatTimeAgo(createdAt),
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'PENDING',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.email_outlined, 'Email', email),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.phone_outlined, 'Phone', phone),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.home_outlined, 'Lot Number', lotNumber),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveUser(userId, userData),
                    icon: const Icon(Icons.check_circle, size: 20),
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
                    onPressed: () => _rejectUser(userId, name),
                    icon: const Icon(Icons.cancel, size: 20),
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

  // MASTER LIST VIEW
  Widget _buildMasterListView() {
    return Column(
      children: [
        _buildSearchBar(),
        _buildFilterChips(),
        Expanded(child: _buildResidentsList()),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
        decoration: InputDecoration(
          hintText: 'Search by name or lot number...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip('All', 'all'),
          const SizedBox(width: 8),
          _buildFilterChip('Occupied', 'occupied'),
          const SizedBox(width: 8),
          _buildFilterChip('Available', 'available'),
          const SizedBox(width: 8),
          _buildFilterChip('Reserved', 'reserved'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF2563EB),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      checkmarkColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildResidentsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('master_residents')
          .orderBy('lotNumber')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text('Error loading residents',
                    style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var residents = snapshot.data!.docs;

        if (_selectedFilter != 'all') {
          residents = residents
              .where((doc) => doc['status'] == _selectedFilter)
              .toList();
        }

        if (_searchQuery.isNotEmpty) {
          residents = residents.where((doc) {
            final firstName = (doc['firstName'] ?? '').toString().toLowerCase();
            final lastName = (doc['lastName'] ?? '').toString().toLowerCase();
            final lotNumber = doc['lotNumber'].toString();
            final fullName = '$firstName $lastName';
            return fullName.contains(_searchQuery) ||
                lotNumber.contains(_searchQuery);
          }).toList();
        }

        if (residents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty || _selectedFilter != 'all'
                      ? 'No residents found'
                      : 'No residents yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  _searchQuery.isNotEmpty || _selectedFilter != 'all'
                      ? 'Try adjusting your search or filter'
                      : 'Add residents to get started',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
          itemCount: residents.length,
          itemBuilder: (context, index) {
            return _buildResidentCard(residents[index]);
          },
        );
      },
    );
  }

  Widget _buildResidentCard(QueryDocumentSnapshot resident) {
    final data = resident.data() as Map<String, dynamic>;
    final firstName = data['firstName'] ?? '';
    final lastName = data['lastName'] ?? '';
    final email = data['email'] ?? '';
    final lotNumber = data['lotNumber'] ?? 0;
    final phase = data['phase'] ?? '';
    final status = data['status'] ?? 'available';

    final initials =
        '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          final data = resident.data() as Map<String, dynamic>;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminMasterListDetailScreen(
                userId: resident.id,
                userData: data,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFF2563EB).withOpacity(0.1),
                child: Text(
                  initials.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$firstName $lastName',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _buildStatusBadge(status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.home, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Lot $lotNumber',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (phase.isNotEmpty) ...[
                          Text(
                            ' • $phase',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[600]),
                          ),
                        ],
                      ],
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.email, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              email,
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey[600]),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (status) {
      case 'occupied':
        bgColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green.shade700;
        icon = Icons.check_circle;
        break;
      case 'reserved':
        bgColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange.shade700;
        icon = Icons.bookmark;
        break;
      default:
        bgColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue.shade700;
        icon = Icons.home_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // HELPER METHODS
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _approveUser(
      String userId, Map<String, dynamic> userData) async {
    try {
      final lotNumber = userData['lotNumber'];
      if (lotNumber == null || lotNumber.toString().trim().isEmpty) {
        _showErrorDialog('Cannot approve user without lot assignment');
        return;
      }

      int lotId;
      if (lotNumber is int) {
        lotId = lotNumber;
      } else {
        final lotStr = lotNumber.toString();
        if (lotStr.startsWith('master_')) {
          lotId = int.parse(lotStr.replaceAll('master_', ''));
        } else {
          lotId = int.tryParse(lotStr) ?? 0;
        }
      }

      if (lotId == 0) {
        _showErrorDialog('Invalid lot number format');
        return;
      }

      final masterQuery = await _firestore
          .collection('master_residents')
          .where('lotNumber', isEqualTo: lotId)
          .limit(1)
          .get();

      if (masterQuery.docs.isEmpty) {
        _showErrorDialog('No matching lot found in master residents');
        return;
      }

      final masterDoc = masterQuery.docs.first;
      final masterData = masterDoc.data();

      if (masterData['status'] == 'occupied' &&
          masterData['residentId'] != null &&
          masterData['residentId'] != userId) {
        _showErrorDialog('Lot ${masterData['lotNumber']} is already occupied');
        return;
      }

      final batch = _firestore.batch();

      batch.update(_firestore.collection('users').doc(userId), {
        'isVerified': true,
        'verifiedAt': FieldValue.serverTimestamp(),
        'lotId': masterDoc.id,
      });

      batch
          .update(_firestore.collection('master_residents').doc(masterDoc.id), {
        'residentId': userId,
        'status': 'occupied',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${userData['firstName'] ?? 'User'} approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error approving user: $e');
      }
    }
  }

  Future<void> _rejectUser(String userId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject User'),
        content: Text(
            'Are you sure you want to reject $name? This will delete their account.'),
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

    if (confirmed == true) {
      try {
        await _firestore.collection('users').doc(userId).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$name rejected and removed'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          _showErrorDialog('Error rejecting user: $e');
        }
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

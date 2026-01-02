import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminMasterListScreen extends StatefulWidget {
  const AdminMasterListScreen({Key? key}) : super(key: key);

  @override
  State<AdminMasterListScreen> createState() => _AdminMasterListScreenState();
}

class _AdminMasterListScreenState extends State<AdminMasterListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildStatisticsSection(),
          _buildSearchBar(),
          _buildFilterChips(),
          Expanded(
            child: _buildResidentsList(),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Upload CSV Button
          FloatingActionButton(
            heroTag: 'upload',
            onPressed: () {
              Navigator.pushNamed(context, '/admin/upload-master-list');
            },
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF2563EB),
            elevation: 4,
            child: const Icon(Icons.upload_file),
          ),
          const SizedBox(height: 12),
          // Add Resident Button
          FloatingActionButton.extended(
            heroTag: 'add',
            onPressed: () {
              Navigator.pushNamed(context, '/admin/add-to-masterlist');
            },
            backgroundColor: const Color(0xFF2563EB),
            icon: const Icon(Icons.person_add),
            label: const Text('Add Resident'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('master_residents').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 120);
        }

        final docs = snapshot.data!.docs;
        final total = docs.length;
        final occupied =
            docs.where((doc) => doc['status'] == 'occupied').length;
        final available =
            docs.where((doc) => doc['status'] == 'available').length;
        final reserved =
            docs.where((doc) => doc['status'] == 'reserved').length;

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Total', total.toString(), Icons.home),
                  _buildStatDivider(),
                  _buildStatItem(
                      'Occupied', occupied.toString(), Icons.check_circle),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                      'Available', available.toString(), Icons.home_outlined),
                  _buildStatDivider(),
                  _buildStatItem(
                      'Reserved', reserved.toString(), Icons.bookmark),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 60,
      width: 1,
      color: Colors.white24,
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                Text(
                  'Error loading residents',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var residents = snapshot.data!.docs;

        // Apply status filter
        if (_selectedFilter != 'all') {
          residents = residents.where((doc) {
            return doc['status'] == _selectedFilter;
          }).toList();
        }

        // Apply search filter
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
                Icon(
                  Icons.people_outline,
                  size: 80,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty || _selectedFilter != 'all'
                      ? 'No residents found'
                      : 'No residents yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _searchQuery.isNotEmpty || _selectedFilter != 'all'
                      ? 'Try adjusting your search or filter'
                      : 'Add residents to get started',
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
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: residents.length,
          itemBuilder: (context, index) {
            final resident = residents[index];
            return _buildResidentCard(resident);
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/admin/master-list-detail',
            arguments: resident.id,
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
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
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
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
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
}

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AdminGovernanceScreen extends StatefulWidget {
  const AdminGovernanceScreen({Key? key}) : super(key: key);

  @override
  State<AdminGovernanceScreen> createState() => _AdminGovernanceScreenState();
}

class _AdminGovernanceScreenState extends State<AdminGovernanceScreen> {
  final _announcementController = TextEditingController();

  @override
  void dispose() {
    _announcementController.dispose();
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
              'Governance & Reports',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Manage community reports and elections',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Announcements Section
            _buildAnnouncementsSection(),
            const SizedBox(height: 16),

            // User Reports Section
            _buildUserReportsSection(),
            const SizedBox(height: 16),

            // Elections Section
            _buildElectionsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementsSection() {
    final recentAnnouncements = [
      {
        'title': 'Monthly barangay assembly this Saturday',
        'time': '2 days ago',
        'category': 'meeting',
      },
      {
        'title': 'Clean-up drive scheduled for Sunday',
        'time': '5 days ago',
        'category': 'event',
      },
      {
        'title': 'HOA dues payment deadline extended',
        'time': '1 week ago',
        'category': 'payment',
      },
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.campaign,
                  color: Color(0xFF7C3AED),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Admin Announcements',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Write New Announcement
          TextField(
            controller: _announcementController,
            decoration: InputDecoration(
              hintText: 'Enter announcement message...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            maxLines: 3,
            maxLength: 200,
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _sendAnnouncement,
              icon: const Icon(Icons.notifications_active, size: 18),
              label: const Text('Send Push Notification to All Residents'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This will send a push notification to all verified residents',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue[900],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Recent Announcements
          const Text(
            'Recent Announcements',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          ...recentAnnouncements.map((announcement) {
            return _buildAnnouncementItem(
              announcement['title']!,
              announcement['time']!,
              announcement['category']!,
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildAnnouncementItem(String title, String time, String category) {
    Color categoryColor;
    IconData categoryIcon;

    switch (category) {
      case 'meeting':
        categoryColor = Colors.blue;
        categoryIcon = Icons.event;
        break;
      case 'event':
        categoryColor = Colors.green;
        categoryIcon = Icons.celebration;
        break;
      case 'payment':
        categoryColor = Colors.orange;
        categoryIcon = Icons.payment;
        break;
      default:
        categoryColor = Colors.grey;
        categoryIcon = Icons.info;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(categoryIcon, size: 16, color: categoryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Sent $time',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserReportsSection() {
    final reports = [
      {
        'reporter': 'Juan Dela Cruz',
        'type': 'False News',
        'description': 'Posted false information about barangay rules',
        'reported': 'Maria Santos',
        'date': 'Nov 30, 2024',
        'color': Colors.red,
      },
      {
        'reporter': 'Pedro Reyes',
        'type': 'Abuse',
        'description': 'Used offensive language in help request comments',
        'reported': 'Rosa Mendoza',
        'date': 'Dec 1, 2024',
        'color': Colors.orange,
      },
      {
        'reporter': 'Luis Garcia',
        'type': 'Delinquent',
        'description': 'Outstanding HOA dues for 6 months',
        'reported': 'Admin',
        'date': 'Dec 2, 2024',
        'color': Colors.yellow[700]!,
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.flag,
                      color: Colors.red,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'User Reports Triage',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButton<String>(
                  value: 'All Categories',
                  underline: const SizedBox(),
                  isDense: true,
                  items: ['All Categories', 'False News', 'Abuse', 'Delinquent']
                      .map((cat) => DropdownMenuItem(
                          value: cat,
                          child:
                              Text(cat, style: const TextStyle(fontSize: 12))))
                      .toList(),
                  onChanged: (value) {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...reports.map((report) {
            return _buildReportCard(report);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Report: ${report['reporter']}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: report['color'].withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            report['type'],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: report['color'],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report['description'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Reported by: ${report['reported']} • ${report['date']}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: View proof
                  },
                  icon: const Icon(Icons.remove_red_eye, size: 16),
                  label: const Text('View Proof'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: BorderSide(color: Colors.grey[400]!),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Mark resolved
                  },
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Resolve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Deactivate account
                  },
                  icon: const Icon(Icons.block, size: 16),
                  label: const Text('Deactivate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildElectionsSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.how_to_vote,
                      color: Color(0xFF2563EB),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Officer Election',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  // TODO: Setup new election
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: const Text('Setup New Election'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Current Election
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'HOA Board Officers 2025',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Dec 1, 2024 - Dec 15, 2024',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Total Votes: 45',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 16),

                // President Race
                _buildElectionPosition(
                  'President',
                  [
                    {'name': 'Maria Santos', 'votes': 18, 'percentage': 54.5},
                    {'name': 'Juan Dela Cruz', 'votes': 15, 'percentage': 45.5},
                  ],
                ),
                const SizedBox(height: 16),

                // Vice President Race
                _buildElectionPosition(
                  'Vice President',
                  [
                    {'name': 'Rosa Mendoza', 'votes': 22, 'percentage': 64.7},
                    {'name': 'Pedro Reyes', 'votes': 12, 'percentage': 35.3},
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElectionPosition(
      String position, List<Map<String, dynamic>> candidates) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          position,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...candidates.map((candidate) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      candidate['name'],
                      style: const TextStyle(fontSize: 13),
                    ),
                    Text(
                      '${candidate['votes']} votes (${candidate['percentage']}%)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: candidate['percentage'] / 100,
                    backgroundColor: Colors.grey[200],
                    color: const Color(0xFF2563EB),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Future<void> _sendAnnouncement() async {
    if (_announcementController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an announcement message'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Announcement'),
        content: Text(
          'Send this announcement to all verified residents?\n\n"${_announcementController.text}"',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // TODO: Send push notification
      _announcementController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Announcement sent to all residents!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}

import 'package:flutter/material.dart';
import '../../../data/models/incident_report.dart';
import '../../../data/repositories/incident_repository.dart';

class AdminIncidentReportsScreen extends StatefulWidget {
  const AdminIncidentReportsScreen({Key? key}) : super(key: key);

  @override
  State<AdminIncidentReportsScreen> createState() =>
      _AdminIncidentReportsScreenState();
}

class _AdminIncidentReportsScreenState extends State<AdminIncidentReportsScreen>
    with SingleTickerProviderStateMixin {
  final _repository = IncidentRepository();
  late TabController _tabController;
  Map<String, int> _stats = {};
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoadingStats = true);
    try {
      final stats = await _repository.getReportStats();
      setState(() {
        _stats = stats;
        _isLoadingStats = false;
      });
    } catch (e) {
      setState(() => _isLoadingStats = false);
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
          'Incident Reports',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Stats Header
          Container(
            color: const Color(0xFF2563EB),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: _isLoadingStats
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard(
                        '${_stats['total'] ?? 0}',
                        'Total',
                        Colors.white.withOpacity(0.2),
                      ),
                      _buildStatCard(
                        '${_stats['new'] ?? 0}',
                        'New',
                        Colors.red.withOpacity(0.3),
                      ),
                      _buildStatCard(
                        '${_stats['underReview'] ?? 0}',
                        'Reviewing',
                        Colors.orange.withOpacity(0.3),
                      ),
                      _buildStatCard(
                        '${_stats['resolved'] ?? 0}',
                        'Resolved',
                        Colors.green.withOpacity(0.3),
                      ),
                    ],
                  ),
          ),

          // Tab Bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF2563EB),
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: const Color(0xFF2563EB),
              indicatorWeight: 3,
              isScrollable: true,
              tabs: [
                Tab(
                  child: Row(
                    children: [
                      const Text('All '),
                      Text(
                        '(${_stats['total'] ?? 0})',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    children: [
                      const Text('New '),
                      Text(
                        '(${_stats['new'] ?? 0})',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    children: [
                      const Text('Under Review '),
                      Text(
                        '(${_stats['underReview'] ?? 0})',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    children: [
                      const Text('Resolved '),
                      Text(
                        '(${_stats['resolved'] ?? 0})',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllTab(),
                _buildStatusTab(IncidentStatus.newReport),
                _buildStatusTab(IncidentStatus.underReview),
                _buildStatusTab(IncidentStatus.resolved),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllTab() {
    return StreamBuilder<List<IncidentReport>>(
      stream: _repository.getAllReports(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final reports = snapshot.data ?? [];

        if (reports.isEmpty) {
          return _buildEmptyState('No reports yet');
        }

        return RefreshIndicator(
          onRefresh: _loadStats,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              return _buildReportCard(reports[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildStatusTab(IncidentStatus status) {
    return StreamBuilder<List<IncidentReport>>(
      stream: _repository.getReportsByStatus(status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final reports = snapshot.data ?? [];

        if (reports.isEmpty) {
          return _buildEmptyState('No ${status.name} reports');
        }

        return RefreshIndicator(
          onRefresh: _loadStats,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              return _buildReportCard(reports[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(IncidentReport report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showReportActions(report),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and Status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      report.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(int.parse(
                              report.statusColor.replaceFirst('#', '0xFF')))
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      report.statusDisplayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(int.parse(
                            report.statusColor.replaceFirst('#', '0xFF'))),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Reporter and Type
              Row(
                children: [
                  Icon(Icons.person_outline, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    report.reporterName,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.label_outline, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    report.typeDisplayName,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Location
              Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      report.location,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Time and Photo
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    report.timeAgo,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  if (report.proofUrl != null)
                    Row(
                      children: [
                        Icon(Icons.photo, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Has photo',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportActions(IncidentReport report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: controller,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title and Status
              Text(
                report.title,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Report Details
              _buildDetailRow(Icons.person, 'Reported by', report.reporterName),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.label, 'Type', report.typeDisplayName),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.location_on, 'Location', report.location),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.access_time, 'Reported', report.timeAgo),
              const SizedBox(height: 20),

              // Description
              const Text(
                'Description',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                report.description,
                style: TextStyle(
                    fontSize: 15, color: Colors.grey[700], height: 1.5),
              ),

              // Admin Notes
              if (report.adminNotes != null &&
                  report.adminNotes!.isNotEmpty) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Admin Notes',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(report.adminNotes!),
                    ],
                  ),
                ),
              ],

              // Photo
              if (report.proofUrl != null) ...[
                const SizedBox(height: 20),
                const Text(
                  'Photo Proof',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(report.proofUrl!),
                ),
              ],

              // Action Buttons
              const SizedBox(height: 24),
              if (!report.isResolved && !report.isDismissed) ...[
                Row(
                  children: [
                    if (report.isNew)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _updateStatus(report, IncidentStatus.underReview);
                          },
                          icon: const Icon(Icons.rate_review),
                          label: const Text('Start Review'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    if (report.isNew) const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _resolveReport(report);
                        },
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Mark Resolved'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _updateStatus(report, IncidentStatus.dismissed);
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('Dismiss'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ).then((_) => _loadStats()); // Refresh stats when bottom sheet closes
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text('$label: ', style: TextStyle(color: Colors.grey[600])),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Future<void> _updateStatus(
      IncidentReport report, IncidentStatus newStatus) async {
    try {
      await _repository.updateReportStatus(
        reportId: report.id,
        newStatus: newStatus,
      );
      _loadStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to ${newStatus.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _resolveReport(IncidentReport report) async {
    final notesController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Resolved'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add resolution notes (optional):'),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                hintText: 'Resolution notes...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Resolve'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _repository.updateReportStatus(
          reportId: report.id,
          newStatus: IncidentStatus.resolved,
          adminNotes: notesController.text.trim().isEmpty
              ? null
              : notesController.text.trim(),
        );
        _loadStats();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Report marked as resolved'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to resolve: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    notesController.dispose();
  }
}

import 'package:flutter/material.dart';
import '../../../data/models/help_request.dart';
import '../../../data/models/offer.dart';
import '../../../data/repositories/request_repository.dart';
import 'request_detail_screen.dart';
import 'create_request_screen.dart';

/// My Requests Screen - Shows all requests posted by the current user
///
/// Features:
/// - Stats cards (Total, Active, Completed count)
/// - Tab view (Active vs Completed requests)
/// - Request cards with status badges
/// - Navigate to details on tap
///
/// Data Flow:
/// Repository.getUserRequestsByStatus() → Stream
///   ↓
/// StreamBuilder rebuilds when data changes
///   ↓
/// UI displays updated list
class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen>
    with SingleTickerProviderStateMixin {
  final RequestRepository _repository = RequestRepository();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Initialize tab controller with 2 tabs (Active, Completed)
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
      // App bar with back button
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB), // Blue
        foregroundColor: Colors.white,
        title: const Text('My Requests'),
        elevation: 0,
      ),

      // StreamBuilder listens to real-time data changes
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _repository.getUserRequestsByStatus(),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Error state
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          // Extract data from snapshot
          final data = snapshot.data ?? {};
          final stats = data['stats'] as Map<String, dynamic>? ?? {};
          final activeRequests = data['active'] as List<HelpRequest>? ?? [];
          final completedRequests =
              data['completed'] as List<HelpRequest>? ?? [];

          return Column(
            children: [
              // Stats Section (Blue header with counts)
              _buildStatsSection(stats),

              // Tab Bar (Active / Completed)
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF2563EB),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color(0xFF2563EB),
                  tabs: [
                    Tab(
                      text: 'Active (${stats['active'] ?? 0})',
                    ),
                    Tab(
                      text: 'Completed (${stats['completed'] ?? 0})',
                    ),
                  ],
                ),
              ),

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Active Tab
                    _buildRequestList(activeRequests, isActive: true),

                    // Completed Tab
                    _buildRequestList(completedRequests, isActive: false),
                  ],
                ),
              ),
            ],
          );
        },
      ),

      // Floating Action Button - Create new request
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateRequestScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFF2563EB),
        icon: const Icon(Icons.add),
        label: const Text('New Request'),
      ),
    );
  }

  /// Builds the blue stats header showing Total, Active, Completed counts
  Widget _buildStatsSection(Map<String, dynamic> stats) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF2563EB),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard(
            label: 'Total',
            count: stats['total'] ?? 0,
          ),
          _buildStatCard(
            label: 'Active',
            count: stats['active'] ?? 0,
          ),
          _buildStatCard(
            label: 'Completed',
            count: stats['completed'] ?? 0,
          ),
        ],
      ),
    );
  }

  /// Individual stat card (number + label)
  Widget _buildStatCard({
    required String label,
    required int count,
  }) {
    return Column(
      children: [
        Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  /// Builds the scrollable list of request cards
  Widget _buildRequestList(List<HelpRequest> requests,
      {required bool isActive}) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? Icons.inbox_outlined : Icons.check_circle_outline,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              isActive ? 'No active requests' : 'No completed requests',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isActive
                  ? 'Create a new request to get started'
                  : 'Complete requests will appear here',
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
        return _buildRequestCard(request);
      },
    );
  }

  /// Individual request card
  ///
  /// Shows:
  /// - Title and category
  /// - Status badge
  /// - Offer count or accepted helper
  /// - Time posted
  Widget _buildRequestCard(HelpRequest request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to request details
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RequestDetailScreen(request: request),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row (Title + Status badge)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      request.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Color(int.parse(
                              request.statusColor.replaceFirst('#', '0xFF')))
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      request.statusText,
                      style: TextStyle(
                        color: Color(int.parse(
                            request.statusColor.replaceFirst('#', '0xFF'))),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Category
              Text(
                request.categoryText,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 12),

              // Footer row (Offers/Helper + Time)
              Row(
                children: [
                  // Show offer count or accepted helper
                  if (request.isOpen)
                    StreamBuilder<List<Offer>>(
                      stream: _repository.getRequestOffers(request.id),
                      builder: (context, offerSnapshot) {
                        final offers = offerSnapshot.data ?? [];
                        final pendingOffers =
                            offers.where((o) => o.isPending).length;

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$pendingOffers pending offer${pendingOffers != 1 ? 's' : ''}',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    )
                  else if (request.acceptedHelperName != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Accepted: ${request.acceptedHelperName}',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 12,
                        ),
                      ),
                    ),

                  const Spacer(),

                  // Time posted
                  Text(
                    request.timeAgo,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

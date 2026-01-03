import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/help_request.dart';
import '../../../../data/repositories/request_repository.dart';
import '../help_request/user_help_request_detail_screen.dart';

class MyHelpRequestsScreen extends StatefulWidget {
  const MyHelpRequestsScreen({Key? key}) : super(key: key);

  @override
  State<MyHelpRequestsScreen> createState() => _MyHelpRequestsScreenState();
}

class _MyHelpRequestsScreenState extends State<MyHelpRequestsScreen> {
  String _selectedFilter = 'active'; // 'active', 'completed', 'all'

  @override
  Widget build(BuildContext context) {
    final repository = RequestRepository();

    return Column(
      children: [
        // Filter Chips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Active', 'active', Icons.pending_actions),
                const SizedBox(width: 8),
                _buildFilterChip('Completed', 'completed', Icons.check_circle),
                const SizedBox(width: 8),
                _buildFilterChip('All', 'all', Icons.list),
              ],
            ),
          ),
        ),

        // List
        Expanded(
          child: StreamBuilder<Map<String, dynamic>>(
            stream: repository.getUserRequestsByStatus(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: ${snapshot.error}'),
                    ],
                  ),
                );
              }

              final data = snapshot.data;
              if (data == null) {
                return _buildEmptyState();
              }

              final activeRequests = data['active'] as List<HelpRequest>;
              final completedRequests = data['completed'] as List<HelpRequest>;

              // Filter based on selection
              List<HelpRequest> displayRequests;
              switch (_selectedFilter) {
                case 'active':
                  displayRequests = activeRequests;
                  break;
                case 'completed':
                  displayRequests = completedRequests;
                  break;
                case 'all':
                  displayRequests = [...activeRequests, ...completedRequests];
                  break;
                default:
                  displayRequests = activeRequests;
              }

              if (displayRequests.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: displayRequests.length,
                itemBuilder: (context, index) {
                  return _buildHelpRequestCard(context, displayRequests[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _selectedFilter == value;

    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : AppColors.primaryBlue,
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      selectedColor: AppColors.primaryBlue,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.primaryBlue,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
      side: BorderSide(
        color: isSelected ? AppColors.primaryBlue : Colors.transparent,
        width: 1,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    );
  }

  Widget _buildEmptyState() {
    String message;
    switch (_selectedFilter) {
      case 'active':
        message = 'No active requests';
        break;
      case 'completed':
        message = 'No completed requests yet';
        break;
      default:
        message = 'No help requests yet';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.volunteer_activism, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a help request to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpRequestCard(BuildContext context, HelpRequest request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HelpRequestDetailScreen(request: request),
            ),
          );
        },
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
                      request.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(request.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      request.statusText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(request.status),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Category
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  request.categoryLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Stats
              Row(
                children: [
                  Icon(Icons.people, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${request.helpersNeeded} helper${request.helpersNeeded > 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.volunteer_activism,
                      size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${request.offerCount} offer${request.offerCount != 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Location
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      request.location,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Time
              Text(
                request.timeAgo,
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.open:
        return Colors.green;
      case RequestStatus.inProgress:
        return Colors.orange;
      case RequestStatus.completed:
        return Colors.blue;
      case RequestStatus.cancelled:
        return Colors.grey;
    }
  }
}

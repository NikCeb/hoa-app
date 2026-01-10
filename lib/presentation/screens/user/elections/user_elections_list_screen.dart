import 'package:flutter/material.dart';
import '../../../../data/repositories/elections_repository.dart';
import '../../../../data/models/election_position.dart';
import 'user_position_detail_screen.dart';

class UserElectionsListScreen extends StatefulWidget {
  const UserElectionsListScreen({super.key});

  @override
  State<UserElectionsListScreen> createState() =>
      _UserElectionsListScreenState();
}

class _UserElectionsListScreenState extends State<UserElectionsListScreen> {
  final _repository = ElectionsRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B5CF6),
        elevation: 0,
        title: const Text(
          'Elections',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<List<ElectionPosition>>(
        stream: _repository
            .getAllUserPositions(), // Changed from getActivePositions()
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF8B5CF6),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading elections',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          final positions = snapshot.data ?? [];

          if (positions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.how_to_vote, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No elections yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check back later for upcoming elections',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          // Group positions into active and ended
          final activePositions = positions.where((p) => !p.isEnded).toList();
          final endedPositions = positions.where((p) => p.isEnded).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Active Elections Section
              if (activePositions.isNotEmpty) ...[
                _buildSectionHeader(
                  icon: Icons.how_to_vote,
                  title: 'Active Elections',
                  subtitle: 'Vote now or apply for a position',
                  color: Colors.green,
                ),
                const SizedBox(height: 12),
                ...activePositions
                    .map((position) => _buildPositionCard(position)),
                const SizedBox(height: 24),
              ],

              // Ended Elections Section
              if (endedPositions.isNotEmpty) ...[
                _buildSectionHeader(
                  icon: Icons.bar_chart,
                  title: 'Past Elections',
                  subtitle: 'View final results',
                  color: Colors.grey,
                ),
                const SizedBox(height: 12),
                ...endedPositions
                    .map((position) => _buildPositionCard(position)),
              ],

              // Empty state for no active elections
              if (activePositions.isEmpty && endedPositions.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No active elections right now. Check back later!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPositionCard(ElectionPosition position) {
    return FutureBuilder<int>(
      future: _repository.getCandidateCount(position.id),
      builder: (context, snapshot) {
        final candidateCount = snapshot.data ?? 0;
        final isEnded = position.isEnded;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: isEnded ? 1 : 2,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserPositionDetailScreen(
                    position: position,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: isEnded
                    ? Border.all(color: Colors.grey.withOpacity(0.3), width: 1)
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Row with Status Badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            position.positionName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isEnded ? Colors.grey[700] : Colors.black,
                            ),
                          ),
                        ),
                        _buildStatusBadge(position),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Description
                    Text(
                      position.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),

                    // Deadline
                    Row(
                      children: [
                        Icon(Icons.event, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Text(
                          isEnded
                              ? 'Ended: ${position.deadlineFormatted}'
                              : 'Deadline: ${position.deadlineFormatted}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Time Status (Active) or Result Status (Ended)
                    if (!isEnded)
                      Row(
                        children: [
                          Icon(Icons.timer,
                              size: 16, color: Colors.orange[700]),
                          const SizedBox(width: 6),
                          Text(
                            position.timeRemainingText,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.orange[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Icon(Icons.check_circle,
                              size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Text(
                            'Results available - Tap to view',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),

                    // Candidate Count Chip
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isEnded
                                ? Colors.grey.withOpacity(0.1)
                                : Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.people,
                                size: 14,
                                color: isEnded ? Colors.grey[700] : Colors.blue,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$candidateCount candidate${candidateCount != 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      isEnded ? Colors.grey[700] : Colors.blue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isEnded) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.emoji_events,
                                  size: 12,
                                  color: Color(0xFF8B5CF6),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'View Winner',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF8B5CF6),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(ElectionPosition position) {
    Color color;
    String text;
    IconData icon;

    if (position.isEnded) {
      color = Colors.grey;
      text = 'Ended';
      icon = Icons.check_circle;
    } else {
      color = Colors.green;
      text = 'Active';
      icon = Icons.circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

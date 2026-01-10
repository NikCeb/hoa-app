import 'package:flutter/material.dart';
import '../../../../data/repositories/elections_repository.dart';
import '../../../../data/models/election_position.dart';
import 'admin_position_detail_screen.dart';
import 'admin_create_position_screen.dart';

class AdminElectionsListScreen extends StatefulWidget {
  const AdminElectionsListScreen({super.key});

  @override
  State<AdminElectionsListScreen> createState() =>
      _AdminElectionsListScreenState();
}

class _AdminElectionsListScreenState extends State<AdminElectionsListScreen> {
  final _repository = ElectionsRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B5CF6),
        elevation: 0,
        title: const Text(
          'Position Elections',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<List<ElectionPosition>>(
        stream: _repository.getAllPositions(),
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
                    'Error loading positions',
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
                    'No positions yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first position election',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: positions.length,
            itemBuilder: (context, index) {
              return _buildPositionCard(positions[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AdminCreatePositionScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFF8B5CF6),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Create Position',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildPositionCard(ElectionPosition position) {
    return FutureBuilder<Map<String, int>>(
      future: _getPositionStats(position.id),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {'candidates': 0, 'votes': 0};

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminPositionDetailScreen(
                    position: position,
                  ),
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
                          position.positionName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
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
                        'Deadline: ${position.deadlineFormatted}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Time Remaining
                  if (!position.isEnded)
                    Row(
                      children: [
                        Icon(Icons.timer, size: 16, color: Colors.grey[600]),
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
                    ),
                  const SizedBox(height: 12),

                  // Stats
                  Row(
                    children: [
                      _buildStatChip(
                        Icons.people,
                        '${stats['candidates']} Candidates',
                        Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      _buildStatChip(
                        Icons.how_to_vote,
                        '${stats['votes']} Votes',
                        Colors.green,
                      ),
                    ],
                  ),
                ],
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

    if (!position.isActive) {
      color = Colors.grey;
      text = 'Closed';
    } else if (position.isEnded) {
      color = Colors.red;
      text = 'Ended';
    } else {
      color = Colors.green;
      text = 'Active';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, int>> _getPositionStats(String positionId) async {
    final candidates = await _repository.getCandidateCount(positionId);
    final votes = await _repository.getTotalVotes(positionId);
    return {'candidates': candidates, 'votes': votes};
  }
}

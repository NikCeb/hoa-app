import 'package:flutter/material.dart';
import '../../../../data/models/election.dart';
import '../../../../data/models/election_position.dart';
import '../../../../data/models/election_candidate.dart';
import '../../../../data/repositories/elections_repository.dart';
import 'admin_create_election_screen.dart';
import 'admin_positions_screen.dart';
import 'admin_candidates_screen.dart';

class AdminElectionsScreen extends StatefulWidget {
  const AdminElectionsScreen({Key? key}) : super(key: key);

  @override
  State<AdminElectionsScreen> createState() => _AdminElectionsScreenState();
}

class _AdminElectionsScreenState extends State<AdminElectionsScreen> {
  String _activeView = 'elections'; // 'elections', 'positions', 'candidates'
  final _repository = ElectionsRepository();

  int _electionsCount = 0;
  int _activeCount = 0;
  int _positionsCount = 0;
  int _pendingCandidates = 0;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final stats = await _repository.getElectionStats();

    _repository.getAllPositions().listen((positions) {
      if (mounted) {
        setState(() => _positionsCount = positions.length);
      }
    });

    _repository.getPendingCandidates().listen((candidates) {
      if (mounted) {
        setState(() => _pendingCandidates = candidates.length);
      }
    });

    if (mounted) {
      setState(() {
        _electionsCount = stats['total'] ?? 0;
        _activeCount = stats['active'] ?? 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B5CF6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Elections Management',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Compact Navigation Cards
          // Compact Navigation Cards (1x4 horizontal)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF8B5CF6),
                  const Color(0xFF8B5CF6).withOpacity(0.95),
                ],
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavigationCard(
                  title: 'Elections',
                  count: _electionsCount,
                  icon: Icons.how_to_vote,
                  color: const Color(0xFF8B5CF6),
                  viewKey: 'elections',
                ),
                _buildNavigationCard(
                  title: 'Active',
                  count: _activeCount,
                  icon: Icons.ballot,
                  color: Colors.green,
                  viewKey: 'active',
                ),
                _buildNavigationCard(
                  title: 'Positions',
                  count: _positionsCount,
                  icon: Icons.workspace_premium,
                  color: Colors.blue,
                  viewKey: 'positions',
                ),
                _buildNavigationCard(
                  title: 'Candidates',
                  count: _pendingCandidates,
                  icon: Icons.person_outline,
                  color: Colors.orange,
                  viewKey: 'candidates',
                  badge: _pendingCandidates > 0,
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildNavigationCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required String viewKey,
    bool badge = false,
  }) {
    final isActive = _activeView == viewKey;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Card(
          elevation: isActive ? 6 : 2,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: isActive
                ? const BorderSide(color: Colors.white, width: 2)
                : BorderSide.none,
          ),
          child: InkWell(
            onTap: () {
              setState(() => _activeView = viewKey);
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 80, // ADD FIXED HEIGHT
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: isActive
                    ? LinearGradient(
                        colors: [color, color.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isActive ? null : color.withOpacity(0.15),
              ),
              child: Stack(
                children: [
                  // CENTER THE ENTIRE COLUMN
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment:
                            CrossAxisAlignment.center, // ADD THIS
                        children: [
                          Icon(
                            icon,
                            size: 22,
                            color: isActive ? Colors.white : color,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            count.toString(),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isActive ? Colors.white : color,
                              height:
                                  1.0, // ADD THIS - removes extra line height
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isActive ? Colors.white : color,
                              height: 1.2, // ADD THIS
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Badge
                  if (badge && count > 0)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Center(
                          child: Text(
                            count.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              height: 1.0,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_activeView) {
      case 'elections':
      case 'active':
        return _buildElectionsList();
      case 'positions':
        return const AdminPositionsScreen();
      case 'candidates':
        return const AdminCandidatesScreen();
      default:
        return _buildElectionsList();
    }
  }

  FloatingActionButton? _buildFAB() {
    if (_activeView == 'elections' || _activeView == 'active') {
      return FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AdminCreateElectionScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFF8B5CF6),
        icon: const Icon(Icons.add),
        label: const Text('New Election'),
      );
    }
    return null;
  }

  Widget _buildElectionsList() {
    Stream<List<Election>> stream;

    if (_activeView == 'active') {
      stream = _repository.getActiveElections();
    } else {
      stream = _repository.getAllElections();
    }

    return StreamBuilder<List<Election>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }

        final elections = snapshot.data ?? [];

        if (elections.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.how_to_vote, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No Elections Yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first election',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: elections.length,
          itemBuilder: (context, index) {
            return _buildElectionCard(elections[index]);
          },
        );
      },
    );
  }

  Widget _buildElectionCard(Election election) {
    Color statusColor;
    switch (election.status) {
      case ElectionStatus.active:
        statusColor = Colors.green;
        break;
      case ElectionStatus.upcoming:
        statusColor = Colors.blue;
        break;
      case ElectionStatus.closed:
        statusColor = Colors.grey;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showElectionDetails(election),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      election.electionName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      election.statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    '${_formatDate(election.timeStart)} - ${_formatDate(election.timeEnd)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    '${election.totalVerifiedVoters} Eligible Voters',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              if (election.isOpen) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time,
                        size: 16, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    Text(
                      election.timeRemainingText,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  void _showElectionDetails(Election election) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: controller,
            children: [
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
              Text(
                election.electionName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoRow(Icons.calendar_today, 'Start Date',
                  _formatDate(election.timeStart)),
              const SizedBox(height: 12),
              _buildInfoRow(
                  Icons.event, 'End Date', _formatDate(election.timeEnd)),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.people, 'Eligible Voters',
                  '${election.totalVerifiedVoters}'),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.info, 'Status', election.statusText),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: election.status == ElectionStatus.closed
                          ? null
                          : () {
                              Navigator.pop(context);
                              // TODO: Navigate to edit screen
                            },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Election'),
                            content: Text(
                              'Are you sure you want to delete "${election.electionName}"?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          await _repository.deleteElection(election.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Election deleted'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            _loadCounts();
                          }
                        }
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[600],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

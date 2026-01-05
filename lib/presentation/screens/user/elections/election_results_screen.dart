import 'package:flutter/material.dart';
import '../../../../data/models/election.dart';
import '../../../../data/models/election_position.dart';
import '../../../../data/models/election_candidate.dart';
import '../../../../data/repositories/elections_repository.dart';

class ElectionResultsScreen extends StatefulWidget {
  final Election election;

  const ElectionResultsScreen({
    Key? key,
    required this.election,
  }) : super(key: key);

  @override
  State<ElectionResultsScreen> createState() => _ElectionResultsScreenState();
}

class _ElectionResultsScreenState extends State<ElectionResultsScreen> {
  final _repository = ElectionsRepository();
  bool _isLoading = true;
  Map<String, dynamic>? _results;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check if election should be finalized
      final isFinalized =
          await _repository.checkAndFinalizeIfEnded(widget.election.id);

      if (isFinalized) {
        final results =
            await _repository.getElectionResults(widget.election.id);
        setState(() {
          _results = results;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Results will be available after voting ends';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load results: $e';
        _isLoading = false;
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
          'Election Results',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildNotAvailable()
              : _buildResults(),
    );
  }

  Widget _buildNotAvailable() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              'Results Not Yet Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Please check back later',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadResults,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_results == null || _results!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Results Available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Election Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF8B5CF6),
                const Color(0xFF8B5CF6).withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Icon(Icons.emoji_events, size: 48, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                widget.election.electionName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'OFFICIAL RESULTS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Results by Position
        ..._results!.entries.map((entry) {
          final positionId = entry.key;
          final positionData = entry.value as Map<String, dynamic>;
          final positionName = positionData['positionName'] ?? 'Position';
          final candidates = positionData['candidates'] as List<dynamic>? ?? [];
          final totalVotes = positionData['totalVotes'] ?? 0;

          return _buildPositionResults(
            positionName: positionName,
            candidates: candidates,
            totalVotes: totalVotes,
          );
        }).toList(),
      ],
    );
  }

  Widget _buildPositionResults({
    required String positionName,
    required List<dynamic> candidates,
    required int totalVotes,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Position Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.workspace_premium,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        positionName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$totalVotes total votes',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Candidates Results
          if (candidates.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No candidates',
                style: TextStyle(color: Colors.grey[600]),
              ),
            )
          else
            ...candidates.asMap().entries.map((entry) {
              final index = entry.key;
              final candidate = entry.value as Map<String, dynamic>;
              final isWinner = index == 0 && totalVotes > 0;

              return _buildCandidateResult(
                candidate: candidate,
                totalVotes: totalVotes,
                rank: index + 1,
                isWinner: isWinner,
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildCandidateResult({
    required Map<String, dynamic> candidate,
    required int totalVotes,
    required int rank,
    required bool isWinner,
  }) {
    final name = candidate['candidateName'] ?? 'Unknown';
    final votes = candidate['voteCount'] as int? ?? 0;
    final lotNumber = candidate['lotNumber'];
    final percentage = totalVotes > 0 ? (votes / totalVotes * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
        color: isWinner ? Colors.green.withOpacity(0.05) : null,
      ),
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isWinner
                  ? Colors.amber
                  : rank == 2
                      ? Colors.grey[400]
                      : rank == 3
                          ? Colors.brown[300]
                          : Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isWinner
                  ? const Icon(Icons.emoji_events,
                      size: 18, color: Colors.white)
                  : Text(
                      '$rank',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: rank <= 3 ? Colors.white : Colors.grey[600],
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // Candidate Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              isWinner ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (isWinner)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'WINNER',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                if (lotNumber != null)
                  Text(
                    'Lot $lotNumber',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                const SizedBox(height: 8),

                // Progress Bar
                Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: percentage / 100,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color:
                              isWinner ? Colors.green : const Color(0xFF8B5CF6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Vote Count
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$votes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isWinner ? Colors.green : const Color(0xFF8B5CF6),
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../data/repositories/elections_repository.dart';
import '../../../../data/models/election_position.dart';
import '../../../../data/models/election_candidate.dart';

class UserPositionDetailScreen extends StatefulWidget {
  final ElectionPosition position;

  const UserPositionDetailScreen({
    super.key,
    required this.position,
  });

  @override
  State<UserPositionDetailScreen> createState() =>
      _UserPositionDetailScreenState();
}

class _UserPositionDetailScreenState extends State<UserPositionDetailScreen> {
  final _repository = ElectionsRepository();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool _hasApplied = false;
  bool _hasVoted = false;
  String? _votedCandidateId;

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    final userId = _auth.currentUser!.uid;

    final hasApplied = await _repository.hasUserApplied(
      positionId: widget.position.id,
      userId: userId,
    );

    final hasVoted = await _repository.hasUserVoted(
      positionId: widget.position.id,
      userId: userId,
    );

    String? votedCandidateId;
    if (hasVoted) {
      votedCandidateId = await _repository.getUserVotedCandidateId(
        positionId: widget.position.id,
        userId: userId,
      );
    }

    if (mounted) {
      setState(() {
        _hasApplied = hasApplied;
        _hasVoted = hasVoted;
        _votedCandidateId = votedCandidateId;
      });
    }
  }

  Future<void> _applyForPosition() async {
    setState(() => _isLoading = true);

    try {
      final userId = _auth.currentUser!.uid;
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data()!;

      final candidateName = '${userData['firstName']} ${userData['lastName']}';
      final lotNumber = userData['lotNumber'];

      await _repository.applyForPosition(
        positionId: widget.position.id,
        userId: userId,
        candidateName: candidateName,
        lotNumber: lotNumber,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application submitted! You have 1 vote.'),
            backgroundColor: Colors.green,
          ),
        );
        _checkUserStatus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _voteForCandidate(ElectionCandidate candidate) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Vote'),
        content: Text(
          'Vote for ${candidate.candidateName}?\n\nYou can only vote once per position.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Vote'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final userId = _auth.currentUser!.uid;

      await _repository.voteForCandidate(
        positionId: widget.position.id,
        candidateId: candidate.id,
        userId: userId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voted for ${candidate.candidateName}!'),
            backgroundColor: Colors.green,
          ),
        );
        _checkUserStatus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<int> _getTotalVotes() async {
    return await _repository.getTotalVotes(widget.position.id);
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
          'Position Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Position Info Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.position.positionName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildStatusBadge(),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.position.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  Icons.event,
                  'Deadline',
                  widget.position.deadlineFormatted,
                ),
                if (!widget.position.isEnded)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _buildInfoRow(
                      Icons.timer,
                      'Time Remaining',
                      widget.position.timeRemainingText,
                      valueColor: Colors.orange[700],
                    ),
                  ),
                if (widget.position.isEnded)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 20, color: Colors.grey[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Voting has ended - Results are final',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Results View (when ended) or Active View
          Expanded(
            child: widget.position.isEnded
                ? _buildResultsView()
                : _buildActiveView(),
          ),

          // Action Buttons (only when active)
          if (widget.position.canApplyOrVote) _buildActionButtons(),
        ],
      ),
    );
  }

  // ==================== RESULTS VIEW (Read-Only) ====================

  Widget _buildResultsView() {
    return FutureBuilder<int>(
      future: _getTotalVotes(),
      builder: (context, totalVotesSnapshot) {
        final totalVotes = totalVotesSnapshot.data ?? 0;

        return StreamBuilder<List<ElectionCandidate>>(
          stream: _repository.getCandidatesForPosition(widget.position.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF8B5CF6),
                ),
              );
            }

            final candidates = snapshot.data ?? [];

            if (candidates.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline,
                        size: 80, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'No candidates participated',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            final winner = candidates.first;
            final otherCandidates =
                candidates.length > 1 ? candidates.sublist(1) : [];

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Status Header
                Row(
                  children: [
                    const Icon(Icons.bar_chart,
                        color: Color(0xFF8B5CF6), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Final Results',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Total: $totalVotes vote${totalVotes != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Winner Card
                _buildWinnerCard(winner, totalVotes),
                const SizedBox(height: 24),

                // Other Candidates Section
                if (otherCandidates.isNotEmpty) ...[
                  Text(
                    'Other Candidates',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...otherCandidates.asMap().entries.map((entry) {
                    return _buildResultCandidateCard(
                      entry.value,
                      entry.key + 2, // Rank starts at 2 (winner is #1)
                      totalVotes,
                    );
                  }).toList(),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildWinnerCard(ElectionCandidate winner, int totalVotes) {
    final percentage = totalVotes > 0
        ? ((winner.voteCount / totalVotes) * 100).toStringAsFixed(1)
        : '0.0';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Trophy Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),

          // "WINNER" Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '🏆 WINNER',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Divider
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),

          // Winner Info
          Text(
            winner.candidateName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          if (winner.lotNumber != null) ...[
            const SizedBox(height: 6),
            Text(
              'Lot: ${winner.lotNumber}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Vote Stats
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.how_to_vote, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${winner.voteCount} votes ($percentage%)',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Divider
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 12),

          // Congratulations
          const Text(
            '🎊 Congratulations! 🎊',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCandidateCard(
      ElectionCandidate candidate, int rank, int totalVotes) {
    final percentage = totalVotes > 0
        ? ((candidate.voteCount / totalVotes) * 100).toStringAsFixed(1)
        : '0.0';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Rank
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '#$rank',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Candidate Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    candidate.candidateName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (candidate.lotNumber != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Lot: ${candidate.lotNumber}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Vote Count
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${candidate.voteCount}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B5CF6),
                  ),
                ),
                Text(
                  '$percentage%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==================== ACTIVE VIEW (Can Vote/Apply) ====================

  Widget _buildActiveView() {
    return StreamBuilder<List<ElectionCandidate>>(
      stream: _repository.getCandidatesForPosition(widget.position.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF8B5CF6),
            ),
          );
        }

        final candidates = snapshot.data ?? [];

        if (candidates.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No candidates yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Be the first to apply!',
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
          itemCount: candidates.length,
          itemBuilder: (context, index) {
            return _buildActiveCandidateCard(candidates[index], index + 1);
          },
        );
      },
    );
  }

  Widget _buildActiveCandidateCard(ElectionCandidate candidate, int rank) {
    final isCurrentUser = candidate.userId == _auth.currentUser!.uid;
    final hasVotedForThis = _votedCandidateId == candidate.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: hasVotedForThis ? 3 : 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Rank
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: rank == 1
                        ? Colors.amber.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '#$rank',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: rank == 1 ? Colors.amber[800] : Colors.grey[700],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Candidate Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              candidate.candidateName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (isCurrentUser)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'You',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (candidate.lotNumber != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Lot: ${candidate.lotNumber}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Vote Count
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.how_to_vote,
                        size: 18,
                        color: Color(0xFF8B5CF6),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${candidate.voteCount}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B5CF6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Vote Button
            if (!isCurrentUser && !_hasVoted) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed:
                      _isLoading ? null : () => _voteForCandidate(candidate),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Vote'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF8B5CF6),
                    side: const BorderSide(color: Color(0xFF8B5CF6)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],

            // Voted Indicator
            if (hasVotedForThis) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'You voted for this candidate',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==================== HELPER WIDGETS ====================

  Widget _buildStatusBadge() {
    Color color;
    String text;

    if (!widget.position.isActive) {
      color = Colors.grey;
      text = 'Closed';
    } else if (widget.position.isEnded) {
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

  Widget _buildInfoRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: _hasApplied
            ? Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "You're running for this position!",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _applyForPosition,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.person_add),
                  label: Text(
                    _isLoading ? 'Applying...' : 'Apply for This Position',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
      ),
    );
  }
}

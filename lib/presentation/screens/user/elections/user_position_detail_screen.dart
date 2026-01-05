import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../data/models/election.dart';
import '../../../../data/models/election_position.dart';
import '../../../../data/models/election_candidate.dart';
import '../../../../data/repositories/elections_repository.dart';
import 'user_nominate_for_position_screen.dart';
import 'user_vote_for_position_screen.dart';
import 'election_results_screen.dart';

class UserPositionDetailScreen extends StatefulWidget {
  final Election election;
  final ElectionPosition position;

  const UserPositionDetailScreen({
    Key? key,
    required this.election,
    required this.position,
  }) : super(key: key);

  @override
  State<UserPositionDetailScreen> createState() =>
      _UserPositionDetailScreenState();
}

class _UserPositionDetailScreenState extends State<UserPositionDetailScreen> {
  final repository = ElectionsRepository();
  final _auth = FirebaseAuth.instance;
  bool _hasVoted = false;
  bool _isCheckingVote = true;

  @override
  void initState() {
    super.initState();
    // Debug: Print position status info
    widget.position.printDebugInfo();
    _checkVoteStatus();
  }

  Future<void> _checkVoteStatus() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        final hasVoted = await repository.hasUserVotedForPosition(
          electionId: widget.election.id,
          positionId: widget.position.id,
          oderId: userId,
        );
        if (mounted) {
          setState(() {
            _hasVoted = hasVoted;
            _isCheckingVote = false;
          });
        }
      }
    } catch (e) {
      print('Error checking vote status: $e');
      if (mounted) {
        setState(() => _isCheckingVote = false);
      }
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
        title: Text(
          widget.position.positionName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Header Info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF8B5CF6),
                  const Color(0xFF8B5CF6).withOpacity(0.8),
                ],
              ),
            ),
            child: Column(
              children: [
                Text(
                  widget.election.electionName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.position.statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.access_time,
                        size: 16, color: Colors.white70),
                    const SizedBox(width: 8),
                    Text(
                      widget.position.timeRemainingText,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                // Show voted badge
                if (_hasVoted && !_isCheckingVote) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.check_circle, size: 16, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'You have voted',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Candidates List
          Expanded(
            child: StreamBuilder<List<ElectionCandidate>>(
              stream: repository
                  .getApprovedCandidatesForPosition(widget.position.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final candidates = snapshot.data ?? [];

                if (candidates.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No Candidates Yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.position.isNominationOpen
                              ? 'Be the first to nominate!'
                              : 'No one has been nominated for this position',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: candidates.length,
                  itemBuilder: (context, index) {
                    return _buildCandidateCard(candidates[index]);
                  },
                );
              },
            ),
          ),

          // Action Buttons
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Show status info if neither nomination nor voting is open
            if (!widget.position.isNominationOpen &&
                !widget.position.isVotingOpen &&
                !widget.position.hasVotingEnded)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.position.isUpcoming
                            ? 'Nominations will open soon'
                            : 'Waiting for voting period to start',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Row(
              children: [
                // Nominate Button
                if (widget.position.isNominationOpen)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserNominateForPositionScreen(
                              election: widget.election,
                              position: widget.position,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.person_add),
                      label: const Text('Nominate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),

                if (widget.position.isNominationOpen &&
                    widget.position.isVotingOpen)
                  const SizedBox(width: 12),

                // Vote Button
                if (widget.position.isVotingOpen && !_hasVoted)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isCheckingVote
                          ? null
                          : () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      UserVoteForPositionScreen(
                                    election: widget.election,
                                    position: widget.position,
                                  ),
                                ),
                              );
                              // Refresh vote status after voting
                              _checkVoteStatus();
                            },
                      icon: _isCheckingVote
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.how_to_vote),
                      label: const Text('Vote'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),

                // Already Voted - View Results
                if (widget.position.isVotingOpen && _hasVoted)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.check_circle,
                              color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Vote Submitted',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Voting Ended - View Results
                if (widget.position.hasVotingEnded)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ElectionResultsScreen(
                              election: widget.election,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.emoji_events),
                      label: const Text('View Results'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),

                // Upcoming State
                if (widget.position.isUpcoming)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: const Text(
                        'Coming Soon',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCandidateCard(ElectionCandidate candidate) {
    final showVoteCount = widget.position.hasVotingEnded;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xFF8B5CF6),
              backgroundImage: candidate.photoUrl != null
                  ? NetworkImage(candidate.photoUrl!)
                  : null,
              child: candidate.photoUrl == null
                  ? Text(
                      candidate.candidateName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
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
                  if (candidate.lotNumber != null)
                    Text(
                      'Lot ${candidate.lotNumber}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            if (showVoteCount)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${candidate.voteCount} votes',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B5CF6),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

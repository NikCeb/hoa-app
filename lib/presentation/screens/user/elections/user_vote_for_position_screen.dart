import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../data/models/election.dart';
import '../../../../data/models/election_position.dart';
import '../../../../data/models/election_candidate.dart';
import '../../../../data/repositories/elections_repository.dart';

class UserVoteForPositionScreen extends StatefulWidget {
  final Election election;
  final ElectionPosition position;

  const UserVoteForPositionScreen({
    Key? key,
    required this.election,
    required this.position,
  }) : super(key: key);

  @override
  State<UserVoteForPositionScreen> createState() =>
      _UserVoteForPositionScreenState();
}

class _UserVoteForPositionScreenState extends State<UserVoteForPositionScreen> {
  final _repository = ElectionsRepository();
  final _auth = FirebaseAuth.instance;

  List<String> _selectedCandidateIds = [];
  List<ElectionCandidate> _candidates = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _hasAlreadyVoted = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userId = _auth.currentUser!.uid;

      // Check if already voted (using anonymous hash check)
      final hasVoted = await _repository.hasUserVotedForPosition(
        electionId: widget.election.id,
        positionId: widget.position.id,
        oderId: userId,
      );

      if (hasVoted && mounted) {
        setState(() => _hasAlreadyVoted = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have already voted for this position'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      // Load candidates
      final candidates = await _repository
          .getApprovedCandidatesForPosition(widget.position.id)
          .first;

      if (mounted) {
        setState(() {
          _candidates = candidates;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleVote(String candidateId) {
    if (_hasAlreadyVoted) return;

    setState(() {
      if (_selectedCandidateIds.contains(candidateId)) {
        _selectedCandidateIds.remove(candidateId);
      } else {
        if (_selectedCandidateIds.length < widget.position.maxWinners) {
          _selectedCandidateIds.add(candidateId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Maximum ${widget.position.maxWinners} selection(s) allowed'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    });
  }

  Future<void> _submitVote() async {
    if (_selectedCandidateIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one candidate'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Your Vote'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your vote is anonymous and cannot be traced back to you.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            const Text(
              'Once submitted, your vote cannot be changed. Are you sure?',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user,
                      color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Your identity is protected',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
            ),
            child: const Text('Submit Vote'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);

    try {
      final userId = _auth.currentUser!.uid;

      // Submit anonymous vote
      await _repository.submitAnonymousVote(
        electionId: widget.election.id,
        positionId: widget.position.id,
        oderId: userId,
        candidateIds: _selectedCandidateIds,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Vote submitted successfully! Your vote is anonymous.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error submitting vote: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit vote: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF10B981),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Cast Your Vote',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header Info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF10B981),
                        const Color(0xFF10B981).withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        widget.position.positionName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Select up to ${widget.position.maxWinners} candidate${widget.position.maxWinners > 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_user,
                                size: 16, color: Colors.white),
                            const SizedBox(width: 6),
                            const Text(
                              'Anonymous Voting',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${_selectedCandidateIds.length}/${widget.position.maxWinners} selected',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Already Voted Banner
                if (_hasAlreadyVoted)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.orange.withOpacity(0.1),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: Colors.orange, size: 24),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'You have already voted for this position',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Candidates List
                Expanded(
                  child: _candidates.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline,
                                  size: 80, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No Candidates Available',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _candidates.length,
                          itemBuilder: (context, index) {
                            return _buildCandidateCard(_candidates[index]);
                          },
                        ),
                ),

                // Submit Button
                if (!_hasAlreadyVoted)
                  Container(
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
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                              _isSubmitting || _selectedCandidateIds.isEmpty
                                  ? null
                                  : _submitVote,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check_circle),
                          label: Text(
                            _isSubmitting ? 'Submitting...' : 'Submit Vote',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildCandidateCard(ElectionCandidate candidate) {
    final isSelected = _selectedCandidateIds.contains(candidate.id);
    final isDisabled = _hasAlreadyVoted;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : () => _toggleVote(candidate.id),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF10B981).withOpacity(0.1)
                  : isDisabled
                      ? Colors.grey[100]
                      : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? const Color(0xFF10B981) : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFF10B981),
                  backgroundImage: candidate.photoUrl != null
                      ? NetworkImage(candidate.photoUrl!)
                      : null,
                  child: candidate.photoUrl == null
                      ? Text(
                          candidate.candidateName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDisabled ? Colors.grey : Colors.black,
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
                if (!isDisabled)
                  isSelected
                      ? const Icon(
                          Icons.check_circle,
                          color: Color(0xFF10B981),
                          size: 32,
                        )
                      : Icon(
                          Icons.radio_button_unchecked,
                          color: Colors.grey[400],
                          size: 32,
                        ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

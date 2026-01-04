import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/election_position.dart';
import '../models/election.dart';
import '../models/election_candidate.dart';

class ElectionsRepository {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Collections
  CollectionReference get _electionsCollection =>
      _firestore.collection('elections');
  CollectionReference get _positionsCollection =>
      _firestore.collection('elections_positions');
  CollectionReference get _candidatesCollection =>
      _firestore.collection('elections_candidates');
  CollectionReference get _votesCollection =>
      _firestore.collection('elections_votes');

  // ==================== VOTE ANONYMITY ====================

  /// Hash the voter ID for anonymity
  /// Uses SHA256 with election+position as salt to prevent cross-reference
  String _hashVoterId(String oderId, String electionId, String positionId) {
    final salt = '$electionId:$positionId';
    final data = utf8.encode('$oderId:$salt');
    final hash = sha256.convert(data);
    return hash.toString();
  }

  /// Check if user has voted (using hash comparison)
  Future<bool> hasUserVotedForPosition({
    required String electionId,
    required String positionId,
    required String oderId,
  }) async {
    final hashedId = _hashVoterId(oderId, electionId, positionId);

    final snapshot = await _votesCollection
        .where('electionId', isEqualTo: electionId)
        .where('positionId', isEqualTo: positionId)
        .where('voterHash', isEqualTo: hashedId)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  /// Submit anonymous vote
  Future<void> submitAnonymousVote({
    required String electionId,
    required String positionId,
    required String oderId,
    required List<String> candidateIds,
  }) async {
    // Check if already voted
    final hasVoted = await hasUserVotedForPosition(
      electionId: electionId,
      positionId: positionId,
      oderId: oderId,
    );

    if (hasVoted) {
      throw Exception('You have already voted for this position');
    }

    final hashedId = _hashVoterId(oderId, electionId, positionId);
    final batch = _firestore.batch();

    // Create anonymous vote record (no oderId stored, only hash)
    final voteRef = _votesCollection.doc();
    batch.set(voteRef, {
      'electionId': electionId,
      'positionId': positionId,
      'voterHash': hashedId, // Anonymous - can't trace back to user
      'candidateIds': candidateIds,
      'timeVoted': FieldValue.serverTimestamp(),
    });

    // Increment vote counts for selected candidates
    for (var candidateId in candidateIds) {
      final candidateRef = _candidatesCollection.doc(candidateId);
      batch.update(candidateRef, {
        'voteCount': FieldValue.increment(1),
      });
    }

    await batch.commit();
  }

  // ==================== RESULT AGGREGATION ====================

  /// Finalize election results - aggregate all votes
  /// Called by admin when voting period ends
  Future<void> finalizeElectionResults(String electionId) async {
    // Get all positions for this election
    final positionsSnapshot = await _positionsCollection
        .where('electionId', isEqualTo: electionId)
        .get();

    // Get all approved candidates for this election
    final candidatesSnapshot = await _candidatesCollection
        .where('electionId', isEqualTo: electionId)
        .where('status', isEqualTo: 'APPROVED')
        .get();

    // Build results map: { positionId: { candidateId: voteCount } }
    final Map<String, dynamic> candidateResults = {};

    for (var posDoc in positionsSnapshot.docs) {
      final positionId = posDoc.id;
      final positionName =
          (posDoc.data() as Map<String, dynamic>)['positionName'] ?? '';

      // Get candidates for this position
      final positionCandidates = candidatesSnapshot.docs
          .where((c) =>
              (c.data() as Map<String, dynamic>)['positionId'] == positionId)
          .toList();

      // Sort by vote count descending
      positionCandidates.sort((a, b) {
        final aVotes =
            (a.data() as Map<String, dynamic>)['voteCount'] as int? ?? 0;
        final bVotes =
            (b.data() as Map<String, dynamic>)['voteCount'] as int? ?? 0;
        return bVotes.compareTo(aVotes);
      });

      // Build position results
      final List<Map<String, dynamic>> positionResults = [];
      for (var candDoc in positionCandidates) {
        final candData = candDoc.data() as Map<String, dynamic>;
        positionResults.add({
          'candidateId': candDoc.id,
          'candidateName': candData['candidateName'] ?? '',
          'voteCount': candData['voteCount'] ?? 0,
          'lotNumber': candData['lotNumber'],
        });
      }

      candidateResults[positionId] = {
        'positionName': positionName,
        'candidates': positionResults,
        'totalVotes': positionResults.fold<int>(
            0, (sum, c) => sum + (c['voteCount'] as int)),
      };
    }

    // Get total unique voters
    final votesSnapshot =
        await _votesCollection.where('electionId', isEqualTo: electionId).get();

    final uniqueVoters =
        votesSnapshot.docs.map((d) => d['voterHash']).toSet().length;

    // Update election with final results
    await _electionsCollection.doc(electionId).update({
      'candidateResults': candidateResults,
      'totalVotesCast': uniqueVoters,
      'isFinalized': true,
      'finalizedAt': FieldValue.serverTimestamp(),
      'isActive': false, // Close the election
    });
  }

  /// Get election results (if finalized)
  Future<Map<String, dynamic>?> getElectionResults(String electionId) async {
    final doc = await _electionsCollection.doc(electionId).get();
    if (!doc.exists) return null;

    final data = doc.data() as Map<String, dynamic>;
    if (data['isFinalized'] != true) return null;

    return data['candidateResults'] as Map<String, dynamic>?;
  }

  /// Check and auto-finalize if voting has ended
  Future<bool> checkAndFinalizeIfEnded(String electionId) async {
    final doc = await _electionsCollection.doc(electionId).get();
    if (!doc.exists) return false;

    final data = doc.data() as Map<String, dynamic>;

    // Already finalized
    if (data['isFinalized'] == true) return true;

    // Check if voting period has ended
    final timeEnd = (data['timeEnd'] as Timestamp?)?.toDate();
    if (timeEnd == null) return false;

    if (DateTime.now().isAfter(timeEnd)) {
      // Voting ended, finalize results
      await finalizeElectionResults(electionId);
      return true;
    }

    return false;
  }

  // ==================== ELECTIONS ====================

  Stream<List<Election>> getAllElections() {
    return _electionsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Election.fromFirestore(doc)).toList();
    });
  }

  Stream<List<Election>> getActiveElections() {
    return _electionsCollection
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final elections =
          snapshot.docs.map((doc) => Election.fromFirestore(doc)).toList();
      elections.sort((a, b) => a.timeStart.compareTo(b.timeStart));
      return elections;
    });
  }

  Future<Election?> getElectionById(String electionId) async {
    final doc = await _electionsCollection.doc(electionId).get();
    if (!doc.exists) return null;
    return Election.fromFirestore(doc);
  }

  Future<void> createElection({
    required String electionName,
    required DateTime timeStart,
    required DateTime timeEnd,
    required int totalVerifiedVoters,
  }) async {
    final election = Election(
      id: '',
      electionName: electionName,
      timeStart: timeStart,
      timeEnd: timeEnd,
      isActive: true,
      candidateResults: {},
      totalVerifiedVoters: totalVerifiedVoters,
      status: ElectionStatus.upcoming,
      createdAt: DateTime.now(),
    );

    await _electionsCollection.add(election.toMap());
  }

  Future<void> updateElection(
    String electionId,
    Map<String, dynamic> updates,
  ) async {
    await _electionsCollection.doc(electionId).update(updates);
  }

  Future<void> deleteElection(String electionId) async {
    await _electionsCollection.doc(electionId).delete();
  }

  // ==================== POSITIONS ====================

  Stream<List<ElectionPosition>> getAllPositions() {
    return _positionsCollection.snapshots().map((snapshot) {
      final positions = snapshot.docs
          .map((doc) => ElectionPosition.fromFirestore(doc))
          .toList();
      positions.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return positions;
    });
  }

  Stream<List<ElectionPosition>> getActivePositions() {
    return _positionsCollection
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final positions = snapshot.docs
          .map((doc) => ElectionPosition.fromFirestore(doc))
          .toList();
      positions.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return positions;
    });
  }

  Stream<List<ElectionPosition>> getPositionsByElection(String electionId) {
    return _positionsCollection
        .where('electionId', isEqualTo: electionId)
        .snapshots()
        .map((snapshot) {
      final positions = snapshot.docs
          .map((doc) => ElectionPosition.fromFirestore(doc))
          .toList();
      positions.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return positions;
    });
  }

  Stream<List<ElectionPosition>> getActivePositionsByElection(
      String electionId) {
    return getPositionsByElection(electionId).map((positions) {
      return positions.where((p) => p.isActive).toList();
    });
  }

  Future<void> createPositionForElection({
    required String electionId,
    required String positionName,
    required int maxWinners,
    required int sortOrder,
    required DateTime nominationStart,
    required DateTime nominationEnd,
    required DateTime votingStart,
    required DateTime votingEnd,
  }) async {
    final position = ElectionPosition(
      id: '',
      positionName: positionName,
      electionId: electionId,
      maxWinners: maxWinners,
      sortOrder: sortOrder,
      isActive: true,
      nominationStart: nominationStart,
      nominationEnd: nominationEnd,
      votingStart: votingStart,
      votingEnd: votingEnd,
    );

    await _positionsCollection.add(position.toMap());
  }

  Future<void> updatePosition(
    String positionId,
    Map<String, dynamic> updates,
  ) async {
    final Map<String, dynamic> processedUpdates = {};

    updates.forEach((key, value) {
      if (value is DateTime) {
        processedUpdates[key] = Timestamp.fromDate(value);
      } else {
        processedUpdates[key] = value;
      }
    });

    await _positionsCollection.doc(positionId).update(processedUpdates);
  }

  Future<void> deletePosition(String positionId) async {
    await _positionsCollection.doc(positionId).delete();
  }

  // ==================== CANDIDATES ====================

  Stream<List<ElectionCandidate>> getCandidatesByElection(String electionId) {
    return _candidatesCollection
        .where('electionId', isEqualTo: electionId)
        .snapshots()
        .map((snapshot) {
      final candidates = snapshot.docs
          .map((doc) => ElectionCandidate.fromFirestore(doc))
          .toList();
      candidates.sort((a, b) => b.voteCount.compareTo(a.voteCount));
      return candidates;
    });
  }

  Stream<List<ElectionCandidate>> getCandidatesByPosition(String positionId) {
    return _candidatesCollection
        .where('positionId', isEqualTo: positionId)
        .snapshots()
        .map((snapshot) {
      final candidates = snapshot.docs
          .map((doc) => ElectionCandidate.fromFirestore(doc))
          .toList();
      candidates.sort((a, b) => b.voteCount.compareTo(a.voteCount));
      return candidates;
    });
  }

  Stream<List<ElectionCandidate>> getApprovedCandidates(String electionId) {
    return _candidatesCollection
        .where('electionId', isEqualTo: electionId)
        .where('status', isEqualTo: 'APPROVED')
        .snapshots()
        .map((snapshot) {
      final candidates = snapshot.docs
          .map((doc) => ElectionCandidate.fromFirestore(doc))
          .toList();
      return candidates;
    });
  }

  Stream<List<ElectionCandidate>> getApprovedCandidatesForPosition(
      String positionId) {
    return _candidatesCollection
        .where('positionId', isEqualTo: positionId)
        .where('status', isEqualTo: 'APPROVED')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ElectionCandidate.fromFirestore(doc))
          .toList();
    });
  }

  Stream<List<ElectionCandidate>> getPendingCandidates() {
    return _candidatesCollection
        .where('status', isEqualTo: 'PENDING')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ElectionCandidate.fromFirestore(doc))
          .toList();
    });
  }

  Future<bool> hasUserNominatedForPosition({
    required String electionId,
    required String positionId,
    required String userId,
  }) async {
    final snapshot = await _candidatesCollection
        .where('electionId', isEqualTo: electionId)
        .where('positionId', isEqualTo: positionId)
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  Future<bool> isUserRunningInElection({
    required String electionId,
    required String userId,
  }) async {
    final snapshot = await _candidatesCollection
        .where('electionId', isEqualTo: electionId)
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  Future<void> createCandidate({
    required String electionId,
    required String positionId,
    required String userId,
    required String candidateName,
    String? lotNumber,
    String? photoUrl,
  }) async {
    await _candidatesCollection.add({
      'electionId': electionId,
      'positionId': positionId,
      'userId': userId,
      'candidateName': candidateName,
      'lotNumber': lotNumber,
      'photoUrl': photoUrl,
      'voteCount': 0,
      'status': 'PENDING',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateCandidateStatus(
    String candidateId,
    CandidateStatus status,
  ) async {
    await _candidatesCollection.doc(candidateId).update({
      'status': status.name.toUpperCase(),
    });
  }

  Future<void> deleteCandidate(String candidateId) async {
    await _candidatesCollection.doc(candidateId).delete();
  }

  // ==================== STATISTICS ====================

  Future<Map<String, int>> getElectionStats() async {
    final electionsSnapshot = await _electionsCollection.get();

    int total = electionsSnapshot.docs.length;
    int active = 0;
    int upcoming = 0;
    int closed = 0;

    for (var doc in electionsSnapshot.docs) {
      final election = Election.fromFirestore(doc);
      switch (election.status) {
        case ElectionStatus.active:
          active++;
          break;
        case ElectionStatus.upcoming:
          upcoming++;
          break;
        case ElectionStatus.closed:
          closed++;
          break;
      }
    }

    return {
      'total': total,
      'active': active,
      'upcoming': upcoming,
      'closed': closed,
    };
  }

  Future<int> getCandidateCount(String electionId) async {
    final snapshot = await _candidatesCollection
        .where('electionId', isEqualTo: electionId)
        .get();
    return snapshot.docs.length;
  }

  Future<int> getVoteCount(String electionId) async {
    final snapshot =
        await _votesCollection.where('electionId', isEqualTo: electionId).get();
    return snapshot.docs.length;
  }
}

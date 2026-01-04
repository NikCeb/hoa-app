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

  // ==================== ELECTIONS ====================

  /// Get all elections
  Stream<List<Election>> getAllElections() {
    return _electionsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Election.fromFirestore(doc)).toList();
    });
  }

  /// Get active elections
  Stream<List<Election>> getActiveElections() {
    return _electionsCollection
        .where('isActive', isEqualTo: true)
        .orderBy('timeStart', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Election.fromFirestore(doc)).toList();
    });
  }

  /// Create election
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

  /// Update election
  Future<void> updateElection(
    String electionId,
    Map<String, dynamic> updates,
  ) async {
    await _electionsCollection.doc(electionId).update(updates);
  }

  /// Delete election
  Future<void> deleteElection(String electionId) async {
    await _electionsCollection.doc(electionId).delete();
  }

  // ==================== POSITIONS ====================

  /// Get all positions
  Stream<List<ElectionPosition>> getAllPositions() {
    return _positionsCollection
        .orderBy('sortOrder')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ElectionPosition.fromFirestore(doc))
          .toList();
    });
  }

  /// Get active positions
  Stream<List<ElectionPosition>> getActivePositions() {
    return _positionsCollection
        .where('isActive', isEqualTo: true)
        .orderBy('sortOrder')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ElectionPosition.fromFirestore(doc))
          .toList();
    });
  }

  /// Create position
  Future<void> createPosition({
    required String positionName,
    required int maxWinners,
    required int sortOrder,
  }) async {
    final position = ElectionPosition(
      id: '',
      positionName: positionName,
      maxWinners: maxWinners,
      sortOrder: sortOrder,
      isActive: true,
    );

    await _positionsCollection.add(position.toMap());
  }

  /// Update position
  Future<void> updatePosition(
    String positionId,
    Map<String, dynamic> updates,
  ) async {
    await _positionsCollection.doc(positionId).update(updates);
  }

  /// Delete position
  Future<void> deletePosition(String positionId) async {
    await _positionsCollection.doc(positionId).delete();
  }

  // ==================== CANDIDATES ====================

  /// Get candidates for an election
  Stream<List<ElectionCandidate>> getCandidatesByElection(String electionId) {
    return _candidatesCollection
        .where('electionId', isEqualTo: electionId)
        .orderBy('voteCount', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ElectionCandidate.fromFirestore(doc))
          .toList();
    });
  }

  /// Get approved candidates for an election
  Stream<List<ElectionCandidate>> getApprovedCandidates(String electionId) {
    return _candidatesCollection
        .where('electionId', isEqualTo: electionId)
        .where('status', isEqualTo: 'APPROVED')
        .orderBy('positionId')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ElectionCandidate.fromFirestore(doc))
          .toList();
    });
  }

  /// Get pending candidates
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

  /// Update candidate status
  Future<void> updateCandidateStatus(
    String candidateId,
    CandidateStatus status,
  ) async {
    await _candidatesCollection.doc(candidateId).update({
      'status': status.name.toUpperCase(),
    });
  }

  /// Delete candidate
  Future<void> deleteCandidate(String candidateId) async {
    await _candidatesCollection.doc(candidateId).delete();
  }

  // ==================== STATISTICS ====================

  /// Get election statistics
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

  /// Get candidate count for election
  Future<int> getCandidateCount(String electionId) async {
    final snapshot = await _candidatesCollection
        .where('electionId', isEqualTo: electionId)
        .get();
    return snapshot.docs.length;
  }

  /// Get vote count for election
  Future<int> getVoteCount(String electionId) async {
    final snapshot =
        await _votesCollection.where('electionId', isEqualTo: electionId).get();
    return snapshot.docs.length;
  }
}

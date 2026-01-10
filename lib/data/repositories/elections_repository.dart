import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/election_position.dart';
import '../models/election_candidate.dart';

class ElectionsRepository {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Collections
  CollectionReference get _positionsCollection =>
      _firestore.collection('elections_positions');
  CollectionReference get _candidatesCollection =>
      _firestore.collection('elections_candidates');
  CollectionReference get _votesCollection =>
      _firestore.collection('elections_votes');

  // ==================== VOTE ANONYMITY ====================

  /// Hash the voter ID for anonymity
  String _hashVoterId(String userId, String positionId) {
    final salt = positionId;
    final data = utf8.encode('$userId:$salt');
    final hash = sha256.convert(data);
    return hash.toString();
  }

  /// Check if user has voted for this position
  Future<bool> hasUserVoted({
    required String positionId,
    required String userId,
  }) async {
    final hashedId = _hashVoterId(userId, positionId);

    final snapshot = await _votesCollection
        .where('positionId', isEqualTo: positionId)
        .where('voterHash', isEqualTo: hashedId)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  /// Check if user has applied for this position
  Future<bool> hasUserApplied({
    required String positionId,
    required String userId,
  }) async {
    final snapshot = await _candidatesCollection
        .where('positionId', isEqualTo: positionId)
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  // ==================== POSITIONS ====================

  /// Get all positions (for admin)
  Stream<List<ElectionPosition>> getAllPositions() {
    return _positionsCollection.snapshots().map((snapshot) {
      final positions = snapshot.docs
          .map((doc) => ElectionPosition.fromFirestore(doc))
          .toList();

      // Client-side sort by createdAt descending
      positions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return positions;
    });
  }

  /// Get active positions only (for users)
  Stream<List<ElectionPosition>> getActivePositions() {
    return _positionsCollection
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final positions = snapshot.docs
          .map((doc) => ElectionPosition.fromFirestore(doc))
          .toList();

      // Filter out ended positions
      final activePositions = positions.where((p) => !p.isEnded).toList();

      // Client-side sort by deadline ascending
      activePositions.sort((a, b) => a.deadline.compareTo(b.deadline));
      return activePositions;
    });
  }

  /// Get all user-visible positions (active + ended with isActive=true)
  /// This shows both ongoing elections and completed elections with results
  Stream<List<ElectionPosition>> getAllUserPositions() {
    return _positionsCollection
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final positions = snapshot.docs
          .map((doc) => ElectionPosition.fromFirestore(doc))
          .toList();

      // Sort: Active first (by deadline), then ended (by deadline)
      positions.sort((a, b) {
        // Both active or both ended - sort by deadline
        if (a.isEnded == b.isEnded) {
          return a.deadline.compareTo(b.deadline);
        }
        // Active positions come first
        return a.isEnded ? 1 : -1;
      });

      return positions;
    });
  }

  /// Get single position by ID
  Future<ElectionPosition?> getPositionById(String positionId) async {
    final doc = await _positionsCollection.doc(positionId).get();
    if (!doc.exists) return null;
    return ElectionPosition.fromFirestore(doc);
  }

  /// Create new position
  Future<void> createPosition({
    required String positionName,
    required String description,
    required DateTime deadline,
  }) async {
    final position = ElectionPosition(
      id: '',
      positionName: positionName,
      description: description,
      deadline: deadline,
      isActive: true,
      createdAt: DateTime.now(),
    );

    await _positionsCollection.add(position.toMap());
  }

  /// End position early (admin)
  Future<void> endPositionEarly(String positionId) async {
    await _positionsCollection.doc(positionId).update({
      'endedEarly': true, // CHANGED: Use endedEarly instead of isActive
    });
  }

  /// Delete position (admin)
  Future<void> deletePosition(String positionId) async {
    // Set isActive to false instead of deleting
    // This hides it from user view but keeps data
    await _positionsCollection.doc(positionId).update({
      'isActive': false,
    });

    // Optional: Also delete related candidates and votes
    final candidatesSnapshot = await _candidatesCollection
        .where('positionId', isEqualTo: positionId)
        .get();

    final votesSnapshot =
        await _votesCollection.where('positionId', isEqualTo: positionId).get();

    final batch = _firestore.batch();
    for (var doc in candidatesSnapshot.docs) {
      batch.delete(doc.reference);
    }
    for (var doc in votesSnapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
  // ==================== CANDIDATES ====================

  /// Get candidates for a position
  Stream<List<ElectionCandidate>> getCandidatesForPosition(String positionId) {
    return _candidatesCollection
        .where('positionId', isEqualTo: positionId)
        .snapshots()
        .map((snapshot) {
      final candidates = snapshot.docs
          .map((doc) => ElectionCandidate.fromFirestore(doc))
          .toList();

      // Client-side sort by vote count descending
      candidates.sort((a, b) => b.voteCount.compareTo(a.voteCount));
      return candidates;
    });
  }

  /// Get candidate count for a position
  Future<int> getCandidateCount(String positionId) async {
    final snapshot = await _candidatesCollection
        .where('positionId', isEqualTo: positionId)
        .get();
    return snapshot.docs.length;
  }

  /// Get total votes for a position
  Future<int> getTotalVotes(String positionId) async {
    final snapshot = await _candidatesCollection
        .where('positionId', isEqualTo: positionId)
        .get();

    int total = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      total += (data['voteCount'] as int? ?? 0);
    }
    return total;
  }

  /// Apply for position (creates candidate with self-vote)
  Future<void> applyForPosition({
    required String positionId,
    required String userId,
    required String candidateName,
    String? lotNumber,
  }) async {
    // VALIDATION 1: Check if already applied
    final hasApplied = await hasUserApplied(
      positionId: positionId,
      userId: userId,
    );

    if (hasApplied) {
      throw Exception('You have already applied for this position');
    }

    // VALIDATION 2: Check if already voted (NEW!)
    final hasVoted = await hasUserVoted(
      positionId: positionId,
      userId: userId,
    );

    if (hasVoted) {
      throw Exception(
          'You have already voted for this position. You cannot run after voting.');
    }

    final batch = _firestore.batch();

    // Create candidate with voteCount = 1 (self-vote)
    final candidateRef = _candidatesCollection.doc();
    final candidate = ElectionCandidate(
      id: candidateRef.id,
      electionId:
          positionId, // Using positionId as electionId for simplified flow
      positionId: positionId,
      userId: userId,
      candidateName: candidateName,
      lotNumber: lotNumber,
      photoUrl: null,
      voteCount: 1, // Self-vote
      status: 'APPROVED', // Auto-approved
      createdAt: DateTime.now(),
    );
    batch.set(candidateRef, candidate.toMap());

    // Create anonymous vote record for self-vote
    final hashedId = _hashVoterId(userId, positionId);
    final voteRef = _votesCollection.doc();
    batch.set(voteRef, {
      'positionId': positionId,
      'voterHash': hashedId,
      'candidateId': candidateRef.id,
      'votedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Remove a candidate (admin only)
  Future<void> removeCandidate(String candidateId) async {
    final batch = _firestore.batch();

    // Get candidate data first
    final candidateDoc = await _candidatesCollection.doc(candidateId).get();
    if (!candidateDoc.exists) {
      throw Exception('Candidate not found');
    }

    final candidateData = candidateDoc.data() as Map<String, dynamic>;
    final positionId = candidateData['positionId'] as String;
    final userId = candidateData['userId'] as String;

    // Delete candidate
    batch.delete(_candidatesCollection.doc(candidateId));

    // Delete their vote record (the self-vote or any vote they cast)
    final hashedId = _hashVoterId(userId, positionId);
    final votesSnapshot = await _votesCollection
        .where('positionId', isEqualTo: positionId)
        .where('voterHash', isEqualTo: hashedId)
        .get();

    for (var voteDoc in votesSnapshot.docs) {
      batch.delete(voteDoc.reference);
    }

    await batch.commit();
  }
  // ==================== VOTING ====================

  /// Vote for a candidate
  Future<void> voteForCandidate({
    required String positionId,
    required String candidateId,
    required String userId,
  }) async {
    // Check if user is running for this position
    final isRunning = await hasUserApplied(
      positionId: positionId,
      userId: userId,
    );

    if (isRunning) {
      throw Exception(
          'You cannot vote for others while running for this position');
    }

    // Check if already voted
    final hasVoted = await hasUserVoted(
      positionId: positionId,
      userId: userId,
    );

    if (hasVoted) {
      throw Exception('You have already voted for this position');
    }

    final batch = _firestore.batch();

    // Increment candidate vote count
    final candidateRef = _candidatesCollection.doc(candidateId);
    batch.update(candidateRef, {
      'voteCount': FieldValue.increment(1),
    });

    // Create anonymous vote record
    final hashedId = _hashVoterId(userId, positionId);
    final voteRef = _votesCollection.doc();
    batch.set(voteRef, {
      'positionId': positionId,
      'voterHash': hashedId,
      'candidateId': candidateId,
      'votedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Get which candidate the user voted for (if any)
  Future<String?> getUserVotedCandidateId({
    required String positionId,
    required String userId,
  }) async {
    final hashedId = _hashVoterId(userId, positionId);

    final snapshot = await _votesCollection
        .where('positionId', isEqualTo: positionId)
        .where('voterHash', isEqualTo: hashedId)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final data = snapshot.docs.first.data() as Map<String, dynamic>;
    return data['candidateId'] as String?;
  }

  /// Get candidate details by ID
  Future<ElectionCandidate?> getCandidateById(String candidateId) async {
    final doc = await _candidatesCollection.doc(candidateId).get();
    if (!doc.exists) return null;
    return ElectionCandidate.fromFirestore(doc);
  }
}

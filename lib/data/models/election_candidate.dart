import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum CandidateStatus { pending, approved, rejected }

class ElectionCandidate {
  final String id;
  final String electionId;
  final String positionId;
  final String userId;
  final String candidateName;
  final String? lotNumber;
  final String? photoUrl;
  final int voteCount;
  final CandidateStatus status;

  ElectionCandidate({
    required this.id,
    required this.electionId,
    required this.positionId,
    required this.userId,
    required this.candidateName,
    this.lotNumber,
    this.photoUrl,
    required this.voteCount,
    required this.status,
  });

  factory ElectionCandidate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    CandidateStatus parseStatus(String? value) {
      switch (value?.toUpperCase()) {
        case 'APPROVED':
          return CandidateStatus.approved;
        case 'REJECTED':
          return CandidateStatus.rejected;
        default:
          return CandidateStatus.pending;
      }
    }

    return ElectionCandidate(
      id: doc.id,
      electionId: data['electionId'],
      positionId: data['positionId'],
      userId: data['userId'],
      candidateName: data['candidateName'] ?? '',
      lotNumber: data['lotNumber'],
      photoUrl: data['photoUrl'],
      voteCount: data['voteCount'] ?? 0,
      status: parseStatus(data['status']),
    );
  }

  /// ✅ THIS IS WHAT YOUR UI NEEDS
  Color get statusColor {
    switch (status) {
      case CandidateStatus.pending:
        return const Color(0xFFF59E0B); // orange
      case CandidateStatus.approved:
        return const Color(0xFF10B981); // green
      case CandidateStatus.rejected:
        return const Color(0xFFEF4444); // red
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

enum CandidateStatus {
  pending,
  approved,
  rejected,
}

class ElectionCandidate {
  final String id;
  final String positionId;
  final String userId;
  final String? photoUrl;
  final int voteCount;
  final String electionId;
  final String candidateName;
  final String? lotNumber;
  final CandidateStatus status;

  ElectionCandidate({
    required this.id,
    required this.positionId,
    required this.userId,
    this.photoUrl,
    required this.voteCount,
    required this.electionId,
    required this.candidateName,
    this.lotNumber,
    required this.status,
  });

  factory ElectionCandidate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ElectionCandidate(
      id: doc.id,
      positionId: data['positionId'] ?? '',
      userId: data['userId'] ?? '',
      photoUrl: data['photoUrl'] as String?,
      voteCount: data['voteCount'] ?? 0,
      electionId: data['electionId'] ?? '',
      candidateName: data['candidateName'] ?? '',
      lotNumber: data['lotNumber'] as String?,
      status: _statusFromString(data['status']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'positionId': positionId,
      'userId': userId,
      'photoUrl': photoUrl,
      'voteCount': voteCount,
      'electionId': electionId,
      'candidateName': candidateName,
      'lotNumber': lotNumber,
      'status': status.name.toUpperCase(),
    };
  }

  static CandidateStatus _statusFromString(dynamic status) {
    if (status == null) return CandidateStatus.pending;
    switch (status.toString().toUpperCase()) {
      case 'APPROVED':
        return CandidateStatus.approved;
      case 'REJECTED':
        return CandidateStatus.rejected;
      default:
        return CandidateStatus.pending;
    }
  }

  String get statusText {
    switch (status) {
      case CandidateStatus.pending:
        return 'Pending';
      case CandidateStatus.approved:
        return 'Approved';
      case CandidateStatus.rejected:
        return 'Rejected';
    }
  }
}

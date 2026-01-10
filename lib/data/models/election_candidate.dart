import 'package:cloud_firestore/cloud_firestore.dart';

class ElectionCandidate {
  final String id;
  final String electionId; // Required in old schema
  final String positionId;
  final String userId;
  final String candidateName;
  final String? lotNumber;
  final String? photoUrl;
  final int voteCount;
  final String status; // String, not enum
  final DateTime createdAt; // Was 'appliedAt' in new code

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
    required this.createdAt,
  });

  factory ElectionCandidate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.now();
    }

    return ElectionCandidate(
      id: doc.id,
      electionId: data['electionId'] ?? '',
      positionId: data['positionId'] ?? '',
      userId: data['userId'] ?? '',
      candidateName: data['candidateName'] ?? '',
      lotNumber: data['lotNumber'],
      photoUrl: data['photoUrl'],
      voteCount: data['voteCount'] ?? 0,
      status: data['status'] ?? 'APPROVED',
      createdAt: parseDate(data['createdAt'] ?? data['appliedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'electionId': electionId,
      'positionId': positionId,
      'userId': userId,
      'candidateName': candidateName,
      if (lotNumber != null) 'lotNumber': lotNumber,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'voteCount': voteCount,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  bool get isApproved => status == 'APPROVED';
}

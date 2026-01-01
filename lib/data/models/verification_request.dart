import 'package:cloud_firestore/cloud_firestore.dart';

class VerificationRequest {
  final String id;
  final String userId;
  final String userName;
  final String email;
  final String phase;
  final String block;
  final String lotNumber;
  final String fullAddress;
  final String status;
  final String? adminNotes;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  VerificationRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.email,
    required this.phase,
    required this.block,
    required this.lotNumber,
    required this.fullAddress,
    this.status = 'pending',
    this.adminNotes,
    required this.createdAt,
    this.reviewedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'email': email,
      'phase': phase,
      'block': block,
      'lotNumber': lotNumber,
      'fullAddress': fullAddress,
      'status': status,
      'adminNotes': adminNotes,
      'createdAt': Timestamp.fromDate(createdAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
    };
  }

  factory VerificationRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VerificationRequest(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      email: data['email'] ?? '',
      phase: data['phase'] ?? '',
      block: data['block'] ?? '',
      lotNumber: data['lotNumber'] ?? '',
      fullAddress: data['fullAddress'] ?? '',
      status: data['status'] ?? 'pending',
      adminNotes: data['adminNotes'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
    );
  }

  VerificationRequest copyWith({
    String? id,
    String? userId,
    String? userName,
    String? email,
    String? phase,
    String? block,
    String? lotNumber,
    String? fullAddress,
    String? status,
    String? adminNotes,
    DateTime? createdAt,
    DateTime? reviewedAt,
  }) {
    return VerificationRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      email: email ?? this.email,
      phase: phase ?? this.phase,
      block: block ?? this.block,
      lotNumber: lotNumber ?? this.lotNumber,
      fullAddress: fullAddress ?? this.fullAddress,
      status: status ?? this.status,
      adminNotes: adminNotes ?? this.adminNotes,
      createdAt: createdAt ?? this.createdAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }
}

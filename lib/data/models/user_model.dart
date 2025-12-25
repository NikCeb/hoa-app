import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { admin, user }

enum VerificationStatus { pending, approved, rejected }

class UserModel {
  final String uid;
  final String email;
  final String firstName;
  final String middleName;
  final String lastName;
  final String suffix;
  final String fullAddress;
  final String phase;
  final String block;
  final String lotNumber;
  final UserRole role;
  final VerificationStatus verificationStatus;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int? lotId;

  UserModel({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.suffix,
    required this.fullAddress,
    required this.phase,
    required this.block,
    required this.lotNumber,
    required this.role,
    required this.verificationStatus,
    required this.createdAt,
    this.updatedAt,
    this.lotId,
  });

  // Factory constructor from Firestore
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? '',
      middleName: data['middleName'] ?? '',
      lastName: data['lastName'] ?? '',
      suffix: data['suffix'] ?? '',
      fullAddress: data['fullAddress'] ?? '',
      phase: data['phase'] ?? '',
      block: data['block'] ?? '',
      lotNumber: data['lotNumber'] ?? '',
      role: _parseRole(data['role']),
      verificationStatus: _parseVerificationStatus(data['verificationStatus']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      lotId: data['lotId'],
    );
  }

  // Factory constructor from Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      firstName: map['firstName'] ?? '',
      middleName: map['middleName'] ?? '',
      lastName: map['lastName'] ?? '',
      suffix: map['suffix'] ?? '',
      fullAddress: map['fullAddress'] ?? '',
      phase: map['phase'] ?? '',
      block: map['block'] ?? '',
      lotNumber: map['lotNumber'] ?? '',
      role: _parseRole(map['role']),
      verificationStatus: _parseVerificationStatus(map['verificationStatus']),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      lotId: map['lotId'],
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'suffix': suffix,
      'fullAddress': fullAddress,
      'phase': phase,
      'block': block,
      'lotNumber': lotNumber,
      'role': role.name,
      'verificationStatus': verificationStatus.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'lotId': lotId,
    };
  }

  // Get full name
  String get fullName {
    String name = '$firstName';
    if (middleName.isNotEmpty) name += ' $middleName';
    name += ' $lastName';
    if (suffix.isNotEmpty) name += ' $suffix';
    return name;
  }

  // Check if user is admin
  bool get isAdmin => role == UserRole.admin;

  // Check if user is approved
  bool get isApproved => verificationStatus == VerificationStatus.approved;

  // Copy with method
  UserModel copyWith({
    String? uid,
    String? email,
    String? firstName,
    String? middleName,
    String? lastName,
    String? suffix,
    String? fullAddress,
    String? phase,
    String? block,
    String? lotNumber,
    UserRole? role,
    VerificationStatus? verificationStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? lotId,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      suffix: suffix ?? this.suffix,
      fullAddress: fullAddress ?? this.fullAddress,
      phase: phase ?? this.phase,
      block: block ?? this.block,
      lotNumber: lotNumber ?? this.lotNumber,
      role: role ?? this.role,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lotId: lotId ?? this.lotId,
    );
  }

  // Helper methods to parse enums
  static UserRole _parseRole(dynamic role) {
    if (role is String) {
      return role == 'admin' ? UserRole.admin : UserRole.user;
    }
    return UserRole.user;
  }

  static VerificationStatus _parseVerificationStatus(dynamic status) {
    if (status is String) {
      switch (status) {
        case 'approved':
          return VerificationStatus.approved;
        case 'rejected':
          return VerificationStatus.rejected;
        default:
          return VerificationStatus.pending;
      }
    }
    return VerificationStatus.pending;
  }
}

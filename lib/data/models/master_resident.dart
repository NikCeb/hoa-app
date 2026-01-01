import 'package:cloud_firestore/cloud_firestore.dart';

class MasterResident {
  final String id;
  final int lotId;
  final String phase;
  final String block;
  final String lotNumber;
  final String fullAddress;
  final String firstName;
  final String middleName;
  final String lastName;
  final String suffix;
  final String? userId;
  final bool isAvailable;
  final bool isRental;
  final DateTime createdAt;
  final DateTime updatedAt;

  MasterResident({
    required this.id,
    required this.lotId,
    required this.phase,
    required this.block,
    required this.lotNumber,
    required this.fullAddress,
    required this.firstName,
    this.middleName = '',
    required this.lastName,
    this.suffix = '',
    this.userId,
    required this.isAvailable,
    this.isRental = false,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName {
    String name = firstName;
    if (middleName.isNotEmpty) name += ' $middleName';
    name += ' $lastName';
    if (suffix.isNotEmpty) name += ' $suffix';
    return name;
  }

  String get matchKey {
    return '${firstName.toLowerCase()}|${lastName.toLowerCase()}|$lotNumber';
  }

  Map<String, dynamic> toMap() {
    return {
      'lotId': lotId,
      'phase': phase,
      'block': block,
      'lotNumber': lotNumber,
      'fullAddress': fullAddress,
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'suffix': suffix,
      'userId': userId,
      'isAvailable': isAvailable,
      'isRental': isRental,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory MasterResident.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MasterResident(
      id: doc.id,
      lotId: data['lotId'] ?? 0,
      phase: data['phase'] ?? '',
      block: data['block'] ?? '',
      lotNumber: data['lotNumber'] ?? '',
      fullAddress: data['fullAddress'] ?? '',
      firstName: data['firstName'] ?? '',
      middleName: data['middleName'] ?? '',
      lastName: data['lastName'] ?? '',
      suffix: data['suffix'] ?? '',
      userId: data['userId'],
      isAvailable: data['isAvailable'] ?? true,
      isRental: data['isRental'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  MasterResident copyWith({
    String? id,
    int? lotId,
    String? phase,
    String? block,
    String? lotNumber,
    String? fullAddress,
    String? firstName,
    String? middleName,
    String? lastName,
    String? suffix,
    String? userId,
    bool? isAvailable,
    bool? isRental,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MasterResident(
      id: id ?? this.id,
      lotId: lotId ?? this.lotId,
      phase: phase ?? this.phase,
      block: block ?? this.block,
      lotNumber: lotNumber ?? this.lotNumber,
      fullAddress: fullAddress ?? this.fullAddress,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      suffix: suffix ?? this.suffix,
      userId: userId ?? this.userId,
      isAvailable: isAvailable ?? this.isAvailable,
      isRental: isRental ?? this.isRental,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

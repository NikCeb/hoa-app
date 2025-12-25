// lib/data/models/master_resident.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class MasterResident {
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

  MasterResident({
    required this.lotId,
    required this.phase,
    required this.block,
    required this.lotNumber,
    required this.fullAddress,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.suffix,
    this.userId,
    required this.isAvailable,
    required this.isRental,
  });

  // Factory constructor to create a MasterResident from Firestore document
  factory MasterResident.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MasterResident(
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
      isAvailable: data['isAvailable'] ?? false,
      isRental: data['isRental'] ?? false,
    );
  }

  // Factory constructor to create a MasterResident from JSON/Map
  factory MasterResident.fromMap(Map<String, dynamic> map) {
    return MasterResident(
      lotId: map['lotId'] ?? 0,
      phase: map['phase'] ?? '',
      block: map['block'] ?? '',
      lotNumber: map['lotNumber'] ?? '',
      fullAddress: map['fullAddress'] ?? '',
      firstName: map['firstName'] ?? '',
      middleName: map['middleName'] ?? '',
      lastName: map['lastName'] ?? '',
      suffix: map['suffix'] ?? '',
      userId: map['userId'],
      isAvailable: map['isAvailable'] ?? false,
      isRental: map['isRental'] ?? false,
    );
  }

  // Convert MasterResident to Map for Firestore
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

  // Check if resident matches user input (for verification)
  bool matches(
      String inputFirstName, String inputLastName, String inputAddress) {
    return firstName.toLowerCase().trim() ==
            inputFirstName.toLowerCase().trim() &&
        lastName.toLowerCase().trim() == inputLastName.toLowerCase().trim() &&
        fullAddress.toLowerCase().trim() == inputAddress.toLowerCase().trim();
  }

  // Copy with method for updating fields
  MasterResident copyWith({
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
  }) {
    return MasterResident(
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
    );
  }
}

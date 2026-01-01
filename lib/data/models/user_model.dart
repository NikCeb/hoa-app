import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String firstName;
  final String middleName;
  final String lastName;
  final String suffix;
  final String phase;
  final String block;
  final String lotNumber;
  final String fullAddress;
  final String? lotId;
  final bool isVerified;
  final String role;
  final int tulongCount;
  final int requestsPosted;
  final int timesHelped;
  final int offersMade;
  final double responseRate;
  final List<String> badges;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.firstName,
    this.middleName = '',
    required this.lastName,
    this.suffix = '',
    required this.phase,
    required this.block,
    required this.lotNumber,
    required this.fullAddress,
    this.lotId,
    this.isVerified = false,
    this.role = 'user',
    this.tulongCount = 0,
    this.requestsPosted = 0,
    this.timesHelped = 0,
    this.offersMade = 0,
    this.responseRate = 0.0,
    this.badges = const [],
    this.photoUrl,
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

  bool get isAdmin => role == 'admin';

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'suffix': suffix,
      'phase': phase,
      'block': block,
      'lotNumber': lotNumber,
      'fullAddress': fullAddress,
      'lotId': lotId,
      'isVerified': isVerified,
      'role': role,
      'tulongCount': tulongCount,
      'requestsPosted': requestsPosted,
      'timesHelped': timesHelped,
      'offersMade': offersMade,
      'responseRate': responseRate,
      'badges': badges,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? '',
      middleName: data['middleName'] ?? '',
      lastName: data['lastName'] ?? '',
      suffix: data['suffix'] ?? '',
      phase: data['phase'] ?? '',
      block: data['block'] ?? '',
      lotNumber: data['lotNumber'] ?? '',
      fullAddress: data['fullAddress'] ?? '',
      lotId: data['lotId'],
      isVerified: data['isVerified'] ?? false,
      role: data['role'] ?? 'user',
      tulongCount: data['tulongCount'] ?? 0,
      requestsPosted: data['requestsPosted'] ?? 0,
      timesHelped: data['timesHelped'] ?? 0,
      offersMade: data['offersMade'] ?? 0,
      responseRate: (data['responseRate'] ?? 0.0).toDouble(),
      badges: List<String>.from(data['badges'] ?? []),
      photoUrl: data['photoUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? firstName,
    String? middleName,
    String? lastName,
    String? suffix,
    String? phase,
    String? block,
    String? lotNumber,
    String? fullAddress,
    String? lotId,
    bool? isVerified,
    String? role,
    int? tulongCount,
    int? requestsPosted,
    int? timesHelped,
    int? offersMade,
    double? responseRate,
    List<String>? badges,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      suffix: suffix ?? this.suffix,
      phase: phase ?? this.phase,
      block: block ?? this.block,
      lotNumber: lotNumber ?? this.lotNumber,
      fullAddress: fullAddress ?? this.fullAddress,
      lotId: lotId ?? this.lotId,
      isVerified: isVerified ?? this.isVerified,
      role: role ?? this.role,
      tulongCount: tulongCount ?? this.tulongCount,
      requestsPosted: requestsPosted ?? this.requestsPosted,
      timesHelped: timesHelped ?? this.timesHelped,
      offersMade: offersMade ?? this.offersMade,
      responseRate: responseRate ?? this.responseRate,
      badges: badges ?? this.badges,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

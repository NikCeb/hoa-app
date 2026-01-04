import 'package:cloud_firestore/cloud_firestore.dart';

class ElectionPosition {
  final String id;
  final String positionName;
  final int maxWinners;
  final int sortOrder;
  final bool isActive;

  ElectionPosition({
    required this.id,
    required this.positionName,
    required this.maxWinners,
    required this.sortOrder,
    required this.isActive,
  });

  factory ElectionPosition.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ElectionPosition(
      id: doc.id,
      positionName: data['positionName'] ?? '',
      maxWinners: data['maxWinners'] ?? 1,
      sortOrder: data['sortOrder'] ?? 0,
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'positionName': positionName,
      'maxWinners': maxWinners,
      'sortOrder': sortOrder,
      'isActive': isActive,
    };
  }
}

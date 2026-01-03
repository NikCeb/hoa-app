import 'package:cloud_firestore/cloud_firestore.dart';

class MarketplaceCategory {
  final String id; // categoryId
  final String categoryName;
  final int sortOrder;
  final bool isActive;

  MarketplaceCategory({
    required this.id,
    required this.categoryName,
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory MarketplaceCategory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return MarketplaceCategory(
      id: doc.id,
      categoryName: data['categoryName'] ?? '',
      sortOrder: data['sortOrder'] ?? 0,
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'categoryName': categoryName,
      'sortOrder': sortOrder,
      'isActive': isActive,
    };
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

/// Payment Category Model - Defines standard HOA fees
///
/// Used by admin to set up recurring fees (monthly dues, special assessments, etc.)
/// Each category has a default fee and due day of month
class PaymentCategory {
  final String id;
  final String categoryName;
  final String description;
  final double defaultFee;
  final int dueDayOfMonth; // 1-28 (day of month bill is due)
  final bool isRecurring; // true for monthly dues, false for one-time
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  PaymentCategory({
    required this.id,
    required this.categoryName,
    required this.description,
    required this.defaultFee,
    required this.dueDayOfMonth,
    required this.isRecurring,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create from Firestore document
  factory PaymentCategory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentCategory(
      id: doc.id,
      categoryName: data['categoryName'] ?? '',
      description: data['description'] ?? '',
      defaultFee: (data['defaultFee'] ?? 0).toDouble(),
      dueDayOfMonth: data['dueDayOfMonth'] ?? 15,
      isRecurring: data['isRecurring'] ?? true,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'categoryName': categoryName,
      'description': description,
      'defaultFee': defaultFee,
      'dueDayOfMonth': dueDayOfMonth,
      'isRecurring': isRecurring,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// Format fee as currency
  String get formattedFee => '₱${defaultFee.toStringAsFixed(2)}';

  /// Copy with method for updates
  PaymentCategory copyWith({
    String? categoryName,
    String? description,
    double? defaultFee,
    int? dueDayOfMonth,
    bool? isRecurring,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return PaymentCategory(
      id: id,
      categoryName: categoryName ?? this.categoryName,
      description: description ?? this.description,
      defaultFee: defaultFee ?? this.defaultFee,
      dueDayOfMonth: dueDayOfMonth ?? this.dueDayOfMonth,
      isRecurring: isRecurring ?? this.isRecurring,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

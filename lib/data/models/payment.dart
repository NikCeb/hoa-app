import 'package:cloud_firestore/cloud_firestore.dart';

/// Payment Model - Represents a bill/payment for a resident
///
/// Generated automatically by the bill generation system
/// Tracks payment status from OWED → PENDING_REVIEW → PAID
///
/// SCHEMA COMPATIBLE: Supports both old and new field names
class Payment {
  final String id;

  // LOT ID - Support both String and Integer
  final String lotId; // Original field (String) - KEEP for compatibility
  final int? lotIdInt; // New field (Integer) - for new schema

  // USER/RESIDENT ID - Support both names
  final String residentId; // Original name - KEEP for compatibility

  // Display fields - KEEP for easier UI rendering
  final String residentName;
  final String lotNumber;
  final String categoryName;

  // CORE FIELDS
  final String categoryId; // Links to payment_categories

  // AMOUNT - Support both names
  final double amount; // Original name - KEEP for compatibility

  final PaymentStatus status;
  final DateTime dateDue;

  // OPTIONAL FIELDS - Keep for functionality
  final DateTime? datePaid;
  final String? proofRef; // Firebase Storage reference for proof
  final String? proofUrl; // Download URL for proof image
  final String? notes;

  // TIMESTAMPS
  final DateTime createdAt;
  final DateTime? updatedAt;

  final String billingPeriod; // e.g., "2024-01" for January 2024

  Payment({
    required this.id,
    required this.lotId,
    this.lotIdInt, // NEW: Optional integer version
    required this.residentId,
    required this.residentName,
    required this.lotNumber,
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.status,
    required this.dateDue,
    this.datePaid,
    this.proofRef,
    this.proofUrl,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    required this.billingPeriod,
  });

  /// Create from Firestore document
  factory Payment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Handle lotId - support both String and Integer
    String lotIdStr;
    int? lotIdInteger;

    final lotIdData = data['lotId'];
    if (lotIdData is int) {
      lotIdInteger = lotIdData;
      lotIdStr = 'master_$lotIdData'; // Convert int to string for compatibility
    } else {
      lotIdStr = lotIdData?.toString() ?? '';
      // Try to extract integer if it's in format "master_1001"
      if (lotIdStr.startsWith('master_')) {
        lotIdInteger = int.tryParse(lotIdStr.replaceAll('master_', ''));
      }
    }

    return Payment(
      id: doc.id,
      lotId: lotIdStr,
      lotIdInt: lotIdInteger,
      residentId:
          data['residentId'] ?? data['userId'] ?? '', // Support both names
      residentName: data['residentName'] ?? '',
      lotNumber: data['lotNumber'] ?? '',
      categoryId: data['categoryId'] ?? '',
      categoryName: data['categoryName'] ?? '',
      amount: (data['amount'] ?? data['amountOwed'] ?? 0)
          .toDouble(), // Support both names
      status: _parseStatus(data['status']),
      dateDue: (data['dateDue'] as Timestamp?)?.toDate() ?? DateTime.now(),
      datePaid: (data['datePaid'] as Timestamp?)?.toDate(),
      proofRef: data['proofRef'],
      proofUrl: data['proofUrl'],
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      billingPeriod: data['billingPeriod'] ?? '',
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      // Store lotId as integer if available, otherwise as string
      'lotId': lotIdInt ?? lotId,

      // Store both field names for compatibility
      'residentId': residentId,
      'userId': residentId, // NEW: Also store as userId

      'residentName': residentName,
      'lotNumber': lotNumber,
      'categoryId': categoryId,
      'categoryName': categoryName,

      // Store amount with both names for compatibility
      'amount': amount,
      'amountOwed': amount, // NEW: Also store as amountOwed

      'status': status.name,
      'dateDue': Timestamp.fromDate(dateDue),
      'datePaid': datePaid != null ? Timestamp.fromDate(datePaid!) : null,
      'proofRef': proofRef,
      'proofUrl': proofUrl,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'billingPeriod': billingPeriod,
    };
  }

  /// Parse status string to enum
  static PaymentStatus _parseStatus(dynamic status) {
    if (status == null) return PaymentStatus.owed;

    switch (status.toString().toUpperCase()) {
      case 'OWED':
        return PaymentStatus.owed;
      case 'PENDING_REVIEW':
      case 'PENDING':
        return PaymentStatus.pendingReview;
      case 'PAID':
        return PaymentStatus.paid;
      case 'OVERDUE':
        return PaymentStatus.overdue;
      default:
        return PaymentStatus.owed;
    }
  }

  // ============================================================
  // GETTERS - For new schema field names
  // ============================================================

  /// Get userId (new schema name for residentId)
  String get userId => residentId;

  /// Get amountOwed (new schema name for amount)
  double get amountOwed => amount;

  /// Get lot ID as integer (preferred for new schema)
  int? get lotIdAsInt => lotIdInt;

  // ============================================================
  // DISPLAY HELPERS - All existing functionality preserved
  // ============================================================

  /// Format amount as currency
  String get formattedAmount => '₱${amount.toStringAsFixed(2)}';

  /// Check if payment is overdue
  bool get isOverdue =>
      status == PaymentStatus.owed && DateTime.now().isAfter(dateDue);

  /// Get status color
  String get statusColor {
    switch (status) {
      case PaymentStatus.paid:
        return '#10B981'; // Green
      case PaymentStatus.pendingReview:
        return '#F59E0B'; // Orange
      case PaymentStatus.owed:
        return '#6B7280'; // Gray
      case PaymentStatus.overdue:
        return '#EF4444'; // Red
    }
  }

  /// Get status text
  String get statusText {
    switch (status) {
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.pendingReview:
        return 'Pending Review';
      case PaymentStatus.owed:
        return 'Owed';
      case PaymentStatus.overdue:
        return 'Overdue';
    }
  }

  /// Get days until due (negative if overdue)
  int get daysUntilDue => dateDue.difference(DateTime.now()).inDays;

  /// Format due date
  String get formattedDueDate {
    final now = DateTime.now();
    final diff = dateDue.difference(now).inDays;

    if (diff < 0) {
      return '${diff.abs()} days overdue';
    } else if (diff == 0) {
      return 'Due today';
    } else if (diff == 1) {
      return 'Due tomorrow';
    } else {
      return 'Due in $diff days';
    }
  }

  /// Copy with method for updates
  Payment copyWith({
    PaymentStatus? status,
    DateTime? datePaid,
    String? proofRef,
    String? proofUrl,
    String? notes,
    DateTime? updatedAt,
  }) {
    return Payment(
      id: id,
      lotId: lotId,
      lotIdInt: lotIdInt,
      residentId: residentId,
      residentName: residentName,
      lotNumber: lotNumber,
      categoryId: categoryId,
      categoryName: categoryName,
      amount: amount,
      status: status ?? this.status,
      dateDue: dateDue,
      datePaid: datePaid ?? this.datePaid,
      proofRef: proofRef ?? this.proofRef,
      proofUrl: proofUrl ?? this.proofUrl,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      billingPeriod: billingPeriod,
    );
  }
}

/// Payment Status Enum
enum PaymentStatus {
  owed, // Bill generated, not yet paid
  pendingReview, // Payment proof submitted, awaiting admin verification
  paid, // Payment verified and approved
  overdue, // Past due date and still owed
}

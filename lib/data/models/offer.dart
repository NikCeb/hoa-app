import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents the state of a helper's offer
///
/// Flow: pending → accepted OR rejected
/// Only ONE offer can be accepted per request
enum OfferStatus {
  pending, // Waiting for requester's decision
  accepted, // Requester chose this helper
  rejected, // Requester declined this offer
}

/// Represents a helper's offer to assist with a request
///
/// Relationship: Many offers → One request
/// Example: Request "Need dog walker" might have 5 offers
///
/// Data Flow:
/// 1. Helper clicks "Offer Help" → Create Offer
/// 2. Store in Firestore → offers collection
/// 3. Requester sees list → Query by requestId
/// 4. Requester accepts → Update status to 'accepted'
class Offer {
  final String id; // Firestore document ID
  final String requestId; // Links to help_requests.id
  final String helperId; // User UID of person offering help
  final String helperName; // Display name for quick access
  final String? message; // Optional message from helper
  final OfferStatus status; // Current state (pending/accepted/rejected)
  final DateTime offeredAt; // When offer was made
  final DateTime?
      respondedAt; // When requester accepted/rejected (null if pending)

  Offer({
    required this.id,
    required this.requestId,
    required this.helperId,
    required this.helperName,
    this.message,
    required this.status,
    required this.offeredAt,
    this.respondedAt,
  });

  /// Creates an Offer object from Firestore DocumentSnapshot
  ///
  /// Example Firestore data:
  /// {
  ///   'requestId': 'req123',
  ///   'helperId': 'user456',
  ///   'status': 'pending',
  ///   'offeredAt': Timestamp(...)
  /// }
  factory Offer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Offer(
      id: doc.id,
      requestId: data['requestId'] ?? '',
      helperId: data['helperId'] ?? '',
      helperName: data['helperName'] ?? 'Unknown Helper',
      message: data['message'],
      status: _parseStatus(data['status']),

      // Convert Firestore Timestamp → DateTime
      offeredAt: (data['offeredAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      respondedAt: (data['respondedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Converts Offer object to Map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'helperId': helperId,
      'helperName': helperName,
      'message': message,
      'status': status.name, // Enum → String

      // DateTime → Firestore Timestamp
      'offeredAt': Timestamp.fromDate(offeredAt),
      'respondedAt':
          respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
    };
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  /// Quick status checks
  bool get isPending => status == OfferStatus.pending;
  bool get isAccepted => status == OfferStatus.accepted;
  bool get isRejected => status == OfferStatus.rejected;

  /// Returns human-readable time since offer was made
  ///
  /// Examples:
  /// - "Just now"
  /// - "18 hours ago"
  /// - "3 days ago"
  String get timeAgo {
    final difference = DateTime.now().difference(offeredAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  /// Returns badge color based on status
  /// Used for UI display (green = accepted, red = rejected, etc.)
  String get statusColor {
    switch (status) {
      case OfferStatus.accepted:
        return '#10B981'; // Green
      case OfferStatus.rejected:
        return '#EF4444'; // Red
      case OfferStatus.pending:
        return '#F59E0B'; // Yellow
    }
  }

  /// Returns display-friendly status text
  String get statusText {
    switch (status) {
      case OfferStatus.accepted:
        return 'accepted';
      case OfferStatus.rejected:
        return 'rejected';
      case OfferStatus.pending:
        return 'pending';
    }
  }

  // ============================================================
  // PARSING METHODS
  // ============================================================

  /// Converts string from Firestore to OfferStatus enum
  /// Falls back to 'pending' if invalid
  static OfferStatus _parseStatus(dynamic status) {
    if (status is String) {
      switch (status.toLowerCase()) {
        case 'accepted':
          return OfferStatus.accepted;
        case 'rejected':
          return OfferStatus.rejected;
        default:
          return OfferStatus.pending;
      }
    }
    return OfferStatus.pending;
  }

  /// Creates a copy with modified fields
  ///
  /// Why this is useful:
  /// When requester accepts an offer:
  ///
  /// final updatedOffer = offer.copyWith(
  ///   status: OfferStatus.accepted,
  ///   respondedAt: DateTime.now(),
  /// );
  Offer copyWith({
    String? id,
    String? requestId,
    String? helperId,
    String? helperName,
    String? message,
    OfferStatus? status,
    DateTime? offeredAt,
    DateTime? respondedAt,
  }) {
    return Offer(
      id: id ?? this.id,
      requestId: requestId ?? this.requestId,
      helperId: helperId ?? this.helperId,
      helperName: helperName ?? this.helperName,
      message: message ?? this.message,
      status: status ?? this.status,
      offeredAt: offeredAt ?? this.offeredAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }
}

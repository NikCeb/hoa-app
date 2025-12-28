import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents the different states a help request can be in
/// This controls what actions are available and how the request displays
enum RequestStatus {
  open, // Just posted, accepting offers
  inProgress, // Helper accepted, work in progress
  completed, // Work finished successfully
  cancelled, // Requester cancelled before completion
}

/// Categorizes the type of help being requested
/// Used for filtering and display organization
enum RequestCategory {
  handyman, // Repairs, assembly, fixing things
  petCare, // Walking, sitting, feeding pets
  errand, // Shopping, deliveries, pickups
  emergency, // Urgent help (car battery, lockout)
  transportation, // Rides, moving items
  other, // Miscellaneous requests
}

/// Core model representing a help request in the HOA system
///
/// Data Flow:
/// 1. User creates request → Firestore via toMap()
/// 2. Firestore stores document → Retrieve via fromFirestore()
/// 3. Display in UI → Access via properties
class HelpRequest {
  final String id; // Firestore document ID (auto-generated)
  final String requesterId; // User UID who posted the request
  final String requesterName; // Display name for quick access
  final String title; // Brief description (e.g., "Need dog walker")
  final String description; // Full details about the request
  final RequestCategory category; // What type of help
  final RequestStatus status; // Current state of request
  final int helpersNeeded; // How many people can help (usually 1)
  final double distance; // Distance from helper (in meters, 0 if same HOA)
  final DateTime postedAt; // When request was created
  final DateTime? completedAt; // When work was finished (null if not completed)
  final String?
      acceptedHelperId; // User UID of accepted helper (null if no one accepted)
  final String? acceptedHelperName; // Display name of accepted helper
  final int tulongCount; // Points/credits for the requester
  final String location; // Location description
  final int offerCount; // Number of offers received

  HelpRequest({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    this.helpersNeeded = 1,
    this.distance = 0,
    required this.postedAt,
    this.completedAt,
    this.acceptedHelperId,
    this.acceptedHelperName,
    this.tulongCount = 0,
    this.location = '',
    this.offerCount = 0,
  });

  /// Creates a HelpRequest object from a Firestore DocumentSnapshot
  ///
  /// Why factory constructor?
  /// - Can validate/transform data before creating object
  /// - Can handle missing fields gracefully
  /// - Centralizes parsing logic
  ///
  /// Example Firestore data:
  /// {
  ///   'requesterId': 'user123',
  ///   'title': 'Need help',
  ///   'status': 'open',
  ///   'postedAt': Timestamp(...)
  /// }
  factory HelpRequest.fromFirestore(DocumentSnapshot doc) {
    // Cast the document data to a Map for easy access
    final data = doc.data() as Map<String, dynamic>;

    return HelpRequest(
      id: doc.id, // Document ID from Firestore
      requesterId: data['requesterId'] ?? '',
      requesterName: data['requesterName'] ?? 'Unknown',
      title: data['title'] ?? 'Untitled Request',
      description: data['description'] ?? '',
      category: _parseCategory(data['category']),
      status: _parseStatus(data['status']),
      helpersNeeded: data['helpersNeeded'] ?? 1,
      distance: (data['distance'] ?? 0).toDouble(),

      // Convert Firestore Timestamp to DateTime
      // Timestamp is Firestore's native date type
      postedAt: (data['postedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),

      acceptedHelperId: data['acceptedHelperId'],
      acceptedHelperName: data['acceptedHelperName'],

      // New fields
      tulongCount: data['tulongCount'] ?? 0,
      location: data['location'] ?? '',
      offerCount: data['offerCount'] ?? 0,
    );
  }

  /// Converts HelpRequest object to Map for Firestore storage
  ///
  /// Why we need this:
  /// - Firestore stores data as Map<String, dynamic>
  /// - We need to convert our object back to this format
  /// - DateTime → Timestamp conversion happens here
  Map<String, dynamic> toMap() {
    return {
      'requesterId': requesterId,
      'requesterName': requesterName,
      'title': title,
      'description': description,
      'category': category.name, // Enum → String (e.g., 'handyman')
      'status': status.name, // Enum → String (e.g., 'open')
      'helpersNeeded': helpersNeeded,
      'distance': distance,

      // DateTime → Firestore Timestamp
      'postedAt': Timestamp.fromDate(postedAt),
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,

      'acceptedHelperId': acceptedHelperId,
      'acceptedHelperName': acceptedHelperName,

      // New fields
      'tulongCount': tulongCount,
      'location': location,
      'offerCount': offerCount,
    };
  }

  // ============================================================
  // HELPER METHODS - Make UI code cleaner
  // ============================================================

  /// Checks if request is still open for offers
  bool get isOpen => status == RequestStatus.open;

  /// Checks if someone is currently working on it
  bool get isInProgress => status == RequestStatus.inProgress;

  /// Checks if work is complete
  bool get isCompleted => status == RequestStatus.completed;

  /// Checks if request was cancelled
  bool get isCancelled => status == RequestStatus.cancelled;

  /// Returns a human-readable time string
  ///
  /// Examples:
  /// - "Just now" (< 1 minute)
  /// - "5 minutes ago"
  /// - "2 hours ago"
  /// - "3 days ago"
  String get timeAgo {
    final difference = DateTime.now().difference(postedAt);

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

  /// Returns color-coded badge color based on status
  String get statusColor {
    switch (status) {
      case RequestStatus.open:
        return '#10B981'; // Green
      case RequestStatus.inProgress:
        return '#F59E0B'; // Yellow
      case RequestStatus.completed:
        return '#6B7280'; // Gray
      case RequestStatus.cancelled:
        return '#EF4444'; // Red
    }
  }

  /// Returns display-friendly status text
  String get statusText {
    switch (status) {
      case RequestStatus.open:
        return 'Open';
      case RequestStatus.inProgress:
        return 'In Progress';
      case RequestStatus.completed:
        return 'Completed';
      case RequestStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Returns category display text
  String get categoryText {
    switch (category) {
      case RequestCategory.handyman:
        return 'Handyman';
      case RequestCategory.petCare:
        return 'Pet Care';
      case RequestCategory.errand:
        return 'Errand';
      case RequestCategory.emergency:
        return 'Emergency';
      case RequestCategory.transportation:
        return 'Transportation';
      case RequestCategory.other:
        return 'Other';
    }
  }

  // ============================================================
  // COMPATIBILITY ALIASES - For new code that uses different names
  // ============================================================

  /// Alias for requesterName (for compatibility with new code)
  String get posterName => requesterName;

  /// Alias for requesterId (for compatibility with new code)
  String get posterId => requesterId;

  /// Alias for acceptedHelperId (for compatibility with new code)
  String? get acceptedOfferId => acceptedHelperId;

  /// Alias for categoryText (for backward compatibility)
  String get categoryLabel => categoryText;

  /// Alias for categoryText (for new code)
  String get categoryDisplayName => categoryText;

  /// Formats distance as human-readable text
  ///
  /// Examples:
  /// - "0m" (same location)
  /// - "250m" (250 meters)
  /// - "1.5km" (1500 meters)
  String get distanceText {
    if (distance == 0) return '0m';
    if (distance < 1000) {
      return '${distance.toInt()}m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)}km';
    }
  }

  // ============================================================
  // PARSING METHODS - Convert strings to enums safely
  // ============================================================

  /// Converts string from Firestore to RequestCategory enum
  /// Falls back to 'other' if invalid
  static RequestCategory _parseCategory(dynamic category) {
    if (category is String) {
      switch (category.toLowerCase()) {
        case 'handyman':
          return RequestCategory.handyman;
        case 'petcare':
        case 'pet_care':
          return RequestCategory.petCare;
        case 'errand':
          return RequestCategory.errand;
        case 'emergency':
          return RequestCategory.emergency;
        case 'transportation':
          return RequestCategory.transportation;
        default:
          return RequestCategory.other;
      }
    }
    return RequestCategory.other;
  }

  /// Converts string from Firestore to RequestStatus enum
  /// Falls back to 'open' if invalid
  static RequestStatus _parseStatus(dynamic status) {
    if (status is String) {
      switch (status.toLowerCase()) {
        case 'inprogress':
        case 'in_progress':
          return RequestStatus.inProgress;
        case 'completed':
          return RequestStatus.completed;
        case 'cancelled':
          return RequestStatus.cancelled;
        default:
          return RequestStatus.open;
      }
    }
    return RequestStatus.open;
  }

  /// Creates a copy of this request with modified fields
  ///
  /// Why copyWith?
  /// - Objects are immutable (final fields)
  /// - To "update" we create a new object with changes
  /// - Useful for state management
  ///
  /// Example:
  /// final updatedRequest = request.copyWith(status: RequestStatus.completed);
  HelpRequest copyWith({
    String? id,
    String? requesterId,
    String? requesterName,
    String? title,
    String? description,
    RequestCategory? category,
    RequestStatus? status,
    int? helpersNeeded,
    double? distance,
    DateTime? postedAt,
    DateTime? completedAt,
    String? acceptedHelperId,
    String? acceptedHelperName,
    int? tulongCount,
    String? location,
    int? offerCount,
  }) {
    return HelpRequest(
      id: id ?? this.id,
      requesterId: requesterId ?? this.requesterId,
      requesterName: requesterName ?? this.requesterName,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      status: status ?? this.status,
      helpersNeeded: helpersNeeded ?? this.helpersNeeded,
      distance: distance ?? this.distance,
      postedAt: postedAt ?? this.postedAt,
      completedAt: completedAt ?? this.completedAt,
      acceptedHelperId: acceptedHelperId ?? this.acceptedHelperId,
      acceptedHelperName: acceptedHelperName ?? this.acceptedHelperName,
      tulongCount: tulongCount ?? this.tulongCount,
      location: location ?? this.location,
      offerCount: offerCount ?? this.offerCount,
    );
  }
}

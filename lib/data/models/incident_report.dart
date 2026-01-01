import 'package:cloud_firestore/cloud_firestore.dart';

/// Status enum - Updated to match new schema
enum IncidentStatus {
  newReport, // Maps to "NEW"
  underReview, // Maps to "IN_REVIEW"
  resolved, // Maps to "RESOLVED"
  dismissed, // Keep for existing functionality
}

/// Type/category of incident
enum IncidentType {
  vandalism,
  noise,
  parking,
  lighting,
  garbage,
  safety,
  maintenance,
  other,
}

/// Represents an incident report filed by a resident
///
/// SCHEMA COMPATIBLE: Matches new schema + keeps useful extra fields
/// - KEPT: title (better UX!)
/// - Removed: resolvedBy
/// - Updated: status values to match new schema
class IncidentReport {
  final String id; // reportId in new schema
  final String reporterId;
  final String reporterName;

  // KEPT: Title field for better UX!
  final String title;

  final String description;
  final IncidentType type; // Keep enum for app logic
  final IncidentStatus status;
  final String location;

  // PROOF HANDLING - Backward compatible
  final String? proofRef; // Can be URL or storage path
  final String? proofUrl; // Keep for backward compatibility

  final DateTime reportedAt;
  final DateTime? resolvedAt;
  final String? adminNotes;

  // REMOVED: resolvedBy field (not in new schema)

  // OPTIONAL FIELDS - Keep for existing functionality
  final String? phase; // User's phase

  IncidentReport({
    required this.id,
    required this.reporterId,
    required this.reporterName,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.location,
    this.proofRef,
    this.proofUrl,
    required this.reportedAt,
    this.resolvedAt,
    this.adminNotes,
    this.phase,
  });

  /// Create from Firestore document
  factory IncidentReport.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return IncidentReport(
      id: doc.id,
      reporterId: data['reporterId'] ?? '',
      reporterName: data['reporterName'] ?? 'Anonymous',
      title: data['title'] ?? '', // Read title if it exists
      description: data['description'] ?? '',
      type: _parseType(data['type'] ?? data['category']), // Support both names
      status: _parseStatus(data['status']),
      location: data['location'] ?? '',
      proofRef: data['proofRef'],
      proofUrl: data['proofUrl'],
      reportedAt: (data['reportedAt'] ?? data['timeSubmitted'] as Timestamp?)
              ?.toDate() ??
          DateTime.now(),
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
      adminNotes: data['adminNotes'],
      phase: data['phase'],
    );
  }

  /// Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'reporterId': reporterId,
      'reporterName': reporterName,
      'title': title, // Save title (optional field - schema allows this!)
      'description': description,

      // Save with both names for compatibility
      'type': type.name,
      'category': type.name, // NEW: Also save as category

      'status': _statusToFirestore(status), // Convert to new schema format
      'location': location,
      'proofRef': proofRef ?? proofUrl, // Prefer proofRef
      'proofUrl': proofUrl, // Keep for backward compatibility

      // Save with both names for compatibility
      'reportedAt': Timestamp.fromDate(reportedAt),
      'timeSubmitted':
          Timestamp.fromDate(reportedAt), // NEW: Also save as timeSubmitted

      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'adminNotes': adminNotes,
      'phase': phase,
    };
  }

  // ============================================================
  // GETTERS - For new schema field names
  // ============================================================

  /// Get reportId (new schema name for id)
  String get reportId => id;

  /// Get category (new schema name for type)
  String get category => type.name;

  /// Get timeSubmitted (new schema name for reportedAt)
  DateTime get timeSubmitted => reportedAt;

  /// Get actual image URL for display
  /// Tries proofRef first (new schema), falls back to proofUrl
  String? get imageUrl => proofRef ?? proofUrl;

  // ============================================================
  // HELPER GETTERS
  // ============================================================

  bool get isNew => status == IncidentStatus.newReport;
  bool get isUnderReview => status == IncidentStatus.underReview;
  bool get isResolved => status == IncidentStatus.resolved;
  bool get isDismissed => status == IncidentStatus.dismissed;

  String get typeDisplayName {
    switch (type) {
      case IncidentType.vandalism:
        return 'Vandalism';
      case IncidentType.noise:
        return 'Noise Complaint';
      case IncidentType.parking:
        return 'Parking Issue';
      case IncidentType.lighting:
        return 'Street Lighting';
      case IncidentType.garbage:
        return 'Garbage/Waste';
      case IncidentType.safety:
        return 'Safety Concern';
      case IncidentType.maintenance:
        return 'Maintenance';
      case IncidentType.other:
        return 'Other';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case IncidentStatus.newReport:
        return 'New';
      case IncidentStatus.underReview:
        return 'Under Review';
      case IncidentStatus.resolved:
        return 'Resolved';
      case IncidentStatus.dismissed:
        return 'Dismissed';
    }
  }

  String get statusColor {
    switch (status) {
      case IncidentStatus.newReport:
        return '#EF4444'; // Red
      case IncidentStatus.underReview:
        return '#F59E0B'; // Orange
      case IncidentStatus.resolved:
        return '#10B981'; // Green
      case IncidentStatus.dismissed:
        return '#6B7280'; // Gray
    }
  }

  String get timeAgo {
    final difference = DateTime.now().difference(reportedAt);

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

  // ============================================================
  // PARSING HELPERS
  // ============================================================

  static IncidentType _parseType(dynamic type) {
    if (type is String) {
      switch (type.toLowerCase()) {
        case 'vandalism':
          return IncidentType.vandalism;
        case 'noise':
          return IncidentType.noise;
        case 'parking':
          return IncidentType.parking;
        case 'lighting':
          return IncidentType.lighting;
        case 'garbage':
          return IncidentType.garbage;
        case 'safety':
          return IncidentType.safety;
        case 'maintenance':
          return IncidentType.maintenance;
        default:
          return IncidentType.other;
      }
    }
    return IncidentType.other;
  }

  static IncidentStatus _parseStatus(dynamic status) {
    if (status is String) {
      final statusStr = status.toUpperCase();

      // Support new schema status values
      switch (statusStr) {
        case 'NEW':
        case 'NEWREPORT':
          return IncidentStatus.newReport;
        case 'IN_REVIEW':
        case 'UNDERREVIEW':
        case 'UNDER_REVIEW':
          return IncidentStatus.underReview;
        case 'RESOLVED':
          return IncidentStatus.resolved;
        case 'DISMISSED':
          return IncidentStatus.dismissed;
        default:
          return IncidentStatus.newReport;
      }
    }
    return IncidentStatus.newReport;
  }

  /// Convert status enum to new schema format
  static String _statusToFirestore(IncidentStatus status) {
    switch (status) {
      case IncidentStatus.newReport:
        return 'NEW';
      case IncidentStatus.underReview:
        return 'IN_REVIEW';
      case IncidentStatus.resolved:
        return 'RESOLVED';
      case IncidentStatus.dismissed:
        return 'DISMISSED';
    }
  }

  /// Copy with method
  IncidentReport copyWith({
    String? id,
    String? reporterId,
    String? reporterName,
    String? title,
    String? description,
    IncidentType? type,
    IncidentStatus? status,
    String? location,
    String? proofRef,
    String? proofUrl,
    DateTime? reportedAt,
    DateTime? resolvedAt,
    String? adminNotes,
    String? phase,
  }) {
    return IncidentReport(
      id: id ?? this.id,
      reporterId: reporterId ?? this.reporterId,
      reporterName: reporterName ?? this.reporterName,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      location: location ?? this.location,
      proofRef: proofRef ?? this.proofRef,
      proofUrl: proofUrl ?? this.proofUrl,
      reportedAt: reportedAt ?? this.reportedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      adminNotes: adminNotes ?? this.adminNotes,
      phase: phase ?? this.phase,
    );
  }
}

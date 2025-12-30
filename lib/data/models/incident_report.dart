import 'package:cloud_firestore/cloud_firestore.dart';

enum IncidentStatus {
  newReport,
  underReview,
  resolved,
  dismissed,
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
/// Data Flow:
/// 1. User creates report → Firestore + Storage
/// 2. Admin views → Updates status
/// 3. Stream updates UI automatically
class IncidentReport {
  final String id;
  final String reporterId;
  final String reporterName;
  final String title;
  final String description;
  final IncidentType type;
  final IncidentStatus status;
  final String location;
  final String? proofUrl; // Photo from Firebase Storage
  final String? proofRef; // Storage reference path
  final DateTime reportedAt;
  final DateTime? resolvedAt;
  final String? adminNotes; // Admin can add notes
  final String? resolvedBy; // Admin UID who resolved it

  IncidentReport({
    required this.id,
    required this.reporterId,
    required this.reporterName,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.location,
    this.proofUrl,
    this.proofRef,
    required this.reportedAt,
    this.resolvedAt,
    this.adminNotes,
    this.resolvedBy,
  });

  /// Create from Firestore document
  factory IncidentReport.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return IncidentReport(
      id: doc.id,
      reporterId: data['reporterId'] ?? '',
      reporterName: data['reporterName'] ?? 'Anonymous',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: _parseType(data['type']),
      status: _parseStatus(data['status']),
      location: data['location'] ?? '',
      proofUrl: data['proofUrl'],
      proofRef: data['proofRef'],
      reportedAt:
          (data['reportedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
      adminNotes: data['adminNotes'],
      resolvedBy: data['resolvedBy'],
    );
  }

  /// Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'reporterId': reporterId,
      'reporterName': reporterName,
      'title': title,
      'description': description,
      'type': type.name,
      'status': status.name,
      'location': location,
      'proofUrl': proofUrl,
      'proofRef': proofRef,
      'reportedAt': Timestamp.fromDate(reportedAt),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'adminNotes': adminNotes,
      'resolvedBy': resolvedBy,
    };
  }

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
      switch (status.toLowerCase()) {
        case 'newreport':
        case 'new':
          return IncidentStatus.newReport;
        case 'underreview':
        case 'under_review':
          return IncidentStatus.underReview;
        case 'resolved':
          return IncidentStatus.resolved;
        case 'dismissed':
          return IncidentStatus.dismissed;
        default:
          return IncidentStatus.newReport;
      }
    }
    return IncidentStatus.newReport;
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
    String? proofUrl,
    String? proofRef,
    DateTime? reportedAt,
    DateTime? resolvedAt,
    String? adminNotes,
    String? resolvedBy,
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
      proofUrl: proofUrl ?? this.proofUrl,
      proofRef: proofRef ?? this.proofRef,
      reportedAt: reportedAt ?? this.reportedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      adminNotes: adminNotes ?? this.adminNotes,
      resolvedBy: resolvedBy ?? this.resolvedBy,
    );
  }
}

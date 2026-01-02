import 'package:cloud_firestore/cloud_firestore.dart';

/// Status enum
enum IncidentStatus {
  newReport, // Maps to "NEW"
  underReview, // Maps to "IN_REVIEW"
  resolved, // Maps to "RESOLVED"
  dismissed, // Optional
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

/// Incident Report Model - Simplified
class IncidentReport {
  final String id;
  final String reporterId;
  final String reporterName;
  final String title;
  final String description;
  final IncidentType type;
  final IncidentStatus status;
  final String location;
  final String? phase;
  final DateTime reportedAt; // When report was submitted
  final DateTime? resolvedAt;
  final String? adminNotes;
  final String? proofRef; // Photo URL (optional)

  IncidentReport({
    required this.id,
    required this.reporterId,
    required this.reporterName,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.location,
    this.phase,
    required this.reportedAt,
    this.resolvedAt,
    this.adminNotes,
    this.proofRef,
  });

  /// Create from Firestore document
  factory IncidentReport.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return IncidentReport(
      id: doc.id,
      reporterId: data['userId'] ?? data['reporterId'] ?? '',
      reporterName: data['reporterName'] ?? 'Unknown',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: _parseType(data['category'] ?? data['type']),
      status: _parseStatus(data['status']),
      location: data['location'] ?? '',
      phase: data['phase'],
      reportedAt: (data['timeSubmitted'] as Timestamp?)?.toDate() ??
          (data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
      adminNotes: data['adminNotes'],
      proofRef: data['proofRef'] ?? data['proofUrl'],
    );
  }

  /// Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': reporterId,
      'reporterId': reporterId,
      'reporterName': reporterName,
      'title': title,
      'description': description,
      'category': type.name,
      'type': type.name,
      'status': statusToFirestore(status),
      'location': location,
      'phase': phase,
      'timeSubmitted': Timestamp.fromDate(reportedAt),
      'createdAt': Timestamp.fromDate(reportedAt),
      'updatedAt': Timestamp.now(),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'adminNotes': adminNotes,
      'proofRef': proofRef,
      'proofUrl': proofRef,
    };
  }

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
      switch (status.toUpperCase()) {
        case 'NEW':
          return IncidentStatus.newReport;
        case 'IN_REVIEW':
        case 'UNDER_REVIEW':
        case 'UNDERREVIEW':
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

  static String statusToFirestore(IncidentStatus status) {
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

  // Getters
  bool get isNew => status == IncidentStatus.newReport;
  bool get isUnderReview => status == IncidentStatus.underReview;
  bool get isResolved => status == IncidentStatus.resolved;
  bool get isDismissed => status == IncidentStatus.dismissed;

  String? get proofUrl => proofRef;
  String? get imageUrl => proofRef;

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

  IncidentReport copyWith({
    String? id,
    String? reporterId,
    String? reporterName,
    String? title,
    String? description,
    IncidentType? type,
    IncidentStatus? status,
    String? location,
    String? phase,
    DateTime? reportedAt,
    DateTime? resolvedAt,
    String? adminNotes,
    String? proofRef,
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
      phase: phase ?? this.phase,
      reportedAt: reportedAt ?? this.reportedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      adminNotes: adminNotes ?? this.adminNotes,
      proofRef: proofRef ?? this.proofRef,
    );
  }
}

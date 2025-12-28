import 'package:cloud_firestore/cloud_firestore.dart';

enum IncidentType {
  vandalism,
  noise,
  parking,
  maintenance,
  security,
  other,
}

enum ReportStatus {
  newReport,
  underReview,
  resolved,
  rejected,
}

class IncidentReport {
  final String id;
  final String title;
  final String description;
  final String reporterId;
  final String reporterName;
  final IncidentType type;
  final ReportStatus status;
  final String location;
  final String? proofRef; // Firebase Storage reference to photo/video
  final DateTime reportedAt;
  final DateTime? resolvedAt;
  final String? adminNotes;
  final String? resolvedBy; // Admin user ID

  IncidentReport({
    required this.id,
    required this.title,
    required this.description,
    required this.reporterId,
    required this.reporterName,
    required this.type,
    required this.status,
    required this.location,
    this.proofRef,
    required this.reportedAt,
    this.resolvedAt,
    this.adminNotes,
    this.resolvedBy,
  });

  // Factory constructor from Firestore
  factory IncidentReport.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return IncidentReport(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      reporterId: data['reporterId'] ?? '',
      reporterName: data['reporterName'] ?? '',
      type: _parseType(data['type']),
      status: _parseStatus(data['status']),
      location: data['location'] ?? '',
      proofRef: data['proofRef'],
      reportedAt:
          (data['reportedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
      adminNotes: data['adminNotes'],
      resolvedBy: data['resolvedBy'],
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'reporterId': reporterId,
      'reporterName': reporterName,
      'type': type.name,
      'status': status.name,
      'location': location,
      'proofRef': proofRef,
      'reportedAt': Timestamp.fromDate(reportedAt),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'adminNotes': adminNotes,
      'resolvedBy': resolvedBy,
    };
  }

  // Helper methods
  String get typeLabel {
    switch (type) {
      case IncidentType.vandalism:
        return 'Vandalism';
      case IncidentType.noise:
        return 'Noise Complaint';
      case IncidentType.parking:
        return 'Parking Issue';
      case IncidentType.maintenance:
        return 'Maintenance';
      case IncidentType.security:
        return 'Security Concern';
      case IncidentType.other:
        return 'Other';
    }
  }

  String get statusLabel {
    switch (status) {
      case ReportStatus.newReport:
        return 'New';
      case ReportStatus.underReview:
        return 'Under Review';
      case ReportStatus.resolved:
        return 'Resolved';
      case ReportStatus.rejected:
        return 'Rejected';
    }
  }

  String get timeAgo {
    final difference = DateTime.now().difference(reportedAt);
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  bool get isNew => status == ReportStatus.newReport;
  bool get isResolved => status == ReportStatus.resolved;
  bool get hasProof => proofRef != null && proofRef!.isNotEmpty;

  // Parse enums
  static IncidentType _parseType(dynamic type) {
    if (type is String) {
      switch (type) {
        case 'vandalism':
          return IncidentType.vandalism;
        case 'noise':
          return IncidentType.noise;
        case 'parking':
          return IncidentType.parking;
        case 'maintenance':
          return IncidentType.maintenance;
        case 'security':
          return IncidentType.security;
        default:
          return IncidentType.other;
      }
    }
    return IncidentType.other;
  }

  static ReportStatus _parseStatus(dynamic status) {
    if (status is String) {
      switch (status) {
        case 'newReport':
          return ReportStatus.newReport;
        case 'underReview':
          return ReportStatus.underReview;
        case 'resolved':
          return ReportStatus.resolved;
        case 'rejected':
          return ReportStatus.rejected;
        default:
          return ReportStatus.newReport;
      }
    }
    return ReportStatus.newReport;
  }

  // Copy with method
  IncidentReport copyWith({
    String? id,
    String? title,
    String? description,
    String? reporterId,
    String? reporterName,
    IncidentType? type,
    ReportStatus? status,
    String? location,
    String? proofRef,
    DateTime? reportedAt,
    DateTime? resolvedAt,
    String? adminNotes,
    String? resolvedBy,
  }) {
    return IncidentReport(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      reporterId: reporterId ?? this.reporterId,
      reporterName: reporterName ?? this.reporterName,
      type: type ?? this.type,
      status: status ?? this.status,
      location: location ?? this.location,
      proofRef: proofRef ?? this.proofRef,
      reportedAt: reportedAt ?? this.reportedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      adminNotes: adminNotes ?? this.adminNotes,
      resolvedBy: resolvedBy ?? this.resolvedBy,
    );
  }
}

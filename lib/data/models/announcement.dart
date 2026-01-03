import 'package:cloud_firestore/cloud_firestore.dart';

enum AnnouncementType {
  general,
  urgent,
  event,
  maintenance,
}

enum TargetAudience {
  all,
  residents,
  owners,
  tenants,
}

class Announcement {
  final String id;
  final String adminId;
  final String adminName;
  final String title;
  final String content;
  final AnnouncementType type;
  final bool isCritical;
  final TargetAudience targetAudience;
  final DateTime timePosted;
  final DateTime? expiresAt;
  final bool isActive;
  final String? attachmentUrl;
  final int viewCount;
  final List<String> tags;

  Announcement({
    required this.id,
    required this.adminId,
    required this.adminName,
    required this.title,
    required this.content,
    required this.type,
    required this.isCritical,
    required this.targetAudience,
    required this.timePosted,
    this.expiresAt,
    required this.isActive,
    this.attachmentUrl,
    required this.viewCount,
    required this.tags,
  });

  factory Announcement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Announcement(
      id: doc.id,
      adminId: data['adminId'] ?? '',
      adminName: data['adminName'] ?? 'Admin',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      type: _typeFromString(data['type'] as String?),
      isCritical: data['isCritical'] ?? false,
      targetAudience: _audienceFromString(data['targetAudience'] as String?),
      timePosted:
          (data['timePosted'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? true,
      attachmentUrl: data['attachmentUrl'] as String?,
      viewCount: data['viewCount'] ?? 0,
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'adminId': adminId,
      'adminName': adminName,
      'title': title,
      'content': content,
      'type': type.name.toUpperCase(),
      'isCritical': isCritical,
      'targetAudience': targetAudience.name.toUpperCase(),
      'timePosted': Timestamp.fromDate(timePosted),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'isActive': isActive,
      'attachmentUrl': attachmentUrl,
      'viewCount': viewCount,
      'tags': tags,
    };
  }

  static AnnouncementType _typeFromString(String? type) {
    switch (type?.toUpperCase()) {
      case 'URGENT':
        return AnnouncementType.urgent;
      case 'EVENT':
        return AnnouncementType.event;
      case 'MAINTENANCE':
        return AnnouncementType.maintenance;
      default:
        return AnnouncementType.general;
    }
  }

  static TargetAudience _audienceFromString(String? audience) {
    switch (audience?.toUpperCase()) {
      case 'RESIDENTS':
        return TargetAudience.residents;
      case 'OWNERS':
        return TargetAudience.owners;
      case 'TENANTS':
        return TargetAudience.tenants;
      default:
        return TargetAudience.all;
    }
  }

  // Getters
  String get typeDisplayName {
    switch (type) {
      case AnnouncementType.general:
        return 'General';
      case AnnouncementType.urgent:
        return 'Urgent';
      case AnnouncementType.event:
        return 'Event';
      case AnnouncementType.maintenance:
        return 'Maintenance';
    }
  }

  String get typeIcon {
    switch (type) {
      case AnnouncementType.general:
        return '📢';
      case AnnouncementType.urgent:
        return '🚨';
      case AnnouncementType.event:
        return '📅';
      case AnnouncementType.maintenance:
        return '🔧';
    }
  }

  String get audienceDisplayName {
    switch (targetAudience) {
      case TargetAudience.all:
        return 'Everyone';
      case TargetAudience.residents:
        return 'Residents';
      case TargetAudience.owners:
        return 'Owners';
      case TargetAudience.tenants:
        return 'Tenants';
    }
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get isVisible {
    return isActive && !isExpired;
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timePosted);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${(difference.inDays / 365).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}

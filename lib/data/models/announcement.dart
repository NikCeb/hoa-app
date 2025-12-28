import 'package:cloud_firestore/cloud_firestore.dart';

class Announcement {
  final String id;
  final String title;
  final String content;
  final String adminId;
  final String adminName;
  final bool isCritical; // If true, triggers push notification
  final DateTime publishedAt;
  final String? imageUrl;
  final List<String> tags;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.adminId,
    required this.adminName,
    required this.isCritical,
    required this.publishedAt,
    this.imageUrl,
    required this.tags,
  });

  // Factory constructor from Firestore
  factory Announcement.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Announcement(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      adminId: data['adminId'] ?? '',
      adminName: data['adminName'] ?? '',
      isCritical: data['isCritical'] ?? false,
      publishedAt:
          (data['publishedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl: data['imageUrl'],
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'adminId': adminId,
      'adminName': adminName,
      'isCritical': isCritical,
      'publishedAt': Timestamp.fromDate(publishedAt),
      'imageUrl': imageUrl,
      'tags': tags,
    };
  }

  // Helper methods
  String get timeAgo {
    final difference = DateTime.now().difference(publishedAt);
    if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()} week${(difference.inDays / 7).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  // Copy with method
  Announcement copyWith({
    String? id,
    String? title,
    String? content,
    String? adminId,
    String? adminName,
    bool? isCritical,
    DateTime? publishedAt,
    String? imageUrl,
    List<String>? tags,
  }) {
    return Announcement(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      adminId: adminId ?? this.adminId,
      adminName: adminName ?? this.adminName,
      isCritical: isCritical ?? this.isCritical,
      publishedAt: publishedAt ?? this.publishedAt,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
    );
  }
}

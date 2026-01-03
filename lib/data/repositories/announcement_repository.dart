import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/announcement.dart';

class AnnouncementRepository {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  CollectionReference get _announcementsCollection =>
      _firestore.collection('announcements');

  /// Get all active announcements for users (visible, not expired)
  Stream<List<Announcement>> getActiveAnnouncements() {
    return _announcementsCollection
        .where('isActive', isEqualTo: true)
        .orderBy('isCritical', descending: true)
        .orderBy('timePosted', descending: true)
        .snapshots()
        .map((snapshot) {
      final announcements = snapshot.docs
          .map((doc) => Announcement.fromFirestore(doc))
          .where((announcement) => announcement.isVisible)
          .toList();
      return announcements;
    });
  }

  /// Get all announcements for admin (including inactive)
  Stream<List<Announcement>> getAllAnnouncementsForAdmin() {
    return _announcementsCollection
        .orderBy('timePosted', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Announcement.fromFirestore(doc))
          .toList();
    });
  }

  /// Create new announcement
  Future<void> createAnnouncement({
    required String title,
    required String content,
    required AnnouncementType type,
    required bool isCritical,
    required TargetAudience targetAudience,
    DateTime? expiresAt,
    String? attachmentUrl,
    List<String>? tags,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Get admin name
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data();
    final adminName = userData?['firstName'] ?? 'Admin';

    final announcement = Announcement(
      id: '',
      adminId: user.uid,
      adminName: adminName,
      title: title,
      content: content,
      type: type,
      isCritical: isCritical,
      targetAudience: targetAudience,
      timePosted: DateTime.now(),
      expiresAt: expiresAt,
      isActive: true,
      attachmentUrl: attachmentUrl,
      viewCount: 0,
      tags: tags ?? [],
    );

    await _announcementsCollection.add(announcement.toMap());
  }

  /// Update announcement
  Future<void> updateAnnouncement(
    String announcementId,
    Map<String, dynamic> updates,
  ) async {
    await _announcementsCollection.doc(announcementId).update(updates);
  }

  /// Delete announcement
  Future<void> deleteAnnouncement(String announcementId) async {
    await _announcementsCollection.doc(announcementId).delete();
  }

  /// Toggle active status
  Future<void> toggleActiveStatus(String announcementId, bool isActive) async {
    await _announcementsCollection.doc(announcementId).update({
      'isActive': isActive,
    });
  }

  /// Increment view count
  Future<void> incrementViewCount(String announcementId) async {
    await _announcementsCollection.doc(announcementId).update({
      'viewCount': FieldValue.increment(1),
    });
  }

  /// Get announcement statistics
  Future<Map<String, int>> getAnnouncementStats() async {
    final snapshot = await _announcementsCollection.get();

    int total = snapshot.docs.length;
    int active = 0;
    int critical = 0;
    int expired = 0;

    for (var doc in snapshot.docs) {
      final announcement = Announcement.fromFirestore(doc);
      if (announcement.isActive) active++;
      if (announcement.isCritical) critical++;
      if (announcement.isExpired) expired++;
    }

    return {
      'total': total,
      'active': active,
      'critical': critical,
      'expired': expired,
    };
  }
}

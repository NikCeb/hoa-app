import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/incident_report.dart';

/// Repository for incident report operations
///
/// Features:
/// - Create reports with photo upload
/// - Stream of reports for users and admins
/// - Update report status (admin only)
/// - Upload photos to Firebase Storage
class IncidentRepository {
  static final IncidentRepository _instance = IncidentRepository._internal();
  factory IncidentRepository() => _instance;
  IncidentRepository._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference get _reportsCollection =>
      _firestore.collection('incident_reports');

  // ============================================================
  // CREATE OPERATIONS
  // ============================================================

  /// Creates a new incident report
  ///
  /// Flow:
  /// 1. Upload photo to Storage (if provided)
  /// 2. Get download URL
  /// 3. Create report document in Firestore
  /// 4. Return created report
  Future<IncidentReport> createReport({
    required String title,
    required String description,
    required IncidentType type,
    required String location,
    File? proofImage,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Get user info
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() as Map<String, dynamic>;
    final reporterName = '${userData['firstName']} ${userData['lastName']}';

    String? proofUrl;
    String? proofRef;

    // Upload photo if provided
    if (proofImage != null) {
      final uploadResult = await _uploadProofImage(user.uid, proofImage);
      proofUrl = uploadResult['url'];
      proofRef = uploadResult['ref'];
    }

    // Create report object
    final report = IncidentReport(
      id: '',
      reporterId: user.uid,
      reporterName: reporterName,
      title: title,
      description: description,
      type: type,
      status: IncidentStatus.newReport,
      location: location,
      proofUrl: proofUrl,
      proofRef: proofRef,
      reportedAt: DateTime.now(),
    );

    // Save to Firestore
    final docRef = await _reportsCollection.add(report.toMap());

    return report.copyWith(id: docRef.id);
  }

  /// Upload proof image to Firebase Storage
  ///
  /// Path: incident_reports/{userId}/{timestamp}.jpg
  /// Returns: {url: downloadUrl, ref: storagePath}
  Future<Map<String, String>> _uploadProofImage(
    String userId,
    File imageFile,
  ) async {
    try {
      // Create unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '$timestamp.jpg';
      final path = 'incident_reports/$userId/$fileName';

      // Upload to Storage
      final ref = _storage.ref().child(path);
      final uploadTask = await ref.putFile(imageFile);

      // Get download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      return {
        'url': downloadUrl,
        'ref': path,
      };
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // ============================================================
  // READ OPERATIONS
  // ============================================================

  /// Get current user's reports
  ///
  /// Used in: User's "My Reports" screen
  Stream<List<IncidentReport>> getUserReports() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _reportsCollection
        .where('reporterId', isEqualTo: userId)
        .orderBy('reportedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => IncidentReport.fromFirestore(doc))
          .toList();
    });
  }

  /// Get ALL reports (admin only)
  ///
  /// Used in: Admin dashboard
  Stream<List<IncidentReport>> getAllReports() {
    return _reportsCollection
        .orderBy('reportedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => IncidentReport.fromFirestore(doc))
          .toList();
    });
  }

  /// Get reports by status (admin filtering)
  ///
  /// Example: Get only NEW reports
  Stream<List<IncidentReport>> getReportsByStatus(IncidentStatus status) {
    return _reportsCollection
        .where('status', isEqualTo: status.name)
        .orderBy('reportedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => IncidentReport.fromFirestore(doc))
          .toList();
    });
  }

  /// Get single report by ID
  Future<IncidentReport?> getReport(String reportId) async {
    final doc = await _reportsCollection.doc(reportId).get();
    if (!doc.exists) return null;
    return IncidentReport.fromFirestore(doc);
  }

  /// Get report statistics
  ///
  /// Returns: {total, new, underReview, resolved, dismissed}
  Future<Map<String, int>> getReportStats() async {
    final snapshot = await _reportsCollection.get();

    int total = snapshot.docs.length;
    int newCount = 0;
    int underReview = 0;
    int resolved = 0;
    int dismissed = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) continue;

      final status = data['status'] as String?;

      switch (status) {
        case 'newReport':
        case 'new':
          newCount++;
          break;
        case 'underReview':
        case 'under_review':
          underReview++;
          break;
        case 'resolved':
          resolved++;
          break;
        case 'dismissed':
          dismissed++;
          break;
      }
    }

    return {
      'total': total,
      'new': newCount,
      'underReview': underReview,
      'resolved': resolved,
      'dismissed': dismissed,
    };
  }
  // ============================================================
  // UPDATE OPERATIONS (Admin)
  // ============================================================

  /// Update report status (admin action)
  ///
  /// Flow when admin resolves:
  /// 1. Update status to RESOLVED
  /// 2. Set resolvedAt timestamp
  /// 3. Set resolvedBy to admin UID
  /// 4. Optionally add admin notes
  Future<void> updateReportStatus({
    required String reportId,
    required IncidentStatus newStatus,
    String? adminNotes,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final updateData = <String, dynamic>{
      'status': newStatus.name,
    };

    if (newStatus == IncidentStatus.resolved) {
      updateData['resolvedAt'] = Timestamp.now();
      updateData['resolvedBy'] = user.uid;
    }

    if (adminNotes != null && adminNotes.isNotEmpty) {
      updateData['adminNotes'] = adminNotes;
    }

    await _reportsCollection.doc(reportId).update(updateData);
  }

  /// Add admin notes to a report
  Future<void> addAdminNotes({
    required String reportId,
    required String notes,
  }) async {
    await _reportsCollection.doc(reportId).update({
      'adminNotes': notes,
    });
  }

  // ============================================================
  // DELETE OPERATIONS
  // ============================================================

  /// Delete a report and its photo
  ///
  /// 1. Delete photo from Storage
  /// 2. Delete report from Firestore
  Future<void> deleteReport(String reportId) async {
    try {
      // Get report to find photo reference
      final report = await getReport(reportId);

      if (report != null && report.proofRef != null) {
        // Delete photo from Storage
        try {
          await _storage.ref().child(report.proofRef!).delete();
        } catch (e) {
          // Photo might not exist, continue anyway
          print('Error deleting photo: $e');
        }
      }

      // Delete report document
      await _reportsCollection.doc(reportId).delete();
    } catch (e) {
      throw Exception('Failed to delete report: $e');
    }
  }
}

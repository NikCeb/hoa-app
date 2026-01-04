import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/incident_report.dart';

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
  // CREATE
  // ============================================================

  Future<IncidentReport> createReport({
    required String title,
    required String description,
    required IncidentType type,
    required String location,
    File? proofImage,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() as Map<String, dynamic>;
    final reporterName = '${userData['firstName']} ${userData['lastName']}';
    final phase = userData['phase'] ?? '';

    String? proofRef;

    if (proofImage != null) {
      proofRef = await _uploadProofImage(user.uid, proofImage);
    }

    final report = IncidentReport(
      id: '',
      reporterId: user.uid,
      reporterName: reporterName,
      title: title,
      description: description,
      type: type,
      status: IncidentStatus.newReport,
      location: location,
      phase: phase,
      reportedAt: DateTime.now(),
      proofRef: proofRef,
    );

    final docRef = await _reportsCollection.add(report.toMap());

    return report.copyWith(id: docRef.id);
  }

  Future<String> _uploadProofImage(String userId, File imageFile) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '$timestamp.jpg';
      final path = 'incident_reports/$userId/$fileName';

      final ref = _storage.ref().child(path);
      await ref.putFile(imageFile);
      final downloadUrl = await ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // ============================================================
  // READ
  // ============================================================

  Stream<List<IncidentReport>> getUserReports() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _reportsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => IncidentReport.fromFirestore(doc))
          .toList();
    });
  }

  Stream<List<IncidentReport>> getAllReports() {
    return _reportsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => IncidentReport.fromFirestore(doc))
          .toList();
    });
  }

  /// FIX: Client-side filtering - uses model's _parseStatus which handles all variations
  Stream<List<IncidentReport>> getReportsByStatus(IncidentStatus status) {
    return _reportsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => IncidentReport.fromFirestore(doc))
          .where((report) => report.status == status)
          .toList();
    });
  }

  Future<IncidentReport?> getReport(String reportId) async {
    final doc = await _reportsCollection.doc(reportId).get();
    if (!doc.exists) return null;
    return IncidentReport.fromFirestore(doc);
  }

  Future<Map<String, int>> getReportStats() async {
    final snapshot = await _reportsCollection.get();

    int total = snapshot.docs.length;
    int newCount = 0;
    int underReview = 0;
    int resolved = 0;
    int dismissed = 0;

    for (var doc in snapshot.docs) {
      final report = IncidentReport.fromFirestore(doc);

      switch (report.status) {
        case IncidentStatus.newReport:
          newCount++;
          break;
        case IncidentStatus.underReview:
          underReview++;
          break;
        case IncidentStatus.resolved:
          resolved++;
          break;
        case IncidentStatus.dismissed:
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
  // UPDATE
  // ============================================================

  Future<void> updateReportStatus({
    required String reportId,
    required IncidentStatus newStatus,
    String? adminNotes,
  }) async {
    final updateData = <String, dynamic>{
      'status': IncidentReport.statusToFirestore(newStatus),
      'updatedAt': Timestamp.now(),
    };

    if (newStatus == IncidentStatus.resolved) {
      updateData['resolvedAt'] = Timestamp.now();
    }

    if (adminNotes != null && adminNotes.isNotEmpty) {
      updateData['adminNotes'] = adminNotes;
    }

    await _reportsCollection.doc(reportId).update(updateData);
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> deleteReport(String reportId) async {
    try {
      final report = await getReport(reportId);

      if (report != null && report.proofRef != null) {
        try {
          final ref = _storage.refFromURL(report.proofRef!);
          await ref.delete();
        } catch (e) {
          print('Error deleting photo: $e');
        }
      }

      await _reportsCollection.doc(reportId).delete();
    } catch (e) {
      throw Exception('Failed to delete report: $e');
    }
  }
}

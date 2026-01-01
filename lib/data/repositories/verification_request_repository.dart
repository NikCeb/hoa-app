import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/verification_request.dart';

class VerificationRequestRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'verification_requests';

  Future<void> createRequest(VerificationRequest request) async {
    await _firestore.collection(_collection).add(request.toMap());
  }

  Future<void> updateRequestStatus({
    required String requestId,
    required String status,
    String? adminNotes,
  }) async {
    await _firestore.collection(_collection).doc(requestId).update({
      'status': status,
      'adminNotes': adminNotes,
      'reviewedAt': Timestamp.now(),
    });
  }

  Future<void> deleteRequest(String requestId) async {
    await _firestore.collection(_collection).doc(requestId).delete();
  }

  Stream<List<VerificationRequest>> getPendingRequests() {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VerificationRequest.fromFirestore(doc))
            .toList());
  }

  Stream<List<VerificationRequest>> getAllRequests() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VerificationRequest.fromFirestore(doc))
            .toList());
  }

  Future<VerificationRequest?> getRequestByUserId(String userId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return VerificationRequest.fromFirestore(snapshot.docs.first);
    }
    return null;
  }
}

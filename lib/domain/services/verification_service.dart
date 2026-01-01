import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/verification_request.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/verification_request_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/repositories/master_resident_repository.dart';

class VerificationService {
  final _firestore = FirebaseFirestore.instance;
  final _verificationRepo = VerificationRequestRepository();
  final _userRepo = UserRepository();
  final _masterResidentRepo = MasterResidentRepository();

  Future<void> approveVerification({
    required String requestId,
    required String userId,
    required String firstName,
    required String lastName,
    required String lotNumber,
    String? adminNotes,
  }) async {
    final batch = _firestore.batch();

    try {
      final masterResident = await _masterResidentRepo.findAvailableMatch(
        firstName: firstName,
        lastName: lastName,
        lotNumber: lotNumber,
      );

      if (masterResident == null) {
        throw Exception(
          'No available master resident found. Please add to database first.',
        );
      }

      batch.update(
        _firestore.collection('users').doc(userId),
        {
          'isVerified': true,
          'lotId': masterResident.id,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      batch.update(
        _firestore.collection('master_residents').doc(masterResident.id),
        {
          'userId': userId,
          'isAvailable': false,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      batch.update(
        _firestore.collection('verification_requests').doc(requestId),
        {
          'status': 'approved',
          'adminNotes': adminNotes,
          'reviewedAt': FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to approve verification: $e');
    }
  }

  Future<void> rejectVerification({
    required String requestId,
    required String userId,
    String? adminNotes,
  }) async {
    final batch = _firestore.batch();

    try {
      batch.update(
        _firestore.collection('users').doc(userId),
        {
          'isVerified': false,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      batch.update(
        _firestore.collection('verification_requests').doc(requestId),
        {
          'status': 'rejected',
          'adminNotes': adminNotes ?? 'Verification rejected by admin',
          'reviewedAt': FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to reject verification: $e');
    }
  }

  Future<void> deleteUserAndRequest({
    required String requestId,
    required String userId,
  }) async {
    final batch = _firestore.batch();

    try {
      batch.delete(_firestore.collection('users').doc(userId));
      batch.delete(
          _firestore.collection('verification_requests').doc(requestId));

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  Stream<List<VerificationRequest>> getPendingRequests() {
    return _verificationRepo.getPendingRequests();
  }

  Stream<List<VerificationRequest>> getAllRequests() {
    return _verificationRepo.getAllRequests();
  }
}

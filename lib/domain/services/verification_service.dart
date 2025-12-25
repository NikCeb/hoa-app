import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/master_resident.dart';
import '../../data/models/user_model.dart';

class VerificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Verify user against master resident list
  Future<VerificationResult> verifyUser(UserModel user) async {
    try {
      // Query master_residents collection for a match
      QuerySnapshot querySnapshot = await _firestore
          .collection('master_residents')
          .where('firstName', isEqualTo: user.firstName.toLowerCase().trim())
          .where('lastName', isEqualTo: user.lastName.toLowerCase().trim())
          .where('fullAddress',
              isEqualTo: user.fullAddress.toLowerCase().trim())
          .get();

      if (querySnapshot.docs.isEmpty) {
        // No match found - add to verification queue
        await _addToVerificationQueue(user);
        return VerificationResult(
          isAutoApproved: false,
          message: 'No exact match found. Added to manual verification queue.',
        );
      }

      // Match found - auto approve
      MasterResident matchedResident =
          MasterResident.fromFirestore(querySnapshot.docs.first);

      // Check if lot is already assigned to another user
      if (matchedResident.userId != null &&
          matchedResident.userId != user.uid) {
        await _addToVerificationQueue(user,
            reason: 'Lot already assigned to another user');
        return VerificationResult(
          isAutoApproved: false,
          message:
              'This lot is already assigned. Added to manual verification queue.',
        );
      }

      // Auto approve - link user to master resident
      await _autoApproveUser(user, matchedResident);

      return VerificationResult(
        isAutoApproved: true,
        message: 'Verification successful! You now have full access.',
        lotId: matchedResident.lotId,
      );
    } catch (e) {
      throw Exception('Verification failed: $e');
    }
  }

  // Auto approve user and link to master resident
  Future<void> _autoApproveUser(UserModel user, MasterResident resident) async {
    WriteBatch batch = _firestore.batch();

    // Update user verification status
    batch.update(
      _firestore.collection('users').doc(user.uid),
      {
        'verificationStatus': VerificationStatus.approved.name,
        'lotId': resident.lotId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );

    // Link user to master resident
    batch.update(
      _firestore.collection('master_residents').doc(resident.lotId.toString()),
      {
        'userId': user.uid,
      },
    );

    await batch.commit();
  }

  // Add user to verification queue for manual review
  Future<void> _addToVerificationQueue(UserModel user, {String? reason}) async {
    await _firestore.collection('verification_queue').add({
      'userId': user.uid,
      'email': user.email,
      'firstName': user.firstName,
      'middleName': user.middleName,
      'lastName': user.lastName,
      'suffix': user.suffix,
      'fullAddress': user.fullAddress,
      'phase': user.phase,
      'block': user.block,
      'lotNumber': user.lotNumber,
      'reason': reason ?? 'No exact match found',
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Get verification queue (Admin only)
  Stream<List<Map<String, dynamic>>> getVerificationQueue() {
    return _firestore
        .collection('verification_queue')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Manually approve user (Admin only)
  Future<void> manuallyApproveUser(
    String queueDocId,
    String userId,
    int lotId,
  ) async {
    WriteBatch batch = _firestore.batch();

    // Update user verification status
    batch.update(
      _firestore.collection('users').doc(userId),
      {
        'verificationStatus': VerificationStatus.approved.name,
        'lotId': lotId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );

    // Link user to master resident
    batch.update(
      _firestore.collection('master_residents').doc(lotId.toString()),
      {
        'userId': userId,
      },
    );

    // Update queue status
    batch.update(
      _firestore.collection('verification_queue').doc(queueDocId),
      {
        'status': 'approved',
        'processedAt': FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();
  }

  // Reject user verification (Admin only)
  Future<void> rejectUser(String queueDocId, String userId) async {
    WriteBatch batch = _firestore.batch();

    // Update user verification status
    batch.update(
      _firestore.collection('users').doc(userId),
      {
        'verificationStatus': VerificationStatus.rejected.name,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );

    // Update queue status
    batch.update(
      _firestore.collection('verification_queue').doc(queueDocId),
      {
        'status': 'rejected',
        'processedAt': FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();
  }

  // Upload master residents from CSV (Admin only)
  Future<void> uploadMasterResidents(List<MasterResident> residents) async {
    WriteBatch batch = _firestore.batch();
    int count = 0;

    for (MasterResident resident in residents) {
      batch.set(
        _firestore
            .collection('master_residents')
            .doc(resident.lotId.toString()),
        resident.toMap(),
      );

      count++;

      // Firestore batch limit is 500 operations
      if (count == 500) {
        await batch.commit();
        batch = _firestore.batch();
        count = 0;
      }
    }

    if (count > 0) {
      await batch.commit();
    }
  }
}

class VerificationResult {
  final bool isAutoApproved;
  final String message;
  final int? lotId;

  VerificationResult({
    required this.isAutoApproved,
    required this.message,
    this.lotId,
  });
}

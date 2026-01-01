import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/master_resident.dart';

class MasterResidentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'master_residents';

  Future<String> addResident(MasterResident resident) async {
    final docRef =
        await _firestore.collection(_collection).add(resident.toMap());
    return docRef.id;
  }

  Future<void> updateResident(String id, MasterResident resident) async {
    await _firestore.collection(_collection).doc(id).update(resident.toMap());
  }

  Future<void> deleteResident(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  Future<MasterResident?> getResidentById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (doc.exists) {
      return MasterResident.fromFirestore(doc);
    }
    return null;
  }

  Future<MasterResident?> findAvailableMatch({
    required String firstName,
    required String lastName,
    required String lotNumber,
  }) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('firstName', isEqualTo: firstName)
        .where('lastName', isEqualTo: lastName)
        .where('lotNumber', isEqualTo: lotNumber)
        .where('isAvailable', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return MasterResident.fromFirestore(snapshot.docs.first);
    }
    return null;
  }

  Future<void> assignUser(String residentId, String userId) async {
    await _firestore.collection(_collection).doc(residentId).update({
      'userId': userId,
      'isAvailable': false,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> unassignUser(String residentId) async {
    await _firestore.collection(_collection).doc(residentId).update({
      'userId': null,
      'isAvailable': true,
      'updatedAt': Timestamp.now(),
    });
  }

  Stream<List<MasterResident>> getAllResidents() {
    return _firestore.collection(_collection).orderBy('lotId').snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) => MasterResident.fromFirestore(doc))
            .toList());
  }

  Stream<List<MasterResident>> getAvailableResidents() {
    return _firestore
        .collection(_collection)
        .where('isAvailable', isEqualTo: true)
        .orderBy('lotId')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MasterResident.fromFirestore(doc))
            .toList());
  }

  Future<int> getNextLotId() async {
    final snapshot = await _firestore
        .collection(_collection)
        .orderBy('lotId', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return 1001;
    }

    final lastResident = MasterResident.fromFirestore(snapshot.docs.first);
    return lastResident.lotId + 1;
  }
}

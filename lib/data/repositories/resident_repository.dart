import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/master_resident.dart';
import '../../core/constants/firebase_constants.dart';

class ResidentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all master residents
  Future<List<MasterResident>> getAllResidents() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(FirebaseConstants.masterResidentsCollection)
          .orderBy(FirebaseConstants.fieldLotId)
          .get();

      return querySnapshot.docs
          .map((doc) => MasterResident.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch residents: $e');
    }
  }

  // Get residents by phase
  Future<List<MasterResident>> getResidentsByPhase(String phase) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(FirebaseConstants.masterResidentsCollection)
          .where(FirebaseConstants.fieldPhase, isEqualTo: phase)
          .orderBy(FirebaseConstants.fieldLotId)
          .get();

      return querySnapshot.docs
          .map((doc) => MasterResident.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch residents by phase: $e');
    }
  }

  // Get resident by lot ID
  Future<MasterResident?> getResidentByLotId(int lotId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(FirebaseConstants.masterResidentsCollection)
          .doc(lotId.toString())
          .get();

      if (!doc.exists) return null;

      return MasterResident.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to fetch resident: $e');
    }
  }

  // Search residents by name
  Future<List<MasterResident>> searchResidentsByName(String searchTerm) async {
    try {
      final searchLower = searchTerm.toLowerCase();

      QuerySnapshot querySnapshot = await _firestore
          .collection(FirebaseConstants.masterResidentsCollection)
          .get();

      return querySnapshot.docs
          .map((doc) => MasterResident.fromFirestore(doc))
          .where((resident) =>
              resident.firstName.toLowerCase().contains(searchLower) ||
              resident.lastName.toLowerCase().contains(searchLower) ||
              resident.fullName.toLowerCase().contains(searchLower))
          .toList();
    } catch (e) {
      throw Exception('Failed to search residents: $e');
    }
  }

  // Get available lots
  Future<List<MasterResident>> getAvailableLots() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(FirebaseConstants.masterResidentsCollection)
          .where(FirebaseConstants.fieldIsAvailable, isEqualTo: true)
          .orderBy(FirebaseConstants.fieldLotId)
          .get();

      return querySnapshot.docs
          .map((doc) => MasterResident.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch available lots: $e');
    }
  }

  // Get rental properties
  Future<List<MasterResident>> getRentalProperties() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(FirebaseConstants.masterResidentsCollection)
          .where(FirebaseConstants.fieldIsRental, isEqualTo: true)
          .orderBy(FirebaseConstants.fieldLotId)
          .get();

      return querySnapshot.docs
          .map((doc) => MasterResident.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch rental properties: $e');
    }
  }

  // Add or update resident
  Future<void> addOrUpdateResident(MasterResident resident) async {
    try {
      await _firestore
          .collection(FirebaseConstants.masterResidentsCollection)
          .doc(resident.lotId.toString())
          .set(resident.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to add/update resident: $e');
    }
  }

  // Update resident availability
  Future<void> updateResidentAvailability(int lotId, bool isAvailable) async {
    try {
      await _firestore
          .collection(FirebaseConstants.masterResidentsCollection)
          .doc(lotId.toString())
          .update({
        FirebaseConstants.fieldIsAvailable: isAvailable,
      });
    } catch (e) {
      throw Exception('Failed to update availability: $e');
    }
  }

  // Update rental status
  Future<void> updateRentalStatus(int lotId, bool isRental) async {
    try {
      await _firestore
          .collection(FirebaseConstants.masterResidentsCollection)
          .doc(lotId.toString())
          .update({
        FirebaseConstants.fieldIsRental: isRental,
      });
    } catch (e) {
      throw Exception('Failed to update rental status: $e');
    }
  }

  // Link user to resident
  Future<void> linkUserToResident(int lotId, String userId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.masterResidentsCollection)
          .doc(lotId.toString())
          .update({
        FirebaseConstants.fieldUserId: userId,
      });
    } catch (e) {
      throw Exception('Failed to link user to resident: $e');
    }
  }

  // Unlink user from resident
  Future<void> unlinkUserFromResident(int lotId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.masterResidentsCollection)
          .doc(lotId.toString())
          .update({
        FirebaseConstants.fieldUserId: null,
      });
    } catch (e) {
      throw Exception('Failed to unlink user from resident: $e');
    }
  }

  // Delete resident
  Future<void> deleteResident(int lotId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.masterResidentsCollection)
          .doc(lotId.toString())
          .delete();
    } catch (e) {
      throw Exception('Failed to delete resident: $e');
    }
  }

  // Stream of all residents (real-time)
  Stream<List<MasterResident>> residentsStream() {
    return _firestore
        .collection(FirebaseConstants.masterResidentsCollection)
        .orderBy(FirebaseConstants.fieldLotId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MasterResident.fromFirestore(doc))
            .toList());
  }

  // Get statistics
  Future<Map<String, int>> getResidentStatistics() async {
    try {
      QuerySnapshot allResidents = await _firestore
          .collection(FirebaseConstants.masterResidentsCollection)
          .get();

      int totalLots = allResidents.docs.length;
      int occupiedLots = 0;
      int availableLots = 0;
      int rentalProperties = 0;
      int verifiedUsers = 0;

      for (var doc in allResidents.docs) {
        MasterResident resident = MasterResident.fromFirestore(doc);

        if (resident.isAvailable) {
          availableLots++;
        } else {
          occupiedLots++;
        }

        if (resident.isRental) {
          rentalProperties++;
        }

        if (resident.userId != null) {
          verifiedUsers++;
        }
      }

      return {
        'totalLots': totalLots,
        'occupiedLots': occupiedLots,
        'availableLots': availableLots,
        'rentalProperties': rentalProperties,
        'verifiedUsers': verifiedUsers,
      };
    } catch (e) {
      throw Exception('Failed to get statistics: $e');
    }
  }
}

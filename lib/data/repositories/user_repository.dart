import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'users';

  Future<void> createUser(UserModel user) async {
    await _firestore.collection(_collection).doc(user.uid).set(user.toMap());
  }

  Future<void> updateUser(UserModel user) async {
    await _firestore.collection(_collection).doc(user.uid).update(user.toMap());
  }

  Future<void> deleteUser(String uid) async {
    await _firestore.collection(_collection).doc(uid).delete();
  }

  Future<UserModel?> getUserById(String uid) async {
    final doc = await _firestore.collection(_collection).doc(uid).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }

  Stream<UserModel?> getUserStream(String uid) {
    return _firestore
        .collection(_collection)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  Future<void> verifyUser({
    required String uid,
    required String lotId,
  }) async {
    await _firestore.collection(_collection).doc(uid).update({
      'isVerified': true,
      'lotId': lotId,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> incrementTulongCount(String uid) async {
    await _firestore.collection(_collection).doc(uid).update({
      'tulongCount': FieldValue.increment(1),
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> incrementRequestsPosted(String uid) async {
    await _firestore.collection(_collection).doc(uid).update({
      'requestsPosted': FieldValue.increment(1),
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> incrementTimesHelped(String uid) async {
    await _firestore.collection(_collection).doc(uid).update({
      'timesHelped': FieldValue.increment(1),
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> incrementOffersMade(String uid) async {
    await _firestore.collection(_collection).doc(uid).update({
      'offersMade': FieldValue.increment(1),
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> updateResponseRate(String uid, double newRate) async {
    await _firestore.collection(_collection).doc(uid).update({
      'responseRate': newRate,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> addBadge(String uid, String badge) async {
    await _firestore.collection(_collection).doc(uid).update({
      'badges': FieldValue.arrayUnion([badge]),
      'updatedAt': Timestamp.now(),
    });
  }

  Stream<List<UserModel>> getAllUsers() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
  }

  Stream<List<UserModel>> getVerifiedUsers() {
    return _firestore
        .collection(_collection)
        .where('isVerified', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/verification_request.dart';
import '../repositories/master_resident_repository.dart';
import '../repositories/user_repository.dart';
import '../repositories/verification_request_repository.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _userRepo = UserRepository();
  final _masterResidentRepo = MasterResidentRepository();
  final _verificationRepo = VerificationRequestRepository();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String firstName,
    String middleName = '',
    required String lastName,
    String suffix = '',
    required String phase,
    required String block,
    required String lotNumber,
    required String fullAddress,
  }) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final masterResident = await _masterResidentRepo.findAvailableMatch(
      firstName: firstName,
      lastName: lastName,
      lotNumber: lotNumber,
    );

    final bool isAutoVerified = masterResident != null;
    final String? lotId = masterResident?.id;

    final newUser = UserModel(
      uid: userCredential.user!.uid,
      email: email,
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      suffix: suffix,
      fullAddress: fullAddress,
      phase: phase,
      block: block,
      lotNumber: lotNumber,
      lotId: lotId,
      isVerified: isAutoVerified,
      role: 'user',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _userRepo.createUser(newUser);

    if (isAutoVerified) {
      await _masterResidentRepo.assignUser(lotId!, userCredential.user!.uid);
    } else {
      final verificationRequest = VerificationRequest(
        id: '',
        userId: userCredential.user!.uid,
        userName: newUser.fullName,
        email: email,
        phase: phase,
        block: block,
        lotNumber: lotNumber,
        fullAddress: fullAddress,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await _verificationRepo.createRequest(verificationRequest);
    }

    return userCredential;
  }

  Future<void> updateVerificationStatus({
    required String uid,
    required bool isVerified,
    String? lotId,
  }) async {
    final updates = <String, dynamic>{
      'isVerified': isVerified,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (lotId != null) {
      updates['lotId'] = lotId;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update(updates);
  }

  Future<UserModel?> getUserData(String uid) async {
    return await _userRepo.getUserById(uid);
  }

  Future<UserModel?> getCurrentUserData() async {
    if (currentUser == null) return null;
    return await _userRepo.getUserById(currentUser!.uid);
  }

  Stream<UserModel?> getUserStream(String uid) {
    return _userRepo.getUserStream(uid);
  }

  Stream<UserModel?> getCurrentUserStream() {
    if (currentUser == null) {
      return Stream.value(null);
    }
    return _userRepo.getUserStream(currentUser!.uid);
  }
}

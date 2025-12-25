class FirebaseConstants {
  // Collection Names
  static const String usersCollection = 'users';
  static const String masterResidentsCollection = 'master_residents';
  static const String verificationQueueCollection = 'verification_queue';
  static const String announcementsCollection = 'announcements';
  static const String paymentsCollection = 'payments';
  static const String eventsCollection = 'events';

  // Field Names - Users Collection
  static const String fieldUid = 'uid';
  static const String fieldEmail = 'email';
  static const String fieldFirstName = 'firstName';
  static const String fieldMiddleName = 'middleName';
  static const String fieldLastName = 'lastName';
  static const String fieldSuffix = 'suffix';
  static const String fieldFullAddress = 'fullAddress';
  static const String fieldPhase = 'phase';
  static const String fieldBlock = 'block';
  static const String fieldLotNumber = 'lotNumber';
  static const String fieldRole = 'role';
  static const String fieldVerificationStatus = 'verificationStatus';
  static const String fieldLotId = 'lotId';
  static const String fieldCreatedAt = 'createdAt';
  static const String fieldUpdatedAt = 'updatedAt';

  // Field Names - Master Residents Collection
  static const String fieldUserId = 'userId';
  static const String fieldIsAvailable = 'isAvailable';
  static const String fieldIsRental = 'isRental';

  // Field Names - Verification Queue
  static const String fieldReason = 'reason';
  static const String fieldStatus = 'status';
  static const String fieldProcessedAt = 'processedAt';

  // Role Values
  static const String roleAdmin = 'admin';
  static const String roleUser = 'user';

  // Verification Status Values
  static const String statusPending = 'pending';
  static const String statusApproved = 'approved';
  static const String statusRejected = 'rejected';

  // Storage Paths
  static const String storageProfileImages = 'profile_images';
  static const String storageDocuments = 'documents';
  static const String storageAnnouncements = 'announcements';
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/help_request.dart';
import '../models/offer.dart';

/// Central service for all request and offer operations
///
/// Why a repository pattern?
/// - Separates data logic from UI
/// - Makes testing easier (can mock this class)
/// - Centralizes Firestore queries
/// - UI doesn't need to know about Firestore details
///
/// Architecture:
/// UI Screen → calls Repository → Firestore
///    ↑                              ↓
///    └──────── Stream updates ←──────┘
class RequestRepository {
  // Singleton pattern - only one instance exists
  static final RequestRepository _instance = RequestRepository._internal();
  factory RequestRepository() => _instance;
  RequestRepository._internal();

  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  /// Where all help requests are stored
  CollectionReference get _requestsCollection =>
      _firestore.collection('help_requests');

  /// Where all offers are stored
  CollectionReference get _offersCollection => _firestore.collection('offers');

  // ============================================================
  // REQUEST OPERATIONS
  // ============================================================

  /// Creates a new help request
  ///
  /// Flow:
  /// 1. User fills form → UI calls this method
  /// 2. Get current user info from Firebase Auth
  /// 3. Create HelpRequest object
  /// 4. Convert to Map and save to Firestore
  /// 5. Return the created request with its ID
  ///
  /// Example usage:
  /// final request = await repository.createRequest(
  ///   title: "Need dog walker",
  ///   description: "My dog needs walking daily",
  ///   category: RequestCategory.petCare,
  /// );
  Future<HelpRequest> createRequest(
      {required String title,
      required String description,
      required RequestCategory category,
      int helpersNeeded = 1,
      String location = '',
      required}) async {
    // Get current user
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Get user's display name from Firestore
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() as Map<String, dynamic>;
    final userName = '${userData['firstName']} ${userData['lastName']}';

    final tulongCount = userData['tulongCount'] ?? 0;

// Create request object
    final request = HelpRequest(
      id: '', // Will be set by Firestore
      requesterId: user.uid,
      requesterName: userName,
      title: title,
      description: description,
      category: category,
      status: RequestStatus.open,
      helpersNeeded: helpersNeeded,
      distance: 0,
      postedAt: DateTime.now(),
      tulongCount: tulongCount,
      location: location,
      offerCount: 0,
    );

    // Save to Firestore
    final docRef = await _requestsCollection.add(request.toMap());

    // Return request with Firestore-generated ID
    return request.copyWith(id: docRef.id);
  }

  /// Gets a stream of requests posted by the current user
  ///
  /// Why Stream?
  /// - Auto-updates UI when data changes
  /// - User posts new request → UI updates automatically
  /// - Someone offers help → Count updates automatically
  ///
  /// Flow:
  /// 1. Query Firestore for user's requests
  /// 2. Convert each document to HelpRequest object
  /// 3. Stream emits list whenever data changes
  ///
  /// Example usage:
  /// StreamBuilder<List<HelpRequest>>(
  ///   stream: repository.getUserRequests(),
  ///   builder: (context, snapshot) {
  ///     final requests = snapshot.data ?? [];
  ///     return ListView(children: ...);
  ///   },
  /// )
  Stream<List<HelpRequest>> getUserRequests() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _requestsCollection
        .where('requesterId', isEqualTo: userId)
        .orderBy('postedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => HelpRequest.fromFirestore(doc))
          .toList();
    });
  }

  /// Gets user's requests split by status (active vs completed)
  ///
  /// Active = open or in_progress
  /// Completed = completed or cancelled
  ///
  /// Returns: {
  ///   'active': [...],
  ///   'completed': [...],
  ///   'stats': {
  ///     'total': 5,
  ///     'active': 3,
  ///     'completed': 2
  ///   }
  /// }
  Stream<Map<String, dynamic>> getUserRequestsByStatus() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value({
        'active': [],
        'completed': [],
        'stats': {'total': 0, 'active': 0, 'completed': 0}
      });
    }

    return _requestsCollection
        .where('requesterId', isEqualTo: userId)
        .orderBy('postedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final allRequests =
          snapshot.docs.map((doc) => HelpRequest.fromFirestore(doc)).toList();

      // Split into active and completed
      final active = allRequests
          .where((r) =>
              r.status == RequestStatus.open ||
              r.status == RequestStatus.inProgress)
          .toList();

      final completed = allRequests
          .where((r) =>
              r.status == RequestStatus.completed ||
              r.status == RequestStatus.cancelled)
          .toList();

      return {
        'active': active,
        'completed': completed,
        'stats': {
          'total': allRequests.length,
          'active': active.length,
          'completed': completed.length,
        }
      };
    });
  }

  /// Gets a single request by ID
  ///
  /// Used when navigating to request details
  Future<HelpRequest?> getRequest(String requestId) async {
    final doc = await _requestsCollection.doc(requestId).get();
    if (!doc.exists) return null;
    return HelpRequest.fromFirestore(doc);
  }

  /// Updates request status
  ///
  /// Flow when requester accepts an offer:
  /// 1. Update request status to 'inProgress'
  /// 2. Set acceptedHelperId to the helper's ID
  /// 3. Set acceptedHelperName for display
  ///
  /// Example:
  /// await repository.updateRequestStatus(
  ///   requestId: 'req123',
  ///   status: RequestStatus.inProgress,
  ///   acceptedHelperId: 'user456',
  ///   acceptedHelperName: 'John Doe',
  /// );
  Future<void> updateRequestStatus({
    required String requestId,
    required RequestStatus status,
    String? acceptedHelperId,
    String? acceptedHelperName,
  }) async {
    final updateData = <String, dynamic>{
      'status': status.name,
    };

    if (status == RequestStatus.completed) {
      updateData['completedAt'] = Timestamp.now();
    }

    if (acceptedHelperId != null) {
      updateData['acceptedHelperId'] = acceptedHelperId;
    }

    if (acceptedHelperName != null) {
      updateData['acceptedHelperName'] = acceptedHelperName;
    }

    await _requestsCollection.doc(requestId).update(updateData);
  }

  /// Deletes a request and all its offers
  ///
  /// Cascade delete:
  /// 1. Delete all offers for this request
  /// 2. Delete the request itself
  Future<void> deleteRequest(String requestId) async {
    // Delete all offers first
    final offers =
        await _offersCollection.where('requestId', isEqualTo: requestId).get();

    for (var doc in offers.docs) {
      await doc.reference.delete();
    }

    // Delete the request
    await _requestsCollection.doc(requestId).delete();
  }

  // ============================================================
  // OFFER OPERATIONS
  // ============================================================

  /// Creates a new offer from a helper
  ///
  /// Flow:
  /// 1. Helper views request details
  /// 2. Clicks "Offer Help"
  /// 3. Optionally adds message
  /// 4. This method creates Offer in Firestore
  ///
  /// Example:
  /// await repository.createOffer(
  ///   requestId: 'req123',
  ///   message: "I can help! I have tools.",
  /// );
  Future<Offer> createOffer({
    required String requestId,
    required String helperName,
    String? message,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Get helper's name
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() as Map<String, dynamic>;
    final helperName = '${userData['firstName']} ${userData['lastName']}';

    // Check if user already offered for this request
    final existingOffer = await _offersCollection
        .where('requestId', isEqualTo: requestId)
        .where('helperId', isEqualTo: user.uid)
        .get();

    if (existingOffer.docs.isNotEmpty) {
      throw Exception('You have already offered to help with this request');
    }

    // Create offer
    final offer = Offer(
      id: '',
      requestId: requestId,
      helperId: user.uid,
      helperName: helperName,
      message: message,
      status: OfferStatus.pending,
      offeredAt: DateTime.now(),
    );

    // Save to Firestore
    final docRef = await _offersCollection.add(offer.toMap());

    return offer.copyWith(id: docRef.id);
  }

  /// Gets all offers for a specific request
  ///
  /// Used in Request Details → Offers tab
  /// Shows list of people who offered to help
  ///
  /// Returns a Stream that updates when:
  /// - New offer is made
  /// - Offer is accepted/rejected
  Stream<List<Offer>> getRequestOffers(String requestId) {
    return _offersCollection
        .where('requestId', isEqualTo: requestId)
        .orderBy('offeredAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Offer.fromFirestore(doc)).toList();
    });
  }

  /// Counts how many pending offers a request has
  ///
  /// Used to show "1 pending offer(s)" badge
  Future<int> getOfferCount(String requestId) async {
    final snapshot = await _offersCollection
        .where('requestId', isEqualTo: requestId)
        .where('status', isEqualTo: 'pending')
        .get();

    return snapshot.docs.length;
  }

  /// Accepts a specific offer
  ///
  /// Flow:
  /// 1. Update accepted offer status → 'accepted'
  /// 2. Update all other offers → 'rejected'
  /// 3. Update request status → 'inProgress'
  /// 4. Set request's acceptedHelperId
  ///
  /// Why batch?
  /// - Multiple Firestore writes happen atomically
  /// - Either ALL succeed or ALL fail
  /// - Prevents partial updates (data corruption)
  ///
  /// Example:
  /// await repository.acceptOffer(
  ///   requestId: 'req123',
  ///   offerId: 'offer456',
  /// );
  Future<void> acceptOffer({
    required String requestId,
    required String offerId,
  }) async {
    // Get the accepted offer to get helper info
    final offerDoc = await _offersCollection.doc(offerId).get();
    final offer = Offer.fromFirestore(offerDoc);

    // Use batch for atomic updates
    final batch = _firestore.batch();

    // Update the accepted offer
    batch.update(_offersCollection.doc(offerId), {
      'status': 'accepted',
      'respondedAt': Timestamp.now(),
    });

    // Reject all other pending offers for this request
    final otherOffers = await _offersCollection
        .where('requestId', isEqualTo: requestId)
        .where('status', isEqualTo: 'pending')
        .get();

    for (var doc in otherOffers.docs) {
      if (doc.id != offerId) {
        batch.update(doc.reference, {
          'status': 'rejected',
          'respondedAt': Timestamp.now(),
        });
      }
    }

    // Update request status and accepted helper
    batch.update(_requestsCollection.doc(requestId), {
      'status': 'inProgress',
      'acceptedHelperId': offer.helperId,
      'acceptedHelperName': offer.helperName,
    });

    // Commit all changes atomically
    await batch.commit();
  }

  /// Rejects a specific offer
  Future<void> rejectOffer(String offerId) async {
    await _offersCollection.doc(offerId).update({
      'status': 'rejected',
      'respondedAt': Timestamp.now(),
    });
  }

  /// Marks request as completed
  ///
  /// Called when requester confirms work is done
  Future<void> completeRequest(String requestId) async {
    await _requestsCollection.doc(requestId).update({
      'status': 'completed',
      'completedAt': Timestamp.now(),
    });
  }

  /// Cancels a request
  ///
  /// Called when requester no longer needs help
  /// Rejects all pending offers automatically
  Future<void> cancelRequest(String requestId) async {
    final batch = _firestore.batch();

    // Update request status
    batch.update(_requestsCollection.doc(requestId), {
      'status': 'cancelled',
    });

    // Reject all pending offers
    final offers = await _offersCollection
        .where('requestId', isEqualTo: requestId)
        .where('status', isEqualTo: 'pending')
        .get();

    for (var doc in offers.docs) {
      batch.update(doc.reference, {
        'status': 'rejected',
        'respondedAt': Timestamp.now(),
      });
    }

    await batch.commit();
  }
}

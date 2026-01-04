import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/marketplace_listing.dart';
import '../models/marketplace_category.dart';

class MarketplaceRepository {
  static final MarketplaceRepository _instance =
      MarketplaceRepository._internal();
  factory MarketplaceRepository() => _instance;
  MarketplaceRepository._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference get _listingsCollection =>
      _firestore.collection('marketplace_listings');
  CollectionReference get _categoriesCollection =>
      _firestore.collection('marketplace_categories');

  // ============================================================
  // CREATE
  // ============================================================

  Future<MarketplaceListing> createListing({
    required String title,
    required String description,
    required double price,
    required String categoryId,
    required ItemCondition condition,
    bool isNegotiable = false,
    String? location,
    bool allowsDelivery = false,
    List<String> tags = const [],
    List<File> photos = const [],
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Get user info
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() as Map<String, dynamic>;
    final sellerName = '${userData['firstName']} ${userData['lastName']}';
    final sellerPhone = userData['phoneNumber'];
    final sellerLotNumber = userData['lotNumber']?.toString();

    // Get category name
    String? categoryName;
    try {
      final categoryDoc = await _categoriesCollection.doc(categoryId).get();
      if (categoryDoc.exists) {
        categoryName =
            (categoryDoc.data() as Map<String, dynamic>)['categoryName'];
      }
    } catch (e) {
      print('Error fetching category: $e');
    }

    // Upload photos
    List<String> photosRef = [];
    if (photos.isNotEmpty) {
      photosRef = await _uploadPhotos(user.uid, photos);
    }

    final listing = MarketplaceListing(
      id: '',
      sellerId: user.uid,
      sellerName: sellerName,
      sellerPhone: sellerPhone,
      sellerLotNumber: sellerLotNumber,
      title: title,
      description: description,
      price: price,
      isNegotiable: isNegotiable,
      categoryId: categoryId,
      categoryName: categoryName,
      condition: condition,
      photosRef: photosRef,
      status: ListingStatus.active,
      location: location,
      allowsDelivery: allowsDelivery,
      tags: tags,
      timePosted: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final docRef = await _listingsCollection.add(listing.toMap());

    return listing.copyWith(id: docRef.id);
  }

  Future<List<String>> _uploadPhotos(String userId, List<File> photos) async {
    List<String> urls = [];

    for (int i = 0; i < photos.length; i++) {
      try {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = '${timestamp}_$i.jpg';
        final path = 'marketplace/$userId/$fileName';

        final ref = _storage.ref().child(path);
        await ref.putFile(photos[i]);
        final downloadUrl = await ref.getDownloadURL();

        urls.add(downloadUrl);
      } catch (e) {
        print('Error uploading photo $i: $e');
      }
    }

    return urls;
  }

  // ============================================================
  // READ
  // ============================================================

  Stream<List<MarketplaceListing>> getAllActiveListings() {
    return _listingsCollection
        .where('status', isEqualTo: 'ACTIVE')
        .orderBy('timePosted', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MarketplaceListing.fromFirestore(doc))
          .toList();
    });
  }

  Stream<List<MarketplaceListing>> getListingsByCategory(String categoryId) {
    return _listingsCollection
        .where('status', isEqualTo: 'ACTIVE')
        .where('categoryId', isEqualTo: categoryId)
        .orderBy('timePosted', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MarketplaceListing.fromFirestore(doc))
          .toList();
    });
  }

  Stream<List<MarketplaceListing>> getUserListings() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _listingsCollection
        .where('sellerId', isEqualTo: userId)
        .orderBy('timePosted', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MarketplaceListing.fromFirestore(doc))
          .toList();
    });
  }

  Future<MarketplaceListing?> getListing(String listingId) async {
    final doc = await _listingsCollection.doc(listingId).get();
    if (!doc.exists) return null;
    return MarketplaceListing.fromFirestore(doc);
  }

  Stream<List<MarketplaceCategory>> getActiveCategories() {
    return _categoriesCollection
        .where('isActive', isEqualTo: true)
        .orderBy('sortOrder')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MarketplaceCategory.fromFirestore(doc))
          .toList();
    });
  }

  // ============================================================
  // UPDATE
  // ============================================================

  Future<void> incrementViewCount(String listingId) async {
    await _listingsCollection.doc(listingId).update({
      'viewCount': FieldValue.increment(1),
    });
  }

  Future<void> updateListingStatus(
      String listingId, ListingStatus newStatus) async {
    await _listingsCollection.doc(listingId).update({
      'status': newStatus.name.toUpperCase(),
      'updatedAt': Timestamp.now(),
    });
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> deleteListing(String listingId) async {
    try {
      final listing = await getListing(listingId);

      if (listing != null && listing.photosRef.isNotEmpty) {
        for (var photoUrl in listing.photosRef) {
          try {
            final ref = _storage.refFromURL(photoUrl);
            await ref.delete();
          } catch (e) {
            print('Error deleting photo: $e');
          }
        }
      }

      await _listingsCollection.doc(listingId).delete();
    } catch (e) {
      throw Exception('Failed to delete listing: $e');
    }
  }

  /// Get all listings for admin (any status)
  Stream<List<MarketplaceListing>> getAllListingsForAdmin() {
    return _listingsCollection
        .orderBy('timePosted', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MarketplaceListing.fromFirestore(doc))
          .toList();
    });
  }

  /// Get listings by status for admin
  Stream<List<MarketplaceListing>> getListingsByStatus(ListingStatus status) {
    String statusValue = status.name.toUpperCase();

    return _listingsCollection
        .where('status', isEqualTo: statusValue)
        .orderBy('timePosted', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MarketplaceListing.fromFirestore(doc))
          .toList();
    });
  }

  /// Get listing statistics
  Future<Map<String, int>> getListingStats() async {
    final snapshot = await _listingsCollection.get();

    int total = snapshot.docs.length;
    int active = 0;
    int sold = 0;
    int withdrawn = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) continue;

      final status = data['status'] as String?;

      switch (status?.toUpperCase()) {
        case 'ACTIVE':
          active++;
          break;
        case 'SOLD':
          sold++;
          break;
        case 'WITHDRAWN':
          withdrawn++;
          break;
      }
    }

    return {
      'total': total,
      'active': active,
      'sold': sold,
      'withdrawn': withdrawn,
    };
  }

  /// Get all categories for admin (including inactive)
  Stream<List<MarketplaceCategory>> getAllCategories() {
    return _categoriesCollection
        .orderBy('sortOrder')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MarketplaceCategory.fromFirestore(doc))
          .toList();
    });
  }

  /// Create new category
  Future<void> createCategory({
    required String categoryName,
    required int sortOrder,
  }) async {
    await _categoriesCollection.add({
      'categoryName': categoryName,
      'sortOrder': sortOrder,
      'isActive': true,
    });
  }

  /// Update category
  Future<void> updateCategory(
    String categoryId,
    Map<String, dynamic> updates,
  ) async {
    await _categoriesCollection.doc(categoryId).update(updates);
  }

  /// Delete category
  Future<void> deleteCategory(String categoryId) async {
    await _categoriesCollection.doc(categoryId).delete();
  }

  /// Toggle category active status
  Future<void> toggleCategoryStatus(String categoryId, bool isActive) async {
    await _categoriesCollection.doc(categoryId).update({
      'isActive': isActive,
    });
  }

  Future<void> updateListing(
    String listingId,
    Map<String, dynamic> updates,
  ) async {
    await _listingsCollection.doc(listingId).update(updates);
  }
}

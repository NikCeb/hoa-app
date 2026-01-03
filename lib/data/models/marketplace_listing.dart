import 'package:cloud_firestore/cloud_firestore.dart';

enum ListingStatus {
  active,
  sold,
  withdrawn,
}

enum ItemCondition {
  brandNew,
  likeNew,
  used,
}

class MarketplaceListing {
  final String id; // listingId
  final String sellerId; // userId who posted
  final String sellerName;
  final String? sellerPhone;
  final String? sellerLotNumber;
  final String title;
  final String description;
  final double price;
  final bool isNegotiable;
  final String categoryId;
  final String? categoryName; // Cached for display
  final ItemCondition condition;
  final List<String> photosRef; // Array of URLs
  final ListingStatus status;
  final String? location;
  final bool allowsDelivery;
  final int viewCount;
  final int favoriteCount;
  final List<String> tags; // For search
  final DateTime timePosted;
  final DateTime updatedAt;

  MarketplaceListing({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    this.sellerPhone,
    this.sellerLotNumber,
    required this.title,
    required this.description,
    required this.price,
    this.isNegotiable = false,
    required this.categoryId,
    this.categoryName,
    this.condition = ItemCondition.used,
    this.photosRef = const [],
    this.status = ListingStatus.active,
    this.location,
    this.allowsDelivery = false,
    this.viewCount = 0,
    this.favoriteCount = 0,
    this.tags = const [],
    required this.timePosted,
    required this.updatedAt,
  });

  factory MarketplaceListing.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return MarketplaceListing(
      id: doc.id,
      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? 'Unknown Seller',
      sellerPhone: data['sellerPhone'],
      sellerLotNumber: data['sellerLotNumber'],
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      isNegotiable: data['isNegotiable'] ?? false,
      categoryId: data['category'] ?? data['categoryId'] ?? '',
      categoryName: data['categoryName'],
      condition: _parseCondition(data['condition']),
      photosRef: List<String>.from(data['photosRef'] ?? []),
      status: _parseStatus(data['status']),
      location: data['location'],
      allowsDelivery: data['allowsDelivery'] ?? false,
      viewCount: data['viewCount'] ?? 0,
      favoriteCount: data['favoriteCount'] ?? 0,
      tags: List<String>.from(data['tags'] ?? []),
      timePosted:
          (data['timePosted'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerPhone': sellerPhone,
      'sellerLotNumber': sellerLotNumber,
      'title': title,
      'description': description,
      'price': price,
      'isNegotiable': isNegotiable,
      'category': categoryId,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'condition': condition.name,
      'photosRef': photosRef,
      'status': status.name.toUpperCase(),
      'location': location,
      'allowsDelivery': allowsDelivery,
      'viewCount': viewCount,
      'favoriteCount': favoriteCount,
      'tags': tags,
      'timePosted': Timestamp.fromDate(timePosted),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static ItemCondition _parseCondition(dynamic condition) {
    if (condition is String) {
      switch (condition.toLowerCase()) {
        case 'brandnew':
        case 'brand_new':
        case 'new':
          return ItemCondition.brandNew;
        case 'likenew':
        case 'like_new':
          return ItemCondition.likeNew;
        case 'used':
          return ItemCondition.used;
        default:
          return ItemCondition.used;
      }
    }
    return ItemCondition.used;
  }

  static ListingStatus _parseStatus(dynamic status) {
    if (status is String) {
      switch (status.toUpperCase()) {
        case 'ACTIVE':
          return ListingStatus.active;
        case 'SOLD':
          return ListingStatus.sold;
        case 'WITHDRAWN':
          return ListingStatus.withdrawn;
        default:
          return ListingStatus.active;
      }
    }
    return ListingStatus.active;
  }

  // Getters
  bool get isActive => status == ListingStatus.active;
  bool get isSold => status == ListingStatus.sold;
  bool get isWithdrawn => status == ListingStatus.withdrawn;

  String get conditionText {
    switch (condition) {
      case ItemCondition.brandNew:
        return 'Brand New';
      case ItemCondition.likeNew:
        return 'Like New';
      case ItemCondition.used:
        return 'Used';
    }
  }

  String get statusText {
    switch (status) {
      case ListingStatus.active:
        return 'Active';
      case ListingStatus.sold:
        return 'Sold';
      case ListingStatus.withdrawn:
        return 'Withdrawn';
    }
  }

  String get priceText {
    return '₱${price.toStringAsFixed(2)}${isNegotiable ? ' (Negotiable)' : ''}';
  }

  String get timeAgo {
    final difference = DateTime.now().difference(timePosted);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  MarketplaceListing copyWith({
    String? id,
    String? sellerId,
    String? sellerName,
    String? sellerPhone,
    String? sellerLotNumber,
    String? title,
    String? description,
    double? price,
    bool? isNegotiable,
    String? categoryId,
    String? categoryName,
    ItemCondition? condition,
    List<String>? photosRef,
    ListingStatus? status,
    String? location,
    bool? allowsDelivery,
    int? viewCount,
    int? favoriteCount,
    List<String>? tags,
    DateTime? timePosted,
    DateTime? updatedAt,
  }) {
    return MarketplaceListing(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      sellerPhone: sellerPhone ?? this.sellerPhone,
      sellerLotNumber: sellerLotNumber ?? this.sellerLotNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      isNegotiable: isNegotiable ?? this.isNegotiable,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      condition: condition ?? this.condition,
      photosRef: photosRef ?? this.photosRef,
      status: status ?? this.status,
      location: location ?? this.location,
      allowsDelivery: allowsDelivery ?? this.allowsDelivery,
      viewCount: viewCount ?? this.viewCount,
      favoriteCount: favoriteCount ?? this.favoriteCount,
      tags: tags ?? this.tags,
      timePosted: timePosted ?? this.timePosted,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

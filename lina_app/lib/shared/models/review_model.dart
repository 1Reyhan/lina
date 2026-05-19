import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String reviewId;
  final String userId;
  final String sellerId;
  final String productId;
  final String orderId;
  final String displayName;
  final String userPhotoURL;
  final double rating;
  final String comment;
  final List<String> images;
  final String aiSentiment;
  final bool isVerifiedPurchase;
  final DateTime createdAt;
  final String? sellerReply;
  final DateTime? sellerReplyCreatedAt;

  ReviewModel({
    required this.reviewId,
    required this.userId,
    required this.sellerId,
    required this.productId,
    required this.orderId,
    required this.displayName,
    this.userPhotoURL = '',
    required this.rating,
    required this.comment,
    this.images = const [],
    this.aiSentiment = 'neutral',
    this.isVerifiedPurchase = true,
    required this.createdAt,
    this.sellerReply,
    this.sellerReplyCreatedAt,
  });

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'sellerId': sellerId,
    'productId': productId,
    'orderId': orderId,
    'displayName': displayName,
    'userPhotoURL': userPhotoURL,
    'rating': rating,
    'comment': comment,
    'images': images,
    'aiSentiment': aiSentiment,
    'isVerifiedPurchase': isVerifiedPurchase,
    'createdAt': Timestamp.fromDate(createdAt),
    'sellerReply': sellerReply,
    'sellerReplyCreatedAt':
        sellerReplyCreatedAt != null
            ? Timestamp.fromDate(sellerReplyCreatedAt!)
            : null,
  };

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return ReviewModel(
      reviewId: doc.id,
      userId: d['userId'] ?? '',
      sellerId: d['sellerId'] ?? '',
      productId: d['productId'] ?? '',
      orderId: d['orderId'] ?? '',
      displayName: d['displayName'] ?? 'Lina Kullanıcısı',
      userPhotoURL: d['userPhotoURL'] ?? '',
      rating: (d['rating'] ?? 5.0).toDouble(),
      comment: d['comment'] ?? '',
      images: List<String>.from(d['images'] ?? []),
      aiSentiment: d['aiSentiment'] ?? 'neutral',
      isVerifiedPurchase: d['isVerifiedPurchase'] ?? true,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      sellerReply: d['sellerReply'],
      sellerReplyCreatedAt: (d['sellerReplyCreatedAt'] as Timestamp?)?.toDate(),
    );
  }
}

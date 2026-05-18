import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String reviewId;
  final String productId;
  final String userId;
  final String
  sellerId; // Hangi satıcıya ait olduğunu bilmek ve güvenlik kurallarını çalıştırmak için eklendi
  final String displayName;
  final String userPhotoURL;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final String? sellerReply; // Satıcının cevabı
  final DateTime? sellerReplyCreatedAt; // Satıcının cevaplama tarihi

  ReviewModel({
    required this.reviewId,
    required this.productId,
    required this.userId,
    required this.sellerId,
    required this.displayName,
    this.userPhotoURL = '',
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.sellerReply,
    this.sellerReplyCreatedAt,
  });

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    final createdAtTimestamp = d['createdAt'] as Timestamp?;
    final replyTimestamp = d['sellerReplyCreatedAt'] as Timestamp?;

    return ReviewModel(
      reviewId: doc.id,
      productId: d['productId'] ?? '',
      userId: d['userId'] ?? '',
      sellerId: d['sellerId'] ?? '',
      displayName: d['displayName'] ?? 'Lina Kullanıcısı',
      userPhotoURL: d['userPhotoURL'] ?? '',
      rating: (d['rating'] ?? 5.0).toDouble(),
      comment: d['comment'] ?? '',
      createdAt:
          createdAtTimestamp != null
              ? createdAtTimestamp.toDate()
              : DateTime.now(),
      sellerReply: d['sellerReply'],
      sellerReplyCreatedAt: replyTimestamp?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'userId': userId,
    'sellerId': sellerId,
    'displayName': displayName,
    'userPhotoURL': userPhotoURL,
    'rating': rating,
    'comment': comment,
    'createdAt': Timestamp.fromDate(createdAt),
    'sellerReply': sellerReply,
    'sellerReplyCreatedAt':
        sellerReplyCreatedAt != null
            ? Timestamp.fromDate(sellerReplyCreatedAt!)
            : null,
  };
}

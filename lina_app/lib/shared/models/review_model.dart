import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String reviewId;
  final String productId;
  final String userId;
  final String displayName;
  final String userPhotoURL;
  final double rating;
  final String comment;
  final DateTime createdAt;

  ReviewModel({
    required this.reviewId,
    required this.productId,
    required this.userId,
    required this.displayName,
    this.userPhotoURL = '',
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    final createdAtTimestamp = d['createdAt'] as Timestamp?;

    return ReviewModel(
      reviewId: doc.id,
      productId: d['productId'] ?? '',
      userId: d['userId'] ?? '',
      displayName: d['displayName'] ?? 'Lina Kullanıcısı',
      userPhotoURL: d['userPhotoURL'] ?? '',
      rating: (d['rating'] ?? 5.0).toDouble(),
      comment: d['comment'] ?? '',
      createdAt:
          createdAtTimestamp != null
              ? createdAtTimestamp.toDate()
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'userId': userId,
    'displayName': displayName,
    'userPhotoURL': userPhotoURL,
    'rating': rating,
    'comment': comment,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}

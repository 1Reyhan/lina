import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String reviewId;
  final String userId;
  final String sellerId;
  final String productId;
  final String orderId;
  final String
  displayName; // 🌟 KORUNDU: UI'da her yorumun sahibini anında göstermek için gereklidir
  final String userPhotoURL; // 🌟 KORUNDU: Kullanıcı avatarı için gereklidir
  final double rating;
  final String comment;
  final List<String>
  images; // 🌟 YENİ: Kullanıcının yoruma eklediği fotoğraflar
  final String
  aiSentiment; // 🌟 YENİ: Lina AI Duygu Analizi ('positive' | 'neutral' | 'negative')
  final bool
  isVerifiedPurchase; // 🌟 YENİ: Ürünü gerçekten satın alan doğrulanmış müşteri mi?
  final DateTime createdAt;
  final String?
  sellerReply; // 🌟 KORUNDU: Trendyol stili satıcı cevaplama alanı
  final DateTime?
  sellerReplyCreatedAt; // 🌟 KORUNDU: Satıcının cevaplama tarihi

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

  // 🌟 YENİ: Satıcı yoruma cevap verdiğinde modeli kolayca güncellemek için copyWith katmanı
  ReviewModel copyWith({
    String? reviewId,
    String? userId,
    String? sellerId,
    String? productId,
    String? orderId,
    String? displayName,
    String? userPhotoURL,
    double? rating,
    String? comment,
    List<String>? images,
    String? aiSentiment,
    bool? isVerifiedPurchase,
    DateTime? createdAt,
    String? sellerReply,
    DateTime? sellerReplyCreatedAt,
  }) {
    return ReviewModel(
      reviewId: reviewId ?? this.reviewId,
      userId: userId ?? this.userId,
      sellerId: sellerId ?? this.sellerId,
      productId: productId ?? this.productId,
      orderId: orderId ?? this.orderId,
      displayName: displayName ?? this.displayName,
      userPhotoURL: userPhotoURL ?? this.userPhotoURL,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      images: images ?? this.images,
      aiSentiment: aiSentiment ?? this.aiSentiment,
      isVerifiedPurchase: isVerifiedPurchase ?? this.isVerifiedPurchase,
      createdAt: createdAt ?? this.createdAt,
      sellerReply: sellerReply ?? this.sellerReply,
      sellerReplyCreatedAt: sellerReplyCreatedAt ?? this.sellerReplyCreatedAt,
    );
  }

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    // 🌟 DÜZELTİLDİ: Boş döküman gelme olasılığına karşı null-safety koruması
    final d = doc.data() as Map<String, dynamic>? ?? {};

    final createdAtTimestamp = d['createdAt'] as Timestamp?;
    final replyTimestamp = d['sellerReplyCreatedAt'] as Timestamp?;

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
      createdAt:
          createdAtTimestamp != null
              ? createdAtTimestamp.toDate()
              : DateTime.now(),
      sellerReply: d['sellerReply'],
      sellerReplyCreatedAt: replyTimestamp?.toDate(),
    );
  }

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
}

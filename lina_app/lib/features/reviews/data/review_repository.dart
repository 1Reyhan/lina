import 'package:cloud_firestore/cloud_firestore.dart';
// ÖNEMLİ: Projenizin kök dizinine göre doğru yolu yazdık:
import '../../../../shared/models/review_model.dart';

class ReviewRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<ReviewModel>> getReviewsByProduct(String productId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('reviews')
              .where('productId', isEqualTo: productId)
              .get();

      final reviews =
          querySnapshot.docs
              .map((doc) => ReviewModel.fromFirestore(doc))
              .toList();

      // Sıralama yaparken null güvenliği için null-check ekledik
      reviews.sort((a, b) {
        return b.createdAt.compareTo(a.createdAt);
      });

      return reviews;
    } catch (e) {
      throw Exception("Yorumlar getirilirken hata oluştu: $e");
    }
  }

  Future<void> addReview(ReviewModel review) async {
    await _firestore
        .collection('reviews')
        .doc(review.reviewId)
        .set(review.toMap());
  }
}

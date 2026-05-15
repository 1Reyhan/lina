import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/product_model.dart';

class ProductRepository {
  final _db = FirebaseFirestore.instance;

  // 1. Ürün Listeleme: Filtreleme ve Canlı Takip
  Stream<List<ProductModel>> getProducts({String? category}) {
    Query query = _db.collection('products').where('isActive', isEqualTo: true);

    if (category != null && category != 'Tümü') {
      query = query.where('category', isEqualTo: category);
    }

    // En yeni ürünler önce (Firebase'de composite index oluşturmayı unutma)
    query = query.orderBy('createdAt', descending: true);

    return query.snapshots().map(
      (snap) => snap.docs.map((d) => ProductModel.fromFirestore(d)).toList(),
    );
  }

  // 2. Tek Ürün Getirme
  Future<ProductModel?> getProduct(String productId) async {
    try {
      final doc = await _db.collection('products').doc(productId).get();
      if (!doc.exists) return null;
      return ProductModel.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  // 3. Profesyonel Arama Motoru (Server-Side Prefix Search)
  // Trendyol/Getir mantığı: Yazmaya başladığı an eşleşenleri getirir.
  Stream<List<ProductModel>> searchProducts(String queryText) {
    if (queryText.isEmpty) return Stream.value([]);

    // Firestore'da 'name' üzerinden sunucu taraflı arama yapar.
    // Bu yöntem binlerce üründe bile saniyesinde sonuç döndürür.
    return _db
        .collection('products')
        .where('isActive', isEqualTo: true)
        .where('name', isGreaterThanOrEqualTo: queryText)
        .where('name', isLessThanOrEqualTo: '$queryText\uf8ff')
        .limit(
          20,
        ) // Performans için ilk 20 sonucu getirir (Hepsiburada mantığı)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => ProductModel.fromFirestore(d)).toList(),
        );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/product_model.dart';

class SellerProductRepository {
  final _db = FirebaseFirestore.instance;

  // Satıcının ürünlerini güvenli bir şekilde dinle
  Stream<List<ProductModel>> watchSellerProducts(String sellerId) {
    try {
      return _db
          .collection('products')
          .where('sellerId', isEqualTo: sellerId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snap) =>
                snap.docs.map((d) => ProductModel.fromFirestore(d)).toList(),
          );
    } catch (e) {
      print(
        'faz3: watchSellerProducts hata oluştu (İndeks kontrolü gerekebilir): $e',
      );
      // Hata durumunda uygulamanın kilitlenmemesi için boş liste akışı döner
      return Stream.value([]);
    }
  }

  // Ürün ekle
  Future<String> addProduct(ProductModel product) async {
    final ref = _db.collection('products').doc();
    // toMap() zaten temiz veri ürettiği için doğrudan set ediyoruz
    await ref.set(product.toMap());
    return ref.id;
  }

  // Ürün güncelle
  Future<void> updateProduct(
    String productId,
    Map<String, dynamic> data,
  ) async {
    await _db.collection('products').doc(productId).update(data);
  }

  // Ürün sil (Doğrudan silmek yerine pasife çekme mimarisi - Harika yaklaşım)
  Future<void> deactivateProduct(String productId) async {
    await _db.collection('products').doc(productId).update({'isActive': false});
  }

  // Stok güncelle
  Future<void> updateStock(String productId, int stock) async {
    await _db.collection('products').doc(productId).update({'stock': stock});
  }
}

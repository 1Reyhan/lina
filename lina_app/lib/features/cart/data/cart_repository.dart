import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/cart_model.dart';

class CartRepository {
  final _db = FirebaseFirestore.instance;

  // Sepeti canlı olarak dinle
  Stream<CartModel?> watchCart(String uid) {
    return _db.collection('carts').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return CartModel.fromFirestore(doc);
    });
  }

  // Sepete ürün ekle veya miktar güncelle
  Future<void> addToCart(
    String uid,
    CartItemModel item, {
    String? bundleId,
  }) async {
    final ref = _db.collection('carts').doc(uid);
    final doc = await ref.get();

    if (!doc.exists) {
      // ŞEMAYA UYGUN İLK OLUŞTURMA
      final cart = CartModel(
        uid: uid,
        items: [item],
        bundleId: bundleId,
        updatedAt: DateTime.now(),
      );
      await ref.set(cart.toMap());
      return;
    }

    final cart = CartModel.fromFirestore(doc);
    final idx = cart.items.indexWhere((e) => e.productId == item.productId);

    if (idx >= 0) {
      cart.items[idx].quantity += item.quantity;
    } else {
      cart.items.add(item);
    }

    // ŞEMAYA UYGUN GÜNCELLEME
    await ref.update({
      'items': cart.items.map((e) => e.toMap()).toList(),
      'totalPrice': cart.totalPrice, // Şemadaki totalPrice güncelleniyor
      'bundleId': bundleId ?? cart.bundleId, // Varsa paket ID güncelleniyor
      'updatedAt': FieldValue.serverTimestamp(), // Şemadaki updatedAt
    });
  }

  // Ürün miktarını artır/azalt veya sil
  Future<void> updateQuantity(
    String uid,
    String productId,
    int quantity,
  ) async {
    final ref = _db.collection('carts').doc(uid);
    final doc = await ref.get();
    if (!doc.exists) return;

    final cart = CartModel.fromFirestore(doc);
    if (quantity <= 0) {
      cart.items.removeWhere((e) => e.productId == productId);
    } else {
      final idx = cart.items.indexWhere((e) => e.productId == productId);
      if (idx >= 0) cart.items[idx].quantity = quantity;
    }

    await ref.update({
      'items': cart.items.map((e) => e.toMap()).toList(),
      'totalPrice': cart.totalPrice,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Sepeti temizle (Siparişten sonra kullanılır)
  Future<void> clearCart(String uid) async {
    await _db.collection('carts').doc(uid).update({
      'items': [],
      'totalPrice': 0,
      'bundleId': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

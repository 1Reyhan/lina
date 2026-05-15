import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/order_model.dart';
import '../../../shared/models/cart_model.dart';

class OrderRepository {
  final _db = FirebaseFirestore.instance;

  // Sipariş oluştur - Şemadaki TÜM alanları kapsar
  Future<String> createOrder({
    required String userId,
    required String sellerId,
    required List<CartItemModel> items,
    required Map<String, dynamic> deliveryAddress,
    required double totalAmount,
    double discountAmount = 0,
    String paymentMethod = 'Kredi Kartı', // Şemadaki paymentMethod
    String paymentStatus = 'pending', // Şemadaki paymentStatus
    String couponCode = '',
    String deliveryNote = '',
  }) async {
    final ref = _db.collection('orders').doc();

    // Şemadaki estimatedDelivery için varsayılan bir süre (örn: 45 dk sonrası)
    final estimatedDate = DateTime.now().add(const Duration(minutes: 45));

    final order = OrderModel(
      orderId: ref.id,
      userId: userId,
      sellerId: sellerId,
      items: items,
      status: 'pending', // Şemadaki başlangıç durumu
      deliveryAddress: deliveryAddress,
      totalAmount: totalAmount,
      discountAmount: discountAmount,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      couponCode: couponCode,
      deliveryNote: deliveryNote,
      estimatedDelivery: estimatedDate, // Şemadaki alan
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(), // Şemadaki updatedAt
    );

    await ref.set(order.toMap());
    return ref.id;
  }

  // Kullanıcının siparişlerini dinle (Canlı Takip Ekranı İçin)
  Stream<List<OrderModel>> watchUserOrders(String userId) {
    return _db
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => OrderModel.fromFirestore(d)).toList(),
        );
  }

  // Sipariş Durumu Güncelleme (Satıcı tarafı veya simülasyon için gerekebilir)
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _db.collection('orders').doc(orderId).update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Tek sipariş detayı
  Stream<OrderModel?> watchOrder(String orderId) {
    return _db
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .map((doc) => doc.exists ? OrderModel.fromFirestore(doc) : null);
  }
}

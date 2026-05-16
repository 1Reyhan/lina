import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/order_model.dart';
import '../../../shared/models/campaign_model.dart';

class SellerOrderRepository {
  final _db = FirebaseFirestore.instance;

  // Satıcının siparişlerini gerçek zamanlı dinle (İndeks korumalı)
  Stream<List<OrderModel>> watchSellerOrders(String sellerId) {
    try {
      return _db
          .collection('orders')
          .where('sellerId', isEqualTo: sellerId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snap) =>
                snap.docs.map((d) => OrderModel.fromFirestore(d)).toList(),
          );
    } catch (e) {
      print('faz3: watchSellerOrders sorgu hatası: $e');
      return Stream.value([]); // Çökmeyi önlemek için boş akış döner
    }
  }

  // Sipariş durumunu güvenli şekilde güncelle
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _db.collection('orders').doc(orderId).update({
        'status': status,
        'updatedAt':
            FieldValue.serverTimestamp(), // Local saat yerine kesin sunucu saati
      });
    } catch (e) {
      print('faz3: updateOrderStatus hatası: $e');
      rethrow;
    }
  }

  // Kampanya oluştur katmanı (İlk adımda ürettiğimiz tip güvenli CampaignModel yapısına entegre edildi)
  Future<void> createCampaign(CampaignModel campaign) async {
    try {
      final ref = _db.collection('campaigns').doc();
      await ref.set({
        ...campaign.toMap(),
        'campaignId': ref.id, // Veri bütünlüğü için iç ID eşitlendi
      });
    } catch (e) {
      print('faz3: createCampaign hatası: $e');
      rethrow;
    }
  }

  // Satıcının kampanyalarını dinle (Ham harita yerine güvenli CampaignModel listesi döner)
  Stream<List<CampaignModel>> watchCampaigns(String sellerId) {
    try {
      return _db
          .collection('campaigns')
          .where('sellerId', isEqualTo: sellerId)
          .snapshots()
          .map(
            (snap) =>
                snap.docs.map((d) => CampaignModel.fromFirestore(d)).toList(),
          );
    } catch (e) {
      print('faz3: watchCampaigns hatası: $e');
      return Stream.value([]);
    }
  }
}

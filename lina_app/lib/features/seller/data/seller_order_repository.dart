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

  // Kampanya oluştur katmanı (Tip güvenli CampaignModel yapısını koruyarak ID döndürecek şekilde güncellendi)
  Future<String> createCampaign(CampaignModel campaign) async {
    try {
      final ref = _db.collection('campaigns').doc();
      await ref.set({
        ...campaign.toMap(),
        'campaignId': ref.id, // Veri bütünlüğü için iç ID eşitlendi
      });
      return ref
          .id; // Sağlayıcılar ve UI katmanında kullanılabilmesi için üretilen ID döndürülüyor
    } catch (e) {
      print('faz3: createCampaign hatası: $e');
      rethrow;
    }
  }

  // Satıcının kampanyalarını dinle (CampaignModel listesi döner ve başlangıç tarihine göre azalan sırada listeler)
  Stream<List<CampaignModel>> watchCampaigns(String sellerId) {
    try {
      return _db
          .collection('campaigns')
          .where('sellerId', isEqualTo: sellerId)
          .orderBy(
            'startDate',
            descending: true,
          ) // Yeni eklenen sıralama kriteri
          .snapshots()
          .map(
            (snap) =>
                snap.docs.map((d) => CampaignModel.fromFirestore(d)).toList(),
          );
    } catch (e) {
      print('faz3: watchCampaigns hatası: $e');
      return Stream.value([]); // Hata durumunda akışın kopmasını engeller
    }
  }

  // Kampanya aktif/pasif durumunu güvenli şekilde güncelle (Yeni eklenen işlev)
  Future<void> toggleCampaign(String campaignId, bool isActive) async {
    try {
      await _db.collection('campaigns').doc(campaignId).update({
        'isActive': isActive,
      });
    } catch (e) {
      print('faz3: toggleCampaign hatası: $e');
      rethrow;
    }
  }
}

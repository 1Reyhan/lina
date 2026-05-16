import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/seller_model.dart';

class SellerRepository {
  final _db = FirebaseFirestore.instance;

  // Satıcı profilini gerçek zamanlı dinle
  Stream<SellerModel?> watchSeller(String uid) {
    return _db.collection('sellers').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return SellerModel.fromFirestore(doc);
    });
  }

  // Bugünkü özet istatistikler (Güvenli sorgu yapısı)
  Future<Map<String, dynamic>> getDashboardStats(String sellerId) async {
    double revenue = 0;
    int pending = 0;
    int todayOrdersCount = 0;
    int activeProductsCount = 0;

    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      // Siparişleri getirir (Firestore composite index uyarısı verirse terminaldeki linke tıklamalısın)
      final ordersSnap =
          await _db
              .collection('orders')
              .where('sellerId', isEqualTo: sellerId)
              .where(
                'createdAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
              )
              .get();

      todayOrdersCount = ordersSnap.docs.length;

      for (final doc in ordersSnap.docs) {
        final data = doc.data();
        revenue += (data['totalAmount'] ?? 0).toDouble();
        if (data['status'] == 'pending') pending++;
      }

      // Toplam aktif ürün sayısı sorgusu
      final productsSnap =
          await _db
              .collection('products')
              .where('sellerId', isEqualTo: sellerId)
              .where('isActive', isEqualTo: true)
              .get();

      activeProductsCount = productsSnap.docs.length;
    } catch (e) {
      // Olası bir Firestore Index eksikliğinde uygulamanın çökmesini engeller, hata basar
      print('faz3: getDashboardStats sorgu hatası: $e');
    }

    return {
      'todayRevenue': revenue,
      'todayOrders': todayOrdersCount,
      'pendingOrders': pending,
      'activeProducts': activeProductsCount,
    };
  }

  // Analitik verilerini birleştirerek kaydet
  Future<void> saveAnalytics(String sellerId, Map<String, dynamic> data) async {
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      await _db.collection('sellerAnalytics').doc('${sellerId}_$today').set({
        ...data,
        'sellerId': sellerId,
        'date': today,
      }, SetOptions(merge: true));
    } catch (e) {
      print('faz3: saveAnalytics hatası: $e');
    }
  }
}

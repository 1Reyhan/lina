import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/seller_repository.dart';
import '../data/seller_product_repository.dart';
import '../data/seller_order_repository.dart';
import '../../../shared/models/seller_model.dart';
import '../../../shared/models/product_model.dart';
import '../../../shared/models/order_model.dart';
import '../../../shared/models/campaign_model.dart';

// Veri depolarının tekil örnekleri (Repositories)
final sellerRepositoryProvider = Provider((ref) => SellerRepository());
final sellerProductRepositoryProvider = Provider(
  (ref) => SellerProductRepository(),
);
final sellerOrderRepositoryProvider = Provider(
  (ref) => SellerOrderRepository(),
);

// Reaktif Firebase Kullanıcı Kimliği Sağlayıcısı (Oturum durumunu canlı izler)
final sellerUidProvider = StreamProvider<String?>((ref) {
  return FirebaseAuth.instance.authStateChanges().map((user) => user?.uid);
});

// Canlı Satıcı Profili Sağlayıcısı (Oturum kapandığında otomatik sıfırlanır)
final sellerProfileProvider = StreamProvider<SellerModel?>((ref) {
  final uidAsync = ref.watch(sellerUidProvider);

  return uidAsync.when(
    data: (uid) {
      if (uid == null) return Stream.value(null);
      return ref.watch(sellerRepositoryProvider).watchSeller(uid);
    },
    error: (e, stack) {
      print('faz3: sellerProfileProvider Auth hatası: $e');
      return Stream.value(null);
    },
    loading: () => const Stream.empty(),
  );
});

// Dashboard İstatistikleri Sağlayıcısı
final dashboardStatsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  // Canlı UID takibi üzerinden veri güvenliği sağlanır
  final uidAsync = ref.watch(sellerUidProvider);
  final uid = uidAsync.valueOrNull;

  if (uid == null) return {};
  return ref.watch(sellerRepositoryProvider).getDashboardStats(uid);
});

// Satıcının Canlı Ürün Listesi Sağlayıcısı
final sellerProductsProvider = StreamProvider<List<ProductModel>>((ref) {
  final uidAsync = ref.watch(sellerUidProvider);
  final uid = uidAsync.valueOrNull;

  if (uid == null) return Stream.value([]);
  return ref.watch(sellerProductRepositoryProvider).watchSellerProducts(uid);
});

// Satıcının Canlı Sipariş Listesi Sağlayıcısı
final sellerOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final uidAsync = ref.watch(sellerUidProvider);
  final uid = uidAsync.valueOrNull;

  if (uid == null) return Stream.value([]);
  return ref.watch(sellerOrderRepositoryProvider).watchSellerOrders(uid);
});

// Satıcının Canlı Kampanya Listesi Sağlayıcısı (Eksik olan kısım güvenli model yapısıyla eklendi)
final sellerCampaignsProvider = StreamProvider<List<CampaignModel>>((ref) {
  final uidAsync = ref.watch(sellerUidProvider);
  final uid = uidAsync.valueOrNull;

  if (uid == null) return Stream.value([]);
  return ref.watch(sellerOrderRepositoryProvider).watchCampaigns(uid);
});

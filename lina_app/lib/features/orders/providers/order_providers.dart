import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/order_repository.dart';
import '../../../shared/models/order_model.dart';

// 1. Repository Sağlayıcısı
final orderRepositoryProvider = Provider((ref) => OrderRepository());

// 2. Kullanıcı Oturum Akışı (Kullanıcı değiştiğinde siparişleri tetikler)
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// 3. Kullanıcının Sipariş Listesi (Canlı/Stream)
final userOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      // Repository üzerinden kullanıcının UID'sine göre siparişleri dinler
      return ref.watch(orderRepositoryProvider).watchUserOrders(user.uid);
    },
    loading: () => const Stream.empty(),
    error: (err, stack) => Stream.error(err),
  );
});

// 4. Tekil Sipariş Detayı (Parametrik - family)
// Sipariş takip ekranında o anki siparişin durumunu (shipped, delivered vb.) izler
final orderDetailProvider = StreamProvider.family<OrderModel?, String>((
  ref,
  orderId,
) {
  return ref.watch(orderRepositoryProvider).watchOrder(orderId);
});

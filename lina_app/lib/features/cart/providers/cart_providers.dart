import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/cart_repository.dart';
import '../../../shared/models/cart_model.dart';

// 1. Repository Sağlayıcısı
final cartRepositoryProvider = Provider((ref) => CartRepository());

// 2. Kullanıcı Oturum Durumu (Sepetin doğru kullanıcıya bağlanması için şart)
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// 3. Canlı Sepet Sağlayıcısı (Kullanıcı değişimine duyarlı)
final cartProvider = StreamProvider<CartModel?>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      // Kullanıcı her değiştiğinde doğru sepeti dinlemeye başlar
      return ref.watch(cartRepositoryProvider).watchCart(user.uid);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

// 4. Sepetteki Toplam Ürün Sayısı (Badge/Kırmızı nokta için)
// Şemandaki quantity (adet) bilgisini toplar
final cartItemCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider).valueOrNull;
  if (cart == null) return 0;
  // Sadece ürün sayısını değil, adetleri topluyoruz (Örn: 2 Elma + 1 Süt = 3)
  return cart.items.fold(0, (sum, item) => sum + item.quantity);
});

// 5. Sepet Toplam Tutarı (Ödeme ekranı için)
final cartTotalAmountProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider).valueOrNull;
  return cart?.totalPrice ?? 0.0;
});

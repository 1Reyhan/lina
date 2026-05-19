import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lina/features/fridge/data/fridge_repository.dart';
import 'package:lina/shared/models/fridge_item_model.dart';

/// Kimlik doğrulama durumunu takip eden sağlayıcı (UID değiştiğinde tetiklenir)
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Fridge Repository sağlayıcısı
final fridgeRepositoryProvider = Provider<FridgeRepository>((ref) {
  return FridgeRepository();
});

/// Kullanıcının buzdolabı öğelerini anlık dinleyen sağlayıcı
final fridgeItemsProvider = StreamProvider<List<FridgeItemModel>>((ref) {
  final user = ref.watch(authStateProvider).value;

  if (user == null) {
    return Stream.value([]);
  }

  return ref.watch(fridgeRepositoryProvider).watchFridgeItems(user.uid);
});

/// Son kullanma tarihi yaklaşan ürünleri filtreleyen sağlayıcı
final expiringItemsProvider = Provider<List<FridgeItemModel>>((ref) {
  final itemsAsync = ref.watch(fridgeItemsProvider);

  return itemsAsync.when(
    data: (items) => items.where((i) => i.isExpiringSoon).toList(),
    error: (_, __) => [],
    loading: () => [],
  );
});

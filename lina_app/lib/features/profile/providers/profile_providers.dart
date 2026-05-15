import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/profile_repository.dart';
import '../../../shared/models/user_profile_model.dart';

// 1. Repository Sağlayıcısı
final profileRepositoryProvider = Provider((ref) => ProfileRepository());

// 2. Auth State Sağlayıcısı (Oturum açan kullanıcıyı takip eder)
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// 3. Kullanıcı Profil Sağlayıcısı (CANLI - StreamProvider)
// Kullanıcının alerjileri veya diyet tipi değiştiği an UI anında yenilenir.
final userProfileProvider = StreamProvider<UserProfileModel?>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);

      // Firestore'u canlı dinleyen bir stream döndürmek için repository'e ekleme yapıyoruz
      // Şimdilik getProfile metodunu kullanıyorsan FutureProvider yerine
      // Stream döndüren bir yapı daha profesyoneldir.
      return Stream.fromFuture(
        ref.watch(profileRepositoryProvider).getProfile(user.uid),
      );
    },
    loading: () => const Stream.empty(),
    error: (err, stack) => Stream.error(err),
  );
});

// 4. Spesifik Alerji Kontrol Sağlayıcısı (Performans için)
// Uygulama içinde sadece alerjilere ihtiyaç duyduğumuzda bunu izleyebiliriz.
final userAllergiesProvider = Provider<List<String>>((ref) {
  final profile = ref.watch(userProfileProvider).valueOrNull;
  return profile?.allergies ?? [];
});

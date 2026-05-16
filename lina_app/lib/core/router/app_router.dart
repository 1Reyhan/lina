import 'dart:async'; // StreamSubscription hatasını çözer
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart'; // FirebaseAuth hatasını çözer

// Auth Ekranları
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/user_register_screen.dart';
import '../../features/auth/presentation/seller_register_screen.dart';
import '../../features/auth/providers/auth_providers.dart';

// Yeni Eklenen Özellik Ekranları
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/presentation/product_detail_screen.dart';
import '../../features/cart/presentation/cart_screen.dart';
import '../../features/cart/presentation/checkout_screen.dart';
import '../../features/orders/presentation/orders_screen.dart';
import '../../features/orders/presentation/order_detail_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/seller/presentation/seller_dashboard_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    // Riverpod 2.x+ için linter uyarısı vermeyen en güncel dinleme yapısı
    refreshListenable: GoRouterRefreshStream(
      Stream.fromFuture(ref.watch(authStateProvider.future)),
    ),
    redirect: (context, state) async {
      // Anlık kullanıcıyı Firebase Auth üzerinden güvenli şekilde alıyoruz
      final user = FirebaseAuth.instance.currentUser;
      final isAuth = user != null;

      final String currentLoc = state.matchedLocation;

      // Auth ile ilgili rotalar
      final isOnAuth =
          currentLoc == '/login' ||
          currentLoc == '/register' ||
          currentLoc == '/register/user' ||
          currentLoc == '/register/seller' ||
          currentLoc == '/splash';

      // Herkese açık sayfalar
      final isPublicPage =
          currentLoc == '/home' || currentLoc.startsWith('/product/');

      // 1. Durum: Giriş yapmamış kullanıcı korumalı sayfaya gitmeye çalışıyorsa -> Login'e at
      if (!isAuth && !isOnAuth && !isPublicPage) {
        return '/login';
      }

      // 2. Durum: Giriş yapmış kullanıcı zaten içeride bir sayfaya gidiyorsa (Örn: satıcı paneli)
      // GoRouter'ın onu zorla başa /splash'e atmasını ENGELLİYORUZ. Gittiği sayfada kalsın.
      if (isAuth && !isOnAuth) {
        return null;
      }

      // 3. Durum: Giriş yapmış kullanıcı yanlışlıkla hala login/register sayfalarındaysa
      if (isAuth && isOnAuth && currentLoc != '/splash') {
        return '/splash';
      }

      return null;
    },
    routes: [
      // --- Temel & Ürün Rotaları ---
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(
        path: '/product/:id',
        builder:
            (_, state) =>
                ProductDetailScreen(productId: state.pathParameters['id']!),
      ),

      // --- Sepet & Ödeme Rotaları ---
      GoRoute(path: '/cart', builder: (_, __) => const CartScreen()),
      GoRoute(path: '/checkout', builder: (_, __) => const CheckoutScreen()),

      // --- Sipariş Rotaları ---
      GoRoute(path: '/orders', builder: (_, __) => const OrdersScreen()),
      GoRoute(
        path: '/orders/:id',
        builder:
            (_, state) =>
                OrderDetailScreen(orderId: state.pathParameters['id']!),
      ),

      // --- Profil Rotaları ---
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),

      // --- Kayıt Akışı Rotaları ---
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/register/user',
        builder: (_, __) => const UserRegisterScreen(),
      ),
      GoRoute(
        path: '/register/seller',
        builder: (_, __) => const SellerRegisterScreen(),
      ),

      // --- Satıcı Rotaları ---
      GoRoute(
        path: '/seller/pending',
        builder:
            (_, __) => const Scaffold(
              body: Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.hourglass_top, size: 64, color: Colors.orange),
                      SizedBox(height: 24),
                      Text(
                        'Başvurunuz Alındı!',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Mağazanız incelendikten sonra aktif edilecek. Genellikle 24 saat içinde sonuçlanır.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ),
      GoRoute(
        path: '/seller/dashboard',
        builder: (_, __) => const SellerDashboardScreen(),
      ),
    ],
  );
});

// GoRouter'ın akışı doğru dinlemesi için yardımcı sınıf
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) async {
      final user = authState.valueOrNull;
      final isAuth = user != null;

      // Auth ile ilgili rotalar
      final isOnAuth =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/register/user' ||
          state.matchedLocation == '/register/seller' ||
          state.matchedLocation == '/splash';

      // Giriş yapmamış kullanıcı ve korumalı bir sayfaya gitmeye çalışıyorsa
      // /home ve /product/:id misafirler için açık kalabilir
      final isPublicPage =
          state.matchedLocation == '/home' ||
          state.matchedLocation.startsWith('/product/');

      if (!isAuth && !isOnAuth && !isPublicPage) {
        return '/login';
      }

      // Giriş yapmış kullanıcıyı login/register sayfalarından uzaklaştır
      if (isAuth && isOnAuth && state.matchedLocation != '/splash') {
        return '/home'; // Veya Splash içindeki rol kontrolüne bırakılabilir
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

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Auth Ekranları
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/user_register_screen.dart';
import '../../features/auth/presentation/seller_register_screen.dart';
import '../../features/auth/providers/auth_providers.dart';

// Özellik Ekranları
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/presentation/product_detail_screen.dart';
import '../../features/cart/presentation/cart_screen.dart';
import '../../features/cart/presentation/checkout_screen.dart';
import '../../features/orders/presentation/orders_screen.dart';
import '../../features/orders/presentation/order_detail_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';

// AI & Fridge & Notifications Ekranları
import '../../features/ai/presentation/ai_assistant_screen.dart';
import '../../features/ai/presentation/barcode_scanner_screen.dart';
import '../../features/ai/presentation/recipe_scan_screen.dart';
import '../../features/fridge/presentation/fridge_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';

// Satıcı Ekranları
import '../../features/seller/presentation/seller_dashboard_screen.dart';
import '../../features/seller/presentation/seller_orders_screen.dart';
import '../../features/seller/presentation/seller_product_list_screen.dart';
import '../../features/seller/presentation/seller_add_product_screen.dart';
import '../../features/seller/presentation/seller_campaigns_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(
      Stream.fromFuture(ref.watch(authStateProvider.future)),
    ),
    redirect: (context, state) async {
      final user = FirebaseAuth.instance.currentUser;
      final isAuth = user != null;
      final String currentLoc = state.matchedLocation;

      final isOnAuth =
          currentLoc == '/login' ||
          currentLoc == '/register' ||
          currentLoc == '/register/user' ||
          currentLoc == '/register/seller' ||
          currentLoc == '/splash';

      final isPublicPage =
          currentLoc == '/home' || currentLoc.startsWith('/product/');

      if (!isAuth && !isOnAuth && !isPublicPage) {
        return '/login';
      }

      if (isAuth && !isOnAuth) {
        return null;
      }

      if (isAuth && isOnAuth && currentLoc != '/splash') {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(
        path: '/product/:id',
        builder:
            (_, state) =>
                ProductDetailScreen(productId: state.pathParameters['id']!),
      ),

      // --- AI & Buzdolabı & Bildirimler ---
      GoRoute(
        path: '/ai/chat',
        builder: (_, state) {
          final isSeller = state.uri.queryParameters['seller'] == 'true';
          return AiAssistantScreen(isSellerMode: isSeller);
        },
      ),
      GoRoute(
        path: '/ai/barcode',
        builder: (_, __) => const BarcodeScannerScreen(),
      ),
      GoRoute(path: '/ai/recipe', builder: (_, __) => const RecipeScanScreen()),
      GoRoute(path: '/fridge', builder: (_, __) => const FridgeScreen()),
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationsScreen(),
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

      // --- Satıcı (Seller) Rotaları ---
      GoRoute(
        path: '/seller/dashboard',
        builder: (_, __) => const SellerDashboardScreen(),
      ),
      GoRoute(
        path: '/seller/orders',
        builder: (_, __) => const SellerOrdersScreen(),
      ),
      GoRoute(
        path: '/seller/products',
        builder: (_, __) => const SellerProductListScreen(),
      ),
      GoRoute(
        path: '/seller/products/add',
        builder: (_, __) => const SellerAddProductScreen(),
      ),
      GoRoute(
        path: '/seller/campaigns',
        builder: (_, __) => const SellerCampaignsScreen(),
      ),
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
                        'Mağazanız incelendikten sonra aktif edilecek.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ),
    ],
  );
});

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

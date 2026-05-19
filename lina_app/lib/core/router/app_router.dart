import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lina/features/notifications/presentation/notifications_screen.dart';

// Auth & Home
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/user_register_screen.dart';
import '../../features/auth/presentation/seller_register_screen.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/presentation/product_detail_screen.dart';

// Diğer Özellikler
import '../../features/cart/presentation/cart_screen.dart';
import '../../features/cart/presentation/checkout_screen.dart';
import '../../features/orders/presentation/orders_screen.dart';
import '../../features/orders/presentation/order_detail_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/ai/presentation/ai_assistant_screen.dart';
import '../../features/ai/presentation/barcode_scanner_screen.dart';
import '../../features/ai/presentation/recipe_scan_screen.dart';
import '../../features/fridge/presentation/fridge_screen.dart';
import '../../features/reviews/presentation/reviews_screen.dart';

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
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final isAuth = user != null;
      final currentLoc = state.matchedLocation;
      final isOnAuth = [
        '/login',
        '/register',
        '/register/user',
        '/register/seller',
        '/splash',
      ].contains(currentLoc);

      if (!isAuth && !isOnAuth && !currentLoc.startsWith('/product/'))
        return '/login';
      if (isAuth && isOnAuth && currentLoc != '/splash') return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/register/user',
        builder: (_, __) => const UserRegisterScreen(),
      ),
      GoRoute(
        path: '/register/seller',
        builder: (_, __) => const SellerRegisterScreen(),
      ),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(
        path: '/product/:id',
        builder:
            (_, state) =>
                ProductDetailScreen(productId: state.pathParameters['id']!),
      ),

      // Bildirimler ve Yorumlar
      GoRoute(
        path: '/notifications',
        builder: (_, __) => NotificationsScreen(),
      ),
      GoRoute(
        path: '/reviews/:productId',
        builder:
            (_, state) =>
                ReviewsScreen(productId: state.pathParameters['productId']!),
      ),

      // AI & Araçlar
      GoRoute(
        path: '/ai/chat',
        builder:
            (_, state) => AiAssistantScreen(
              isSellerMode: state.uri.queryParameters['seller'] == 'true',
            ),
      ),
      GoRoute(
        path: '/ai/barcode',
        builder: (_, __) => const BarcodeScannerScreen(),
      ),
      GoRoute(path: '/ai/recipe', builder: (_, __) => const RecipeScanScreen()),

      // Kullanıcı & Alışveriş
      GoRoute(path: '/fridge', builder: (_, __) => const FridgeScreen()),
      GoRoute(path: '/cart', builder: (_, __) => const CartScreen()),
      GoRoute(path: '/checkout', builder: (_, __) => const CheckoutScreen()),
      GoRoute(path: '/orders', builder: (_, __) => const OrdersScreen()),
      GoRoute(
        path: '/orders/:id',
        builder:
            (_, state) =>
                OrderDetailScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),

      // Satıcı Rotaları
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
        path: '/seller/add-product',
        builder: (_, __) => const SellerAddProductScreen(),
      ),
      GoRoute(
        path: '/seller/campaigns',
        builder: (_, __) => const SellerCampaignsScreen(),
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

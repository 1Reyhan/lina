import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Auth Ekranları
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/user_register_screen.dart'; // Yeni eklendi
import '../../features/auth/presentation/seller_register_screen.dart';

// Diğer Özellik Ekranları
import '../../features/home/presentation/home_screen.dart';
import '../../features/seller/presentation/seller_dashboard_screen.dart';
import '../../features/auth/providers/auth_providers.dart';

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
      // Not: /home sayfasını misafir girişi için açık bıraktığımızdan onuisOnAuth gibi düşünebiliriz
      if (!isAuth && !isOnAuth && state.matchedLocation != '/home') {
        return '/login';
      }

      // Giriş yapmış kullanıcı login/register sayfalarındaysa (Splash hariç) ana akışa dön
      if (isAuth && isOnAuth && state.matchedLocation != '/splash') {
        return null; // Yönlendirme kararını Splash Screen içindeki rol kontrolü versin
      }

      return null;
    },
    routes: [
      // Temel Rotalar
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),

      // Kayıt Akışı Rotaları
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/register/user',
        builder: (_, __) => const UserRegisterScreen(),
      ),
      GoRoute(
        path: '/register/seller',
        builder: (_, __) => const SellerRegisterScreen(),
      ),

      // Onay Bekleme Sayfası (Geçici UI)
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
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Mağazanız incelendikten sonra aktif edilecek. '
                        'Genellikle 24 saat içinde sonuçlanır.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ),

      // Satıcı Dashboard
      GoRoute(
        path: '/seller/dashboard',
        builder: (_, __) => const SellerDashboardScreen(),
      ),
    ],
  );
});

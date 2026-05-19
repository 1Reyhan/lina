import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'core/router/app_router.dart';

void main() async {
  // Flutter binding'ini başlat
  WidgetsFlutterBinding.ensureInitialized();

  // .env dosyasını yükle (API anahtarları için gerekli)
  await dotenv.load(fileName: '.env');

  // Firebase'i yapılandır
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Uygulamayı ProviderScope ile sararak başlat
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Router sağlayıcısını izle
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Lina',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}

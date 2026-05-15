import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Kullanıcının giriş durumunu dinliyoruz
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('lina'),
        actions: [
          // Kullanıcı giriş yapmışsa çıkış butonu, yapmamışsa giriş butonu göster
          user != null
              ? IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await ref.read(authRepositoryProvider).signOut();
                  // Çıkış yapınca login'e değil, yine home'a (misafir haline) dönsün
                  if (context.mounted) context.go('/splash');
                },
              )
              : TextButton(
                onPressed: () => context.go('/login'),
                child: const Text(
                  'Giriş Yap',
                  style: TextStyle(color: Colors.black),
                ),
              ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Ana Sayfa — Ürünler Burada Listelenecek'),
            const SizedBox(height: 20),
            // Misafir kullanıcı için bir uyarı veya yönlendirme kartı
            if (user == null)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Alışverişe başlamak veya satış yapmak için giriş yapmalısınız.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import 'package:go_router/go_router.dart';

class SellerDashboardScreen extends ConsumerWidget {
  const SellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lina Satıcı Paneli'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) context.go('/splash');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hoş Geldiniz!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Mağazanız şu an aktif ve satışa hazır.',
              style: TextStyle(color: Colors.green),
            ),
            const SizedBox(height: 24),

            // AI Araçları Bölümü (Aşama 4 Vizyonu)
            const Text(
              'AI Araçları',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              title: 'AI Katalog Mimarı',
              subtitle: 'Fotoğraf çekin, AI ürününüzü hazırlasın.',
              icon: Icons.auto_awesome,
              onTap: () {}, // Aşama 4'te doldurulacak
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              title: 'Talep Isı Haritası',
              subtitle: 'Bölgenizdeki trendleri analiz edin.',
              icon: Icons.map_outlined,
              onTap: () {}, // Aşama 4'te doldurulacak
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.green, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

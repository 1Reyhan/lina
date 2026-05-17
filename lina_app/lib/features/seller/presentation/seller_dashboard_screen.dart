import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/seller_providers.dart';
import '../../../features/auth/providers/auth_providers.dart';
import 'widgets/dashboard_stat_card.dart';
import '../../../shared/models/order_model.dart'; // Modelimiz dahil edildi

class SellerDashboardScreen extends ConsumerWidget {
  const SellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sellerAsync = ref.watch(sellerProfileProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);
    final ordersAsync = ref.watch(sellerOrdersProvider);

    // Lina Premium lüks koyu lacivert marka rengi
    const Color premiumNavy = Color(0xFF041E31);

    return Scaffold(
      backgroundColor: const Color(
        0xFFF8FAFC,
      ), // Modern, açık kurumsal arka plan rengi
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        // AppBar altındaki ayraç çizgisine asil lacivert tonu yedirildi
        shape: Border(
          bottom: BorderSide(color: premiumNavy.withAlpha(35), width: 1),
        ),
        title: sellerAsync.when(
          data:
              (s) => Text(
                s?.storeName ?? 'Yönetim Paneli',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  fontFamily: 'Nunito',
                  color: premiumNavy, // Başlık asil lüks lacivert yapıldı
                ),
              ),
          loading:
              () => const Text(
                'Yükleniyor...',
                style: TextStyle(fontFamily: 'Nunito', color: premiumNavy),
              ),
          error:
              (_, __) => const Text(
                'Panel',
                style: TextStyle(fontFamily: 'Nunito', color: premiumNavy),
              ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: premiumNavy),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider);
          ref.invalidate(sellerOrdersProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. ONAY DURUM KONTROLÜ
              sellerAsync.when(
                data: (seller) {
                  if (seller != null && !seller.isApproved) {
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.hourglass_top_rounded,
                            color: Colors.amber.shade800,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Mağazanız admin onayı bekliyor. Onaylandıktan sonra ürün ekleyebilir ve satış yapabilirsiniz.',
                              style: TextStyle(
                                color: Colors.amber.shade900,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Nunito',
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox();
                },
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),

              // 2. İSTATİSTİK KARTLARI ALANI
              const Text(
                'Genel Özet',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: premiumNavy, // Bölüm başlığı asil renk yapıldı
                  fontFamily: 'Nunito',
                ),
              ),
              const SizedBox(height: 12),
              statsAsync.when(
                loading:
                    () => const SizedBox(
                      height: 100,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                error:
                    (e, _) => Text(
                      'İstatistikler yüklenemedi: $e',
                      style: const TextStyle(fontFamily: 'Nunito'),
                    ),
                data:
                    (stats) => GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio:
                          1.15, // Dikey taşmayı (RenderFlex Overflow) %100 engelleyen kusursuz oran
                      children: [
                        DashboardStatCard(
                          title: 'Günlük Kazanç',
                          value:
                              '₺${(stats['todayRevenue'] ?? 0).toStringAsFixed(0)}',
                          icon: Icons.monetization_on_outlined,
                          color: const Color(0xFF10B981),
                        ),
                        DashboardStatCard(
                          title: 'Bugünkü Sipariş',
                          value: '${stats['todayOrders'] ?? 0}',
                          icon: Icons.shopping_bag_outlined,
                          color: const Color(0xFF3B82F6),
                        ),
                        DashboardStatCard(
                          title: 'Bekleyen Sipariş',
                          value: '${stats['pendingOrders'] ?? 0}',
                          icon: Icons.pending_actions_rounded,
                          color: const Color(0xFFF59E0B),
                        ),
                        DashboardStatCard(
                          title: 'Aktif Ürünler',
                          value: '${stats['activeProducts'] ?? 0}',
                          icon: Icons.grid_view_rounded,
                          color: const Color(0xFF8B5CF6),
                        ),
                      ],
                    ),
              ),
              const SizedBox(height: 28),

              // 3. HIZLI İŞLEMLER BUTONLARI
              const Text(
                'Hızlı İşlemler',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: premiumNavy,
                  fontFamily: 'Nunito',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.add_to_photos_outlined,
                      label: 'Ürün Ekle',
                      color: const Color(0xFF10B981),
                      onTap: () => context.push('/seller/products/add'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.layers_outlined,
                      label: 'Ürünlerim',
                      color: const Color(0xFF3B82F6),
                      onTap: () => context.push('/seller/products'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.local_shipping_outlined,
                      label: 'Siparişler',
                      color: const Color(0xFFF59E0B),
                      onTap: () => context.push('/seller/orders'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.auto_awesome_outlined,
                      label: 'Kampanyalar',
                      color: const Color(0xFF8B5CF6),
                      onTap: () => context.push('/seller/campaigns'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // 4. SON SİPARİŞLER KATMANI
              const Text(
                'Son Siparişler',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: premiumNavy,
                  fontFamily: 'Nunito',
                ),
              ),
              const SizedBox(height: 12),
              ordersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Siparişler alınamadı: $e'),
                data: (orders) {
                  final recent = orders.take(3).toList();
                  if (recent.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: premiumNavy.withAlpha(
                            40,
                          ), // İnce asil koyu ayraç çizgisi
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'Henüz bir sipariş almadınız.',
                          style: TextStyle(
                            color: Colors.grey,
                            fontFamily: 'Nunito',
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children:
                        recent.map((o) => _RecentOrderTile(order: o)).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        backgroundColor: Colors.white,
        elevation: 8,
        surfaceTintColor: Colors.transparent,
        onDestinationSelected: (i) {
          switch (i) {
            case 1:
              context.push('/seller/orders');
              break;
            case 2:
              context.push('/seller/products');
              break;
            case 3:
              context.push('/seller/campaigns');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined, color: premiumNavy),
            selectedIcon: Icon(Icons.dashboard_rounded, color: premiumNavy),
            label: 'Panel',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined, color: premiumNavy),
            selectedIcon: Icon(Icons.receipt_long_rounded, color: premiumNavy),
            label: 'Siparişler',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined, color: premiumNavy),
            selectedIcon: Icon(Icons.inventory_2_rounded, color: premiumNavy),
            label: 'Ürünler',
          ),
          NavigationDestination(
            icon: Icon(Icons.campaign_outlined, color: premiumNavy),
            selectedIcon: Icon(Icons.campaign_rounded, color: premiumNavy),
            label: 'Kampanya',
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          // Aksiyon butonlarının kenar çizgilerine asil koyu lacivert soft bir geçiş olarak eklendi
          border: Border.all(color: const Color(0xFF041E31).withAlpha(25)),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFF041E31,
              ).withAlpha(6), // Koyu mavi bazlı yumuşak gölge
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontFamily: 'Nunito',
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentOrderTile extends StatelessWidget {
  final OrderModel order;
  const _RecentOrderTile({required this.order});

  static const _statusLabel = {
    'pending': 'Bekliyor',
    'confirmed': 'Onaylandı',
    'preparing': 'Hazırlanıyor',
    'shipped': 'Yolda',
    'delivered': 'Teslim Edildi',
    'cancelled': 'İptal',
  };

  static const _statusColor = {
    'pending': Colors.orange,
    'confirmed': Colors.blue,
    'preparing': Colors.purple,
    'shipped': Colors.teal,
    'delivered': Colors.green,
    'cancelled': Colors.red,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _statusColor[order.status] ?? Colors.grey;
    const Color premiumNavy = Color(0xFF041E31);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: premiumNavy.withAlpha(20),
        ), // İnce asil kenarlık
        boxShadow: [
          BoxShadow(
            color: premiumNavy.withAlpha(5),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sipariş #${order.orderId.length > 8 ? order.orderId.substring(0, 8).toUpperCase() : order.orderId}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        premiumNavy, // Sipariş ID başlığı asil lüks renk yapıldı
                    fontFamily: 'Nunito',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${order.items.length} Farklı Ürün',
                  style: TextStyle(
                    color: premiumNavy.withAlpha(120),
                    fontSize: 12,
                    fontFamily: 'Nunito',
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₺${order.totalAmount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF10B981),
              fontSize: 15,
              fontFamily: 'Nunito',
            ),
          ),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withAlpha(51)),
            ),
            child: Text(
              _statusLabel[order.status] ?? order.status,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                fontFamily: 'Nunito',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

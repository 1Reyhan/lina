import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/seller_providers.dart';
import '../../../features/auth/providers/auth_providers.dart';
import 'widgets/dashboard_stat_card.dart';
import '../../../shared/models/order_model.dart';

class SellerDashboardScreen extends ConsumerWidget {
  const SellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const _SellerDashboardView();
  }
}

class _SellerDashboardView extends ConsumerWidget {
  const _SellerDashboardView();

  // Lina Premium lüks koyu lacivert marka rengi
  static const Color premiumNavy = Color(0xFF041E31);
  static const Color premiumNavyLight = Color(0xFF0D324E);
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color infoBlue = Color(0xFF3B82F6);
  static const Color purpleTone = Color(0xFF8B5CF6);
  static const Color softBackground = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sellerAsync = ref.watch(sellerProfileProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);
    final ordersAsync = ref.watch(sellerOrdersProvider);

    return Scaffold(
      backgroundColor: softBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        shape: Border(
          bottom: BorderSide(color: premiumNavy.withAlpha(25), width: 1),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: premiumNavy.withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.storefront_rounded,
                color: premiumNavy,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: sellerAsync.when(
                data:
                    (s) => Text(
                      s?.storeName ?? 'Lina Mağaza',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Nunito',
                        fontSize: 18,
                        color: premiumNavy,
                        letterSpacing: -0.5,
                      ),
                    ),
                loading:
                    () => const Text(
                      'Yükleniyor...',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        color: premiumNavy,
                        fontSize: 16,
                      ),
                    ),
                error:
                    (_, __) => const Text(
                      'Yönetim Paneli',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        color: premiumNavy,
                        fontSize: 16,
                      ),
                    ),
              ),
            ),
          ],
        ),
        actions: [
          // LINA AI İkonunu buraya ekledik:
          GestureDetector(
            onTap: () => context.push('/ai/chat?seller=true'),
            child: Padding(
              padding: const EdgeInsets.only(
                right: 12,
              ), // Diğer ikonlarla hizalı olması için
              child: Image.asset(
                'assets/images/lina.ai.png', // Dosya yolunun doğru olduğundan emin ol
                width: 32,
                height: 32,
              ),
            ),
          ),

          // Bildirim Butonu
          Container(
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: premiumNavy.withAlpha(10),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: premiumNavy,
                size: 22,
              ),
              onPressed: () {},
            ),
          ),

          // Çıkış Butonu
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: dangerRed.withAlpha(
                25,
              ), // Alpha değerini biraz artırdım daha hoş görünür
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.logout_rounded,
                color: dangerRed,
                size: 20,
              ),
              tooltip: 'Çıkış Yap',
              onPressed:
                  () => _showLogoutDialog(context, ref), // Diyaloğu çağırıyor
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: premiumNavy,
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
              // 1. ADMİN ONAY DURUM KONTROLÜ
              sellerAsync.when(
                data: (seller) {
                  if (seller != null && !seller.isApproved) {
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: warningOrange.withAlpha(15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: warningOrange.withAlpha(50),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.hourglass_top_rounded,
                            color: warningOrange,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Mağazanız admin onayı bekliyor. Onaylandıktan sonra ürün ekleyebilir ve satış yapabilirsiniz.',
                              style: TextStyle(
                                color: warningOrange.withAlpha(240),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
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

              // Lüks Karşılama Kartı (Hero Banner)
              _buildWelcomeBanner(sellerAsync),
              const SizedBox(height: 24),

              // 2. İSTATİSTİK KARTLARI ALANI
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: premiumNavy,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Genel Özet',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: premiumNavy,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              statsAsync.when(
                loading:
                    () => const SizedBox(
                      height: 100,
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            premiumNavy,
                          ),
                        ),
                      ),
                    ),
                error:
                    (e, _) => Text(
                      'İstatistikler yüklenemedi: $e',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        color: dangerRed,
                      ),
                    ),
                data:
                    (stats) => GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.15,
                      children: [
                        // Kartları force-border (net asil mavi çerçeve) ile sarmaladık
                        _buildDecoratedStatCard(
                          child: DashboardStatCard(
                            title: 'Günlük Kazanç',
                            value:
                                '₺${(stats['todayRevenue'] ?? 0).toStringAsFixed(0)}',
                            icon: Icons.monetization_on_outlined,
                            color: successGreen,
                          ),
                        ),
                        _buildDecoratedStatCard(
                          child: DashboardStatCard(
                            title: 'Bugünkü Sipariş',
                            value: '${stats['todayOrders'] ?? 0}',
                            icon: Icons.shopping_bag_outlined,
                            color: infoBlue,
                          ),
                        ),
                        _buildDecoratedStatCard(
                          child: DashboardStatCard(
                            title: 'Bekleyen Sipariş',
                            value: '${stats['pendingOrders'] ?? 0}',
                            icon: Icons.pending_actions_rounded,
                            color: warningOrange,
                          ),
                        ),
                        _buildDecoratedStatCard(
                          child: DashboardStatCard(
                            title: 'Aktif Ürünler',
                            value: '${stats['activeProducts'] ?? 0}',
                            icon: Icons.grid_view_rounded,
                            color: purpleTone,
                          ),
                        ),
                      ],
                    ),
              ),
              const SizedBox(height: 28),

              // 3. HIZLI İŞLEMLER BUTONLARI
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: premiumNavy,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Hızlı İşlemler',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: premiumNavy,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.add_to_photos_outlined,
                      label: 'Ürün Ekle',
                      color: successGreen,
                      onTap: () => context.push('/seller/add-product'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.layers_outlined,
                      label: 'Ürünlerim',
                      color: infoBlue,
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
                      color: warningOrange,
                      onTap: () => context.push('/seller/orders'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.auto_awesome_outlined,
                      label: 'Kampanyalar',
                      color: purpleTone,
                      onTap: () => context.push('/seller/campaigns'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // 4. SON SİPARİŞLER KATMANI
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: premiumNavy,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Son Siparişler',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: premiumNavy,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ordersAsync.when(
                loading:
                    () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            premiumNavy,
                          ),
                        ),
                      ),
                    ),
                error:
                    (e, _) => Text(
                      'Siparişler alınamadı: $e',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        color: dangerRed,
                      ),
                    ),
                data: (orders) {
                  final recent = orders.take(3).toList();
                  if (recent.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: premiumNavy.withAlpha(
                            80,
                          ), // Net asil koyu mavi kenarlık
                          width: 1.5,
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
        shadowColor: premiumNavy.withAlpha(100),
        surfaceTintColor: Colors.transparent,
        indicatorColor: premiumNavy.withAlpha(20),
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

  // Dashboard Stat Card'ları net çerçeveyle çevreleyen metot
  Widget _buildDecoratedStatCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: premiumNavy.withAlpha(
            80,
          ), // Net asil koyu mavi kenarlık (belirginleştirildi)
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(16), child: child),
    );
  }

  // Karşılama Kartı Tasarımı
  Widget _buildWelcomeBanner(AsyncValue<dynamic> sellerAsync) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [premiumNavy, premiumNavyLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: premiumNavy.withAlpha(35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lina Satıcı Portalı',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: successGreen,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          sellerAsync.when(
            data:
                (s) => Text(
                  'Tekrar Hoş Geldiniz,\n${s?.storeName ?? 'Değerli Ortağımız'} 👋',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
            loading:
                () => const Text(
                  'Yükleniyor...',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
            error:
                (_, __) => const Text(
                  'Tekrar Hoş Geldiniz!',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Mağazanızın durumunu ve siparişlerinizi anlık olarak buradan takip edebilirsiniz.',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Oturumu Kapat',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
                color: premiumNavy,
              ),
            ),
            content: const Text(
              'Lina dünyasından çıkış yapmak istediğinize emin misiniz?',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w500,
                color: premiumNavy,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => context.pop(),
                child: const Text(
                  'İptal',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Çıkış mantığı (Burada authRepositoryProvider kullandığını gördüm)
                  await ref.read(authRepositoryProvider).signOut();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: dangerRed,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Çıkış Yap',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
    const Color premiumNavy = Color(0xFF041E31);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          // Hızlı işlemler kartlarının çevresi belirginleştirildi (width: 1.5, withAlpha: 80)
          border: Border.all(color: premiumNavy.withAlpha(80), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: premiumNavy.withAlpha(8),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                color: premiumNavy,
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

  static const Color premiumNavy = Color(0xFF041E31);
  static const Color successGreen = Color(0xFF10B981);

  @override
  Widget build(BuildContext context) {
    final color = _statusColor[order.status] ?? Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        // Son siparişler kartlarının çevresi belirginleştirildi (width: 1.5, withAlpha: 80)
        border: Border.all(color: premiumNavy.withAlpha(80), width: 1.5),
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
                    color: premiumNavy,
                    fontFamily: 'Nunito',
                  ),
                ),
                const SizedBox(height: 4),
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
              color: successGreen,
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

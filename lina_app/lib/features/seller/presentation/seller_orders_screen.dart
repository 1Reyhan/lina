import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/seller_providers.dart';
import '../../../shared/models/order_model.dart';
import 'widgets/order_status_dropdown.dart';

class SellerOrdersScreen extends ConsumerStatefulWidget {
  const SellerOrdersScreen({super.key});

  @override
  ConsumerState<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends ConsumerState<SellerOrdersScreen> {
  // Seçili olan durum filtresi ("Tümü" varsayılan gelir)
  String _selectedStatusFilter = 'Tümü';

  // Marka renk kodları (Lina Premium Tasarım Dili)
  static const Color premiumNavy = Color(0xFF041E31);
  static const Color premiumNavyLight = Color(0xFF0D324E);
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color infoBlue = Color(0xFF3B82F6);
  static const Color softBackground = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ordersAsync = ref.watch(sellerOrdersProvider);

    return Scaffold(
      backgroundColor: softBackground,
      appBar: AppBar(
        title: const Text(
          'Sipariş Yönetimi',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontFamily: 'Nunito',
            fontSize: 22,
            color: premiumNavy,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        shape: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withAlpha(50),
            width: 1,
          ),
        ),
      ),
      body: ordersAsync.when(
        loading:
            () => const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(premiumNavy),
              ),
            ),
        error:
            (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 60,
                      color: dangerRed,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Siparişler yüklenirken hata oluştu:\n$e',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: premiumNavy,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        data: (orders) {
          if (orders.isEmpty) {
            return _buildEmptyState();
          }

          // Durum filtrelerine göre filtreleme mantığı
          final filteredOrders =
              orders.where((order) {
                if (_selectedStatusFilter == 'Tümü') return true;
                if (_selectedStatusFilter == 'Bekleyenler')
                  return order.status == 'pending';
                if (_selectedStatusFilter == 'Hazırlananlar') {
                  return order.status == 'confirmed' ||
                      order.status == 'preparing';
                }
                if (_selectedStatusFilter == 'Kargoda')
                  return order.status == 'shipped';
                if (_selectedStatusFilter == 'Tamamlananlar')
                  return order.status == 'delivered';
                if (_selectedStatusFilter == 'İptaller')
                  return order.status == 'cancelled';
                return true;
              }).toList();

          // Analiz sayaçları
          final pendingCount =
              orders.where((o) => o.status == 'pending').length;
          final preparingCount =
              orders
                  .where(
                    (o) => o.status == 'confirmed' || o.status == 'preparing',
                  )
                  .length;
          final completedCount =
              orders.where((o) => o.status == 'delivered').length;

          return Column(
            children: [
              // 1. Üst Kısım: Premium Sipariş Dashboard Analizi
              _buildStatsDashboard(
                pendingCount,
                preparingCount,
                completedCount,
              ),

              // 2. Sipariş Filtreleme Sekmeleri
              _buildFilterTabs(),

              // 3. Sipariş Listesi
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child:
                      filteredOrders.isEmpty
                          ? _buildNoFilteredOrdersState()
                          : ListView.separated(
                            key: ValueKey('orders_list_$_selectedStatusFilter'),
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: filteredOrders.length,
                            physics: const BouncingScrollPhysics(),
                            separatorBuilder:
                                (_, __) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final order = filteredOrders[index];
                              return _buildOrderCard(context, order);
                            },
                          ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Sipariş İstatistik Paneli
  Widget _buildStatsDashboard(int pending, int preparing, int completed) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [premiumNavy, premiumNavyLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: premiumNavy.withAlpha(30),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Yeni / Bekleyen',
            pending.toString(),
            Icons.pending_actions_rounded,
            warningOrange,
          ),
          Container(height: 24, width: 1, color: Colors.white24),
          _buildStatItem(
            'Hazırlananlar',
            preparing.toString(),
            Icons.soup_kitchen_rounded,
            infoBlue,
          ),
          Container(height: 24, width: 1, color: Colors.white24),
          _buildStatItem(
            'Teslim Edilen',
            completed.toString(),
            Icons.task_alt_rounded,
            successGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String title,
    String val,
    IconData icon,
    Color badgeColor,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: badgeColor.withAlpha(35),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: badgeColor, size: 18),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              val,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Sipariş Durumu Sekmeleri (Yatay Kaydırılabilir)
  Widget _buildFilterTabs() {
    final filters = [
      'Tümü',
      'Bekleyenler',
      'Hazırlananlar',
      'Kargoda',
      'Tamamlananlar',
      'İptaller',
    ];

    return SizedBox(
      height: 60,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedStatusFilter == filter;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedStatusFilter = filter;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 2,
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? premiumNavy : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? premiumNavy : premiumNavy.withAlpha(30),
                    width: 1.5,
                  ),
                  boxShadow:
                      isSelected
                          ? [
                            BoxShadow(
                              color: premiumNavy.withAlpha(40),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ]
                          : null,
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isSelected ? Colors.white : premiumNavy,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Premium Sipariş Kartı Tasarımı
  Widget _buildOrderCard(BuildContext context, OrderModel order) {
    // Sipariş durumuna göre renk ve metin belirleme
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (order.status) {
      case 'pending':
        statusColor = warningOrange;
        statusText = 'Beklemede';
        statusIcon = Icons.access_time_rounded;
        break;
      case 'confirmed':
        statusColor = infoBlue;
        statusText = 'Onaylandı';
        statusIcon = Icons.thumb_up_alt_rounded;
        break;
      case 'preparing':
        statusColor = premiumNavy;
        statusText = 'Hazırlanıyor';
        statusIcon = Icons.soup_kitchen_rounded;
        break;
      case 'shipped':
        statusColor = Colors.purple;
        statusText = 'Kargoda';
        statusIcon = Icons.local_shipping_rounded;
        break;
      case 'delivered':
        statusColor = successGreen;
        statusText = 'Teslim Edildi';
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'cancelled':
        statusColor = dangerRed;
        statusText = 'İptal Edildi';
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = premiumNavy;
        statusText = 'Bilinmiyor';
        statusIcon = Icons.help_outline_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: premiumNavy.withAlpha(20), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: premiumNavy.withAlpha(12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Row(
            children: [
              // Sol Kısım: Sipariş No & Tarih
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sipariş #${order.orderId.length > 8 ? order.orderId.substring(0, 8).toUpperCase() : order.orderId}',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: premiumNavy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDateTime(order.createdAt),
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        color: premiumNavy.withAlpha(120),
                      ),
                    ),
                  ],
                ),
              ),

              // Sağ Kısım: Durum Rozeti (Badge)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: statusColor.withAlpha(60),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  size: 14,
                  color: premiumNavy.withAlpha(120),
                ),
                const SizedBox(width: 4),
                Text(
                  '${order.items.length} Kalem Ürün',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    color: premiumNavy.withAlpha(150),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '₺${order.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: successGreen,
                  ),
                ),
              ],
            ),
          ),
          children: [
            const Divider(color: Color(0xFFF1F5F9), height: 16),

            // Ürünler Listesi Konteyneri
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: softBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children:
                    order.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: premiumNavy.withAlpha(15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'x${item.quantity}',
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: premiumNavy,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: premiumNavy,
                                    ),
                                  ),
                                  // HATA ÇÖZÜLDÜ: CartItemModel üzerinde 'unit' alanı bulunmadığı için
                                  // bu kısımdaki birim sorgusu kaldırılarak derleyici hatası sıfırlandı.
                                ],
                              ),
                            ),
                            Text(
                              '₺${item.price.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 13,
                                color: premiumNavy.withAlpha(180),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              ),
            ),

            const SizedBox(height: 12),

            // Teslimat Adresi
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: premiumNavy,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Teslimat Adresi',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: premiumNavy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.deliveryAddress['address'] ??
                            'Adres Belirtilmemiş',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 13,
                          color: premiumNavy.withAlpha(150),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Varsa Müşteri Notu
            if (order.deliveryNote.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: dangerRed.withAlpha(10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: dangerRed.withAlpha(25), width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.note_alt_outlined,
                      size: 16,
                      color: dangerRed,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Müşteri Notu: ${order.deliveryNote}',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          color: dangerRed.withAlpha(220),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Divider(color: Color(0xFFF1F5F9), height: 24),

            // Ödeme Yöntemi ve Güncelleme Alanı
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Ödeme Tipi
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ödeme: ${order.paymentMethod.replaceAll('_', ' ').toUpperCase()}',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: premiumNavy.withAlpha(140),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ödeme Durumu: ${order.paymentStatus == 'paid' ? 'Ödendi' : 'Beklemede'}',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color:
                            order.paymentStatus == 'paid'
                                ? successGreen
                                : warningOrange,
                      ),
                    ),
                  ],
                ),

                // Sipariş Durumu Değiştirme (Dropdown)
                OrderStatusDropdown(
                  current: order.status,
                  onChanged: (status) async {
                    try {
                      await ref
                          .read(sellerOrderRepositoryProvider)
                          .updateOrderStatus(order.orderId, status);

                      ref.invalidate(sellerOrdersProvider);
                      ref.invalidate(dashboardStatsProvider);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Durum güncellenemedi: $e',
                              style: const TextStyle(fontFamily: 'Nunito'),
                            ),
                            backgroundColor: dangerRed,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),

            // Hızlı Durum İlerleme Butonları (Kullanışlılık Kısayolu)
            if (order.status == 'pending' ||
                order.status == 'confirmed' ||
                order.status == 'preparing') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    String nextStatus = 'confirmed';
                    String message = 'Sipariş onaylandı!';
                    if (order.status == 'confirmed') {
                      nextStatus = 'preparing';
                      message = 'Sipariş hazırlanıyor!';
                    } else if (order.status == 'preparing') {
                      nextStatus = 'shipped';
                      message = 'Sipariş yola çıktı!';
                    }

                    try {
                      await ref
                          .read(sellerOrderRepositoryProvider)
                          .updateOrderStatus(order.orderId, nextStatus);

                      ref.invalidate(sellerOrdersProvider);
                      ref.invalidate(dashboardStatsProvider);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              message,
                              style: const TextStyle(fontFamily: 'Nunito'),
                            ),
                            backgroundColor: successGreen,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Hata: $e',
                              style: const TextStyle(fontFamily: 'Nunito'),
                            ),
                            backgroundColor: dangerRed,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: Text(
                    order.status == 'pending'
                        ? 'Siparişi Onayla ve İşleme Al'
                        : (order.status == 'confirmed'
                            ? 'Siparişi Hazırlamaya Başla'
                            : 'Kuryeye Ver / Yola Çıkar'),
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        order.status == 'pending' ? successGreen : premiumNavy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Tarih Biçimlendirme Yardımcı Metodu
  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} - ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  // Filtreleme Sonucunda Eşleşen Sipariş Bulunamadıysa
  Widget _buildNoFilteredOrdersState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: premiumNavy.withAlpha(50),
          ),
          const SizedBox(height: 16),
          Text(
            '$_selectedStatusFilter kategorisinde sipariş yok.',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: premiumNavy.withAlpha(120),
            ),
          ),
        ],
      ),
    );
  }

  // Hiç Sipariş Alınmamış Boş Ekran Tasarımı
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: premiumNavy.withAlpha(12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 80,
                color: premiumNavy,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sipariş Bulunmuyor',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: premiumNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Müşterileriniz mağazanızdan alışveriş yaptığında siparişler anında bu ekrana düşecektir.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                color: premiumNavy.withAlpha(130),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

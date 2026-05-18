import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/order_providers.dart';
import '../../../shared/models/order_model.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  // Şemadaki durumlara uygun etiketler
  static const _statusLabel = {
    'pending': 'Onay Bekliyor',
    'confirmed': 'Hazırlanıyor',
    'preparing': 'Paketleniyor',
    'shipped': 'Kuryede',
    'delivered': 'Teslim Edildi',
    'cancelled': 'İptal Edildi',
  };

  // Duruma göre profesyonel premium renk paleti
  static const _statusColor = {
    'pending': Colors.orange,
    'confirmed': Colors.blue,
    'preparing': Colors.purple,
    'shipped': Colors.teal,
    'delivered': Color(0xFF10B981), // Lina Başarı Yeşili
    'cancelled': Colors.red,
  };

  static const Color premiumNavy = Color(0xFF041E31);
  static const Color softBackground = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(userOrdersProvider);

    return Scaffold(
      backgroundColor: softBackground,
      appBar: AppBar(
        title: const Text(
          'Siparişlerim',
          style: TextStyle(
            color: premiumNavy,
            fontWeight: FontWeight.bold,
            fontFamily: 'Nunito',
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: premiumNavy),
        shape: Border(
          bottom: BorderSide(
            color: premiumNavy.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      body: ordersAsync.when(
        loading:
            () => const Center(
              child: CircularProgressIndicator(color: premiumNavy),
            ),
        error:
            (e, _) => Center(
              child: Text(
                'Hata oluştu: $e',
                style: const TextStyle(fontFamily: 'Nunito'),
              ),
            ),
        data: (orders) {
          if (orders.isEmpty) {
            return _buildEmptyOrders(context);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (_, i) {
              final order = orders[i];
              return _OrderCard(order: order);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyOrders(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: premiumNavy.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 16),
            const Text(
              'Henüz bir siparişiniz bulunmuyor',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Nunito',
                color: premiumNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Lina\'nın taze ve organik dünyasını keşfetmeye ne dersiniz?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'Nunito',
                color: premiumNavy.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: premiumNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Keşfetmeye Başla',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

  static const Color premiumNavy = Color(0xFF041E31);

  @override
  Widget build(BuildContext context) {
    final statusColor = OrdersScreen._statusColor[order.status] ?? Colors.grey;
    final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(order.createdAt);

    return GestureDetector(
      onTap: () => context.push('/orders/${order.orderId}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: premiumNavy.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: premiumNavy.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sipariş #${order.orderId.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        color: premiumNavy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: TextStyle(
                        color: premiumNavy.withValues(alpha: 0.5),
                        fontSize: 12,
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                _buildStatusBadge(statusColor),
              ],
            ),
            const Divider(height: 24, thickness: 0.8),

            // Ürün Resim Önizlemeleri Alanı (Kırmızı Çarpı Hatası ve Taşmayı Önleyen Akıllı Yapı)
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: order.items.length,
                itemBuilder: (context, index) {
                  final item = order.items[index];
                  final bool hasImg = item.image.isNotEmpty;
                  final bool isNet =
                      hasImg &&
                      (item.image.startsWith('http://') ||
                          item.image.startsWith('https://'));
                  final bool isLoc =
                      hasImg &&
                      (item.image.startsWith('file://') ||
                          item.image.startsWith('/') ||
                          item.image.contains('data/user/'));

                  return Container(
                    width: 50,
                    height: 50,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: premiumNavy.withValues(alpha: 0.08),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child:
                          isNet
                              ? Image.network(
                                item.image,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _shimmerMini(),
                              )
                              : isLoc
                              ? Image.file(
                                File(item.image.replaceFirst('file://', '')),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _shimmerMini(),
                              )
                              : _shimmerMini(),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 24, thickness: 0.8),
            Row(
              children: [
                const Icon(
                  Icons.shopping_bag_outlined,
                  size: 16,
                  color: premiumNavy,
                ),
                const SizedBox(width: 8),
                Text(
                  '${order.items.fold(0, (sum, i) => sum + i.quantity)} Ürün',
                  style: const TextStyle(
                    fontSize: 13,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                    color: premiumNavy,
                  ),
                ),
                const Spacer(),
                Text(
                  '₺${order.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: premiumNavy.withValues(alpha: 0.4),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order.deliveryAddress['address'] ?? 'Adres belirtilmemiş',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: premiumNavy.withValues(alpha: 0.6),
                      fontSize: 12,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 11,
                  color: premiumNavy.withValues(alpha: 0.4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        OrdersScreen._statusLabel[order.status] ?? order.status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontFamily: 'Nunito',
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _shimmerMini() {
    return Container(
      color: premiumNavy,
      child: const Center(
        child: Icon(Icons.spa_rounded, size: 14, color: Colors.white24),
      ),
    );
  }
}

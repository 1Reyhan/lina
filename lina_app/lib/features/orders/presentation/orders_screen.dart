import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart'; // Tarih formatlamak için (pubspec.yaml'a eklemelisin)
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

  // Duruma göre profesyonel renk paleti
  static const _statusColor = {
    'pending': Colors.orange,
    'confirmed': Colors.blue,
    'preparing': Colors.purple,
    'shipped': Colors.teal,
    'delivered': Colors.green,
    'cancelled': Colors.red,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(userOrdersProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Siparişlerim',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata oluştu: $e')),
        data: (orders) {
          if (orders.isEmpty) {
            return _buildEmptyOrders(context);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'Henüz bir siparişiniz bulunmuyor',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/home'),
            child: const Text('Keşfetmeye Başla'),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

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
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 10,
              offset: const Offset(0, 4),
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
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                _buildStatusBadge(statusColor),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(
                  Icons.shopping_bag_outlined,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  '${order.items.length} Ürün',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  '₺${order.totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
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
                  color: Colors.grey.shade400,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order.deliveryAddress['address'] ?? 'Adres belirtilmemiş',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: Colors.grey.shade400,
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
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        OrdersScreen._statusLabel[order.status] ?? order.status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

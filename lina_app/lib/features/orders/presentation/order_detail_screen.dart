import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/order_providers.dart';
import '../../../shared/models/order_model.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  static const _steps = [
    'pending',
    'confirmed',
    'preparing',
    'shipped',
    'delivered',
  ];
  static const _stepLabel = [
    'Bekliyor',
    'Onaylandı',
    'Hazırlanıyor',
    'Yolda',
    'Teslim Edildi',
  ];
  static const _stepIcon = [
    Icons.hourglass_top,
    Icons.check_circle_outline,
    Icons.inventory_2_outlined,
    Icons.local_shipping_outlined,
    Icons.home_outlined,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Sipariş Takibi',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (order) {
          if (order == null)
            return const Center(child: Text('Sipariş bulunamadı'));

          final stepIdx = _steps.indexOf(order.status);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 1. Durum Takip Paneli (Stepper)
                _buildStepper(stepIdx, order.status == 'cancelled'),
                const SizedBox(height: 16),

                // 2. Sipariş Bilgileri Kartı
                _buildInfoCard(order),
                const SizedBox(height: 12),

                // 3. Ürünler Listesi
                _buildItemsCard(order),
                const SizedBox(height: 12),

                // 4. Teslimat Adresi
                _buildAddressCard(order),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStepper(int currentStep, bool isCancelled) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          if (isCancelled)
            const Text(
              'SİPARİŞ İPTAL EDİLDİ',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            )
          else
            Row(
              children: List.generate(_steps.length, (i) {
                final isDone = i <= currentStep;
                return Expanded(
                  child: Column(
                    children: [
                      // İkon ve Bağlantı Çizgisi
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color:
                                  i == 0
                                      ? Colors.transparent
                                      : (isDone
                                          ? Colors.green
                                          : Colors.grey.shade300),
                              thickness: 2,
                            ),
                          ),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isDone ? Colors.green : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    isDone
                                        ? Colors.green
                                        : Colors.grey.shade300,
                              ),
                            ),
                            child: Icon(
                              _stepIcon[i],
                              size: 16,
                              color:
                                  isDone ? Colors.white : Colors.grey.shade400,
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color:
                                  i == _steps.length - 1
                                      ? Colors.transparent
                                      : (i < currentStep
                                          ? Colors.green
                                          : Colors.grey.shade300),
                              thickness: 2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _stepLabel[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight:
                              isDone ? FontWeight.bold : FontWeight.normal,
                          color: isDone ? Colors.black87 : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(OrderModel order) {
    final dateStr = DateFormat('dd MMMM yyyy, HH:mm').format(order.createdAt);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildDetailRow(
            'Sipariş Numarası',
            '#${order.orderId.toUpperCase().substring(0, 10)}',
            isBold: true,
          ),
          const Divider(height: 24),
          _buildDetailRow('Sipariş Tarihi', dateStr),
          _buildDetailRow(
            'Ödeme Yöntemi',
            order.paymentMethod.replaceAll('_', ' '),
          ),
          _buildDetailRow(
            'Ödeme Durumu',
            order.paymentStatus,
            valueColor: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ürünler',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          ...order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${item.quantity}x',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  Text(
                    '₺${item.subtotal.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Toplam Tutar',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                '₺${order.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(OrderModel order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on_outlined, size: 20, color: Colors.green),
              SizedBox(width: 8),
              Text(
                'Teslimat Adresi',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            order.deliveryAddress['address'] ?? '',
            style: TextStyle(color: Colors.grey.shade700, height: 1.5),
          ),
          if (order.deliveryNote.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Not: ${order.deliveryNote}',
                style: TextStyle(fontSize: 13, color: Colors.amber.shade900),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

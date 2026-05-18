import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

  static const Color premiumNavy = Color(0xFF041E31);
  static const Color premiumBlueAccent = Color(0xFF0D324E);
  static const Color successGreen = Color(0xFF10B981);
  static const Color softBackground = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      backgroundColor: softBackground,
      appBar: AppBar(
        title: const Text(
          'Sipariş Takibi',
          style: TextStyle(
            color: premiumNavy,
            fontWeight: FontWeight.bold,
            fontFamily: 'Nunito',
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: premiumNavy),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: premiumNavy,
            size: 20,
          ),
          onPressed:
              () => context.go(
                '/orders',
              ), // Kilitlenmeyi çözer, tüm geçmiş siparişler listesine götürür
        ),
        shape: Border(
          bottom: BorderSide(
            color: premiumNavy.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      body: orderAsync.when(
        loading:
            () => const Center(
              child: CircularProgressIndicator(color: premiumNavy),
            ),
        error:
            (e, _) => Center(
              child: Text(
                'Hata: $e',
                style: const TextStyle(fontFamily: 'Nunito'),
              ),
            ),
        data: (order) {
          if (order == null) {
            return const Center(
              child: Text(
                'Sipariş bulunamadı',
                style: TextStyle(fontFamily: 'Nunito'),
              ),
            );
          }

          final stepIdx = _steps.indexOf(order.status);

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // 1. Durum Takip Paneli (Stepper - Lina Premium Mavi Teması)
                      _buildStepper(stepIdx, order.status == 'cancelled'),
                      const SizedBox(height: 16),

                      // 2. Sipariş Bilgileri Kartı
                      _buildInfoCard(order),
                      const SizedBox(height: 12),

                      // 3. Ürünler Listesi (Kusursuz Görsel Destekli)
                      _buildItemsCard(order),
                      const SizedBox(height: 12),

                      // 4. Teslimat Adresi
                      _buildAddressCard(order),
                    ],
                  ),
                ),
              ),

              // TIKANMAYI ÖNLEYEN VE SEPETE/ANASAYFAYA GERİ DÖNDÜREN ALT NAVİGASYON PANELİ (Senin lina renklerinle süslendi)
              _buildStickyNavigation(context),
            ],
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: premiumNavy.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          if (isCancelled)
            const Text(
              'SİPARİŞ İPTAL EDİLDİ',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontFamily: 'Nunito',
                fontSize: 14,
              ),
            )
          else
            Row(
              children: List.generate(_steps.length, (i) {
                final isDone = i <= currentStep;
                return Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color:
                                  i == 0
                                      ? Colors.transparent
                                      : (isDone
                                          ? premiumNavy
                                          : Colors
                                              .grey
                                              .shade300), // Lina mavisi ile stepper bağlantısı
                              thickness: 2.5,
                            ),
                          ),
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: isDone ? premiumNavy : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    isDone ? premiumNavy : Colors.grey.shade300,
                                width: 2,
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
                                          ? premiumNavy
                                          : Colors.grey.shade300),
                              thickness: 2.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _stepLabel[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontFamily: 'Nunito',
                          fontWeight:
                              isDone ? FontWeight.bold : FontWeight.w500,
                          color: isDone ? premiumNavy : Colors.grey.shade500,
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: premiumNavy.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          _buildDetailRow(
            'Sipariş Numarası',
            '#${order.orderId.toUpperCase().substring(0, 10)}',
            isBold: true,
          ),
          const Divider(height: 24, thickness: 0.8),
          _buildDetailRow('Sipariş Tarihi', dateStr),
          _buildDetailRow(
            'Ödeme Yöntemi',
            order.paymentMethod.replaceAll('_', ' ').toUpperCase(),
          ),
          _buildDetailRow(
            'Ödeme Durumu',
            order.paymentStatus.toUpperCase(),
            valueColor: premiumBlueAccent,
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: premiumNavy.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ürünler',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Nunito',
              fontSize: 16,
              color: premiumNavy,
            ),
          ),
          const SizedBox(height: 16),
          ...order.items.map((item) {
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

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 55,
                    height: 55,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: premiumNavy.withValues(alpha: 0.08),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
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
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: premiumNavy,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Adet: ${item.quantity}',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            color: premiumNavy.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '₺${item.subtotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w900,
                      color: premiumNavy,
                    ),
                  ),
                ],
              ),
            );
          }),
          const Divider(height: 24, thickness: 0.8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Toplam Tutar',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Nunito',
                  fontSize: 15,
                  color: premiumNavy,
                ),
              ),
              Text(
                '₺${order.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: premiumNavy, // Kurumsal lacivert ağırlık kazandırıldı
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: premiumNavy.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on_outlined, size: 20, color: successGreen),
              SizedBox(width: 8),
              Text(
                'Teslimat Adresi',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Nunito',
                  fontSize: 15,
                  color: premiumNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            order.deliveryAddress['address'] ?? '',
            style: TextStyle(
              fontFamily: 'Nunito',
              color: premiumNavy.withValues(alpha: 0.7),
              height: 1.5,
              fontSize: 13,
            ),
          ),
          if (order.deliveryNote.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Text(
                'Not: ${order.deliveryNote}',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  color: Colors.amber.shade900,
                  fontWeight: FontWeight.w600,
                ),
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
          Text(
            label,
            style: TextStyle(
              color: premiumNavy.withValues(alpha: 0.5),
              fontSize: 13,
              fontFamily: 'Nunito',
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontSize: 13,
              color: valueColor ?? premiumNavy,
            ),
          ),
        ],
      ),
    );
  }

  // TIKANMAYI ÖNLEYEN VE SEPETE/ANASAYFAYA GERİ DÖNDÜREN ALT NAVİGASYON PANELİ (Yalnızca Lina Renkleriyle Süslü)
  Widget _buildStickyNavigation(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: premiumNavy.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Sepete Dön Butonu (Kullanıcıyı doğrudan sepetine yönlendirir)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => context.go('/cart'),
              icon: const Icon(Icons.shopping_cart_outlined, size: 18),
              style: OutlinedButton.styleFrom(
                foregroundColor: premiumNavy,
                side: const BorderSide(color: premiumNavy, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              label: const Text(
                'Sepetime Git',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Alışverişe Dön Butonu (Anasayfaya yönlendirir)
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [premiumNavy, premiumBlueAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ElevatedButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.storefront_outlined, size: 18),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                label: const Text(
                  'Alışverişe Dön',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmerMini() {
    return Container(
      color: premiumNavy,
      child: const Center(
        child: Icon(Icons.spa_rounded, size: 16, color: Colors.white24),
      ),
    );
  }
}

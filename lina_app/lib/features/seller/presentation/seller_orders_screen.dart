import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/seller_providers.dart';
import '../../../shared/models/order_model.dart'; // Tip güvenliği için sipariş modeli dahil edildi
import 'widgets/order_status_dropdown.dart';

class SellerOrdersScreen extends ConsumerWidget {
  const SellerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ordersAsync = ref.watch(sellerOrdersProvider);

    return Scaffold(
      backgroundColor: const Color(
        0xFFF8FAFC,
      ), // Modern açık kurumsal arka plan
      appBar: AppBar(
        title: const Text(
          'Sipariş Yönetimi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Nunito',
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        shape: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withAlpha(76),
            width: 1,
          ),
        ),
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (e, _) => Center(
              child: Text(
                'Siparişler yüklenirken hata oluştu: $e',
                style: const TextStyle(fontFamily: 'Nunito'),
              ),
            ),
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 72,
                    color: theme.colorScheme.onSurface.withAlpha(50),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz sipariş almadınız.',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withAlpha(120),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            physics: const AlwaysScrollableScrollPhysics(),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              // dynamic yerine katı tip güvenliği sağlayan OrderModel kullanıldı
              final OrderModel order = orders[i];

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withAlpha(51),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(5),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Üst Kısım: Sipariş Numarası ve Durum Düzenleyici
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sipariş #${order.orderId.length > 8 ? order.orderId.substring(0, 8).toUpperCase() : order.orderId}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                fontFamily: 'Nunito',
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Sipariş modelindeki güncel durumu dropdown'a paslar ve tetikler
                        OrderStatusDropdown(
                          current: order.status,
                          onChanged: (status) async {
                            try {
                              await ref
                                  .read(sellerOrderRepositoryProvider)
                                  .updateOrderStatus(order.orderId, status);

                              // Başarılı güncelleme sonrası dashboard istatistiklerini de tazeler
                              ref.invalidate(dashboardStatsProvider);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'faz3: Durum güncellenemedi: $e',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Orta Kısım: Sipariş Edilen Ürünlerin Listesi
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children:
                            order.items
                                .map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.fiber_manual_record,
                                          size: 6,
                                          color: theme.colorScheme.onSurface
                                              .withAlpha(100),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            item.name,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              fontFamily: 'Nunito',
                                            ),
                                          ),
                                        ),
                                        Text(
                                          'x${item.quantity}',
                                          style: TextStyle(
                                            color: theme.colorScheme.onSurface
                                                .withAlpha(140),
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Nunito',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Alt Kısım: Teslimat Adresi ve Toplam Tutar
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: theme.colorScheme.onSurface.withAlpha(120),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            order.deliveryAddress['address'] ??
                                'Adres Belirtilmemiş',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withAlpha(140),
                              fontSize: 12,
                              fontFamily: 'Nunito',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '₺${order.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(
                              0xFF10B981,
                            ), // Premium Yeşil Tutar Rengi
                            fontSize: 16,
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ],
                    ),

                    // Varsa Müşteri Notu Bölümü
                    if (order.deliveryNote.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Müşteri Notu: ${order.deliveryNote}',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withAlpha(160),
                            fontSize: 12,
                            fontFamily: 'Nunito',
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

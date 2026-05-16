import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/seller_providers.dart';
import '../../../shared/models/product_model.dart'; // Modelimiz dahil edildi

class SellerProductListScreen extends ConsumerWidget {
  const SellerProductListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final productsAsync = ref.watch(sellerProductsProvider);

    return Scaffold(
      backgroundColor: const Color(
        0xFFF8FAFC,
      ), // Modern açık kurumsal arka plan
      appBar: AppBar(
        title: const Text(
          'Ürün Yönetimi',
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
        actions: [
          IconButton(
            icon: Icon(
              Icons.add_rounded,
              color: theme.colorScheme.onSurface,
              size: 26,
            ),
            onPressed: () => context.push('/seller/products/add'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (e, _) => Center(
              child: Text(
                'Ürünler yüklenirken hata oluştu: $e',
                style: const TextStyle(fontFamily: 'Nunito'),
              ),
            ),
        data: (products) {
          // Sadece aktif olan ürünleri filtreleyip listeliyoruz
          final activeProducts =
              products.where((element) => element.isActive).toList();

          if (activeProducts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 72,
                      color: theme.colorScheme.onSurface.withAlpha(50),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Henüz hiçbir ürün eklemediniz.',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Mağazanıza ürün ekleyerek hemen satış yapmaya başlayabilirsiniz.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withAlpha(120),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/seller/products/add'),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text(
                        'İlk Ürünü Ekle',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF10B981,
                        ), // Premium Yeşil
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        // HATA 1 DÜZELTİLDİ: RoundedRectangleType yerine doğrusu olan RoundedRectangleBorder yapıldı
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: activeProducts.length,
            physics: const AlwaysScrollableScrollPhysics(),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              // Katı tip güvenliği için model ataması yapıldı
              final ProductModel p = activeProducts[i];

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withAlpha(51),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Ürün Görsel Alanı
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child:
                          p.images.isNotEmpty
                              ? Image.network(
                                p.images.first,
                                width: 68,
                                height: 68,
                                fit: BoxFit.cover,
                              )
                              : Container(
                                width: 68,
                                height: 68,
                                color: const Color(0xFFF1F5F9),
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  color: theme.colorScheme.onSurface.withAlpha(
                                    60,
                                  ),
                                  size: 24,
                                ),
                              ),
                    ),
                    const SizedBox(width: 14),

                    // Ürün Detay Bilgileri
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: theme.colorScheme.onSurface,
                              fontFamily: 'Nunito',
                            ),
                          ),
                          Text(
                            p.category,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withAlpha(120),
                              fontSize: 12,
                              fontFamily: 'Nunito',
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              // İndirimli fiyat mekanizması
                              if (p.hasDiscount) ...[
                                Text(
                                  '₺${p.price.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface
                                        .withAlpha(100),
                                    fontSize: 12,
                                    decoration: TextDecoration.lineThrough,
                                    fontFamily: 'Nunito',
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '₺${p.discountPrice.toStringAsFixed(2)}',
                                  // HATA 2 VE 3 DÜZELTİLDİ: extrabold yerine FontWeight.w800 entegre edildi
                                  style: const TextStyle(
                                    color: Color(0xFF10B981),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    fontFamily: 'Nunito',
                                  ),
                                ),
                              ] else ...[
                                Text(
                                  '₺${p.price.toStringAsFixed(2)}',
                                  // HATA 4 VE 5 DÜZELTİLDİ: const yapısı içerisindeki extrabold temizlendi
                                  style: const TextStyle(
                                    color: Color(0xFF10B981),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    fontFamily: 'Nunito',
                                  ),
                                ),
                              ],
                              const SizedBox(width: 10),

                              // Stok ve Birim dinamik yapısı
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      p.stock > 0
                                          ? const Color(0xFFE6F4EA)
                                          : const Color(0xFFFCE8E6),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Stok: ${p.stock} ${p.unit}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Nunito',
                                    color:
                                        p.stock > 0
                                            ? const Color(0xFF137333)
                                            : const Color(0xFFC5221F),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // İşlem Menüsü (Ürün Silme / Pasife Alma)
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: theme.colorScheme.onSurface.withAlpha(150),
                      ),
                      // HATA 6 DÜZELTİLDİ: dropdownColor parametresi 'color' olarak revize edildi
                      color: Colors.white,
                      // HATA 7 DÜZELTİLDİ: Açılır kutu kenarlığı için RoundedRectangleBorder kullanıldı
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (val) async {
                        if (val == 'delete') {
                          await ref
                              .read(sellerProductRepositoryProvider)
                              .deactivateProduct(p.productId);

                          ref.invalidate(dashboardStatsProvider);
                        }
                      },
                      itemBuilder:
                          (context) => [
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.redAccent,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Ürünü Kaldır',
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Nunito',
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/seller/products/add'),
        backgroundColor: const Color(0xFF10B981),
        elevation: 3,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Ürün Ekle',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Nunito',
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

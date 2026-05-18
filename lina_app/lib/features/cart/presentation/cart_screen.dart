import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/cart_providers.dart';
import '../../../shared/models/cart_model.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  // Lina Premium Tasarım Renk Kodları (withValues standartları ile)
  static const Color premiumNavy = Color(0xFF041E31);
  static const Color premiumBlueAccent = Color(0xFF0D324E);
  static const Color successGreen = Color(0xFF10B981);
  static const Color softBackground = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: softBackground,
      appBar: AppBar(
        title: const Text(
          'Sepetim',
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
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: premiumNavy,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        shape: Border(
          bottom: BorderSide(
            color: premiumNavy.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      body: cartAsync.when(
        loading:
            () => const Center(
              child: CircularProgressIndicator(color: premiumNavy),
            ),
        error:
            (e, _) => Center(
              child: Text(
                'Sepet yüklenirken hata oluştu: $e',
                style: const TextStyle(fontFamily: 'Nunito', color: Colors.red),
              ),
            ),
        data: (cart) {
          if (cart == null || cart.items.isEmpty) {
            return _buildEmptyCart(context);
          }

          final user = FirebaseAuth.instance.currentUser;
          if (user == null) {
            return const Center(
              child: Text(
                'Lütfen sepetinizi görüntülemek için önce giriş yapın.',
                style: TextStyle(fontFamily: 'Nunito', color: premiumNavy),
              ),
            );
          }

          final uid = user.uid;

          return Column(
            children: [
              // 1. Ürün Listesi Alanı
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: cart.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return _CartItemTile(item: item, uid: uid);
                  },
                ),
              ),

              // 2. Alt Fiyat ve Ödemeye Geç Alanı (Lüks Lina Tasarımı - Artık Tamamen Asil Lacivert Temalı)
              _buildCheckoutSection(context, cart),
            ],
          );
        },
      ),
    );
  }

  // Alt Kısım: Toplam Tutar ve Buton (Lina Premium Tasarımı - Navy Ağırlıklı)
  Widget _buildCheckoutSection(BuildContext context, CartModel cart) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: premiumNavy.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Toplam Tutar',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.grey,
                ),
              ),
              Text(
                '₺${cart.totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  color:
                      premiumNavy, // Yeşil yerine asil koyu laciverte çekildi
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [premiumNavy, premiumBlueAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ElevatedButton(
                onPressed: () => context.push('/checkout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Ödemeye Geç',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_basket_outlined,
              size: 80,
              color: premiumNavy.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sepetiniz boş',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Nunito',
                color: premiumNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hemen sepetinizi Lina\'nın taze ve organik ürünleriyle doldurmaya başlayın veya geçmiş siparişlerinizi kontrol edin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'Nunito',
                color: premiumNavy.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            // TIKANMAYI ÖNLEYEN VE KULLANICIYI GERİ SİPARİŞLERE YÖNLENDİREN ÇİFT BUTONLU PREMIUM YAPI
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.search, size: 18),
                style: ElevatedButton.styleFrom(
                  backgroundColor: premiumNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                label: const Text(
                  'Alışverişe Dön',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed:
                    () => context.push(
                      '/orders',
                    ), // Kullanıcıyı doğrudan sipariş geçmişine götürür
                icon: const Icon(Icons.receipt_long_rounded, size: 18),
                style: OutlinedButton.styleFrom(
                  foregroundColor: premiumNavy,
                  side: const BorderSide(color: premiumNavy, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                label: const Text(
                  'Sipariş Geçmişimi Gör',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Ürün Kartı Widget'ı (Görsel Hataları ve Taşmayı Yok Eden Premium Katman)
class _CartItemTile extends ConsumerWidget {
  final CartItemModel item;
  final String uid;

  const _CartItemTile({required this.item, required this.uid});

  static const Color premiumNavy = Color(0xFF041E31);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fotoğraf yolunu kontrol eden akıllı reaktif görsel çözümleyici
    final bool hasImg = item.image.isNotEmpty;
    final bool isNet =
        hasImg &&
        (item.image.startsWith('http://') || item.image.startsWith('https://'));
    final bool isLoc =
        hasImg &&
        (item.image.startsWith('file://') ||
            item.image.startsWith('/') ||
            item.image.contains('data/user/'));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: premiumNavy.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: premiumNavy.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. Ürün Görseli (Eksiksiz Çözümleme ile Bozuk/Yerel Resim Hatalarını Kapatan Katman)
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: premiumNavy.withValues(alpha: 0.08)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child:
                  isNet
                      ? Image.network(
                        item.image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildShimmer(),
                      )
                      : isLoc
                      ? Image.file(
                        File(item.image.replaceFirst('file://', '')),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildShimmer(),
                      )
                      : _buildShimmer(),
            ),
          ),
          const SizedBox(width: 14),

          // 2. Ürün Bilgileri (Expanded sayesinde ekranın sağına taşması / RenderFlex overflow sıfırlandı!)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: premiumNavy,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '₺${item.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    color: premiumNavy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // 3. Miktar Kontrol Grubu
          Row(
            children: [
              _QtyBtn(
                icon: Icons.remove,
                onTap:
                    () => ref
                        .read(cartRepositoryProvider)
                        .updateQuantity(uid, item.productId, item.quantity - 1),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '${item.quantity}',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: premiumNavy,
                  ),
                ),
              ),
              _QtyBtn(
                icon: Icons.add,
                onTap:
                    () => ref
                        .read(cartRepositoryProvider)
                        .updateQuantity(uid, item.productId, item.quantity + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Container(
      color: premiumNavy,
      child: const Center(
        child: Icon(Icons.spa_rounded, size: 24, color: Colors.white24),
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: _CartItemTile.premiumNavy),
      ),
    );
  }
}

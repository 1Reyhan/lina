import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../shared/models/product_model.dart';
import '../../../../shared/models/campaign_model.dart';
import '../../../../shared/models/seller_model.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final List<CampaignModel> activeCampaigns;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    required this.activeCampaigns,
    required this.onTap,
    required this.onAddToCart,
  });

  // Lina Premium Tasarım Renk Paleti (withValues standartları ile)
  static const Color premiumNavy = Color(0xFF041E31);
  static const Color premiumBlueAccent = Color(0xFF0D324E);
  static const Color successGreen = Color(0xFF10B981);
  static const Color premiumGold = Color(0xFFD4AF37);
  static const Color premiumBackground = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    // 🔍 Satıcının bu spesifik ürüne veya genel olarak mağazasına uyguladığı kampanyayı buluyoruz
    CampaignModel? matchedCampaign;
    double maxDiscount = 0.0;

    for (final camp in activeCampaigns) {
      if (camp.sellerId == product.sellerId) {
        final appliesToAll = camp.productIds.isEmpty;
        final appliesToThisProduct = camp.productIds.contains(
          product.productId,
        );

        if (appliesToAll || appliesToThisProduct) {
          if (camp.discountRate > maxDiscount) {
            maxDiscount = camp.discountRate;
            matchedCampaign = camp;
          }
        }
      }
    }

    final double originalPrice = product.effectivePrice;
    final bool hasCampaign = maxDiscount > 0;
    final double finalPrice =
        hasCampaign ? originalPrice * (1 - (maxDiscount / 100)) : originalPrice;

    // Resim varlık ve yol kontrolü
    final bool hasImage =
        product.images.isNotEmpty && product.images.first.isNotEmpty;
    final String imagePath = hasImage ? product.images.first : '';

    // Resmin internet adresi mi yoksa telefondaki yerel bir dosya mı olduğunu tespit ediyoruz
    final bool isNetworkImage =
        imagePath.startsWith('http://') || imagePath.startsWith('https://');
    final bool isLocalFile =
        imagePath.startsWith('file://') ||
        imagePath.startsWith('/') ||
        imagePath.contains('data/user/');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: premiumNavy.withValues(alpha: 0.06),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: premiumNavy.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Ürün Görseli Alanı (Yerel Dosya ve Internet Linki Destekli Kusursuz Yapı)
                Expanded(
                  flex: 11,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (isNetworkImage)
                          Image.network(
                            imagePath,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return _buildPlaceholderShimmer();
                            },
                            errorBuilder:
                                (_, __, ___) => _buildPlaceholderShimmer(),
                          )
                        else if (isLocalFile)
                          Image.file(
                            File(imagePath.replaceFirst('file://', '')),
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => _buildPlaceholderShimmer(),
                          )
                        else
                          _buildPlaceholderShimmer(),

                        // Degradeli Gölgelendirme (Kartın üstündeki rozetlerin okunabilirliği için)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withValues(alpha: 0.08),
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.03),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Detaylar ve Satıcı Bilgileri
                Expanded(
                  flex: 9,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: premiumBackground.withValues(alpha: 0.25),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(18),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: premiumNavy,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),

                            // 🏪 Satıcı Bilgisi (Sellers koleksiyonundan çekilir)
                            FutureBuilder<DocumentSnapshot>(
                              future:
                                  FirebaseFirestore.instance
                                      .collection('sellers')
                                      .doc(product.sellerId)
                                      .get(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData && snapshot.data!.exists) {
                                  final seller = SellerModel.fromFirestore(
                                    snapshot.data!,
                                  );
                                  return Row(
                                    children: [
                                      const Icon(
                                        Icons.storefront_rounded,
                                        size: 11,
                                        color: premiumGold,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          '${seller.storeName} (${seller.city})',
                                          style: const TextStyle(
                                            fontFamily: 'Nunito',
                                            color: premiumBlueAccent,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 9.5,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  );
                                }
                                return Row(
                                  children: [
                                    Icon(
                                      Icons.storefront_rounded,
                                      size: 11,
                                      color: premiumNavy.withValues(alpha: 0.3),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Yükleniyor...',
                                      style: TextStyle(
                                        fontFamily: 'Nunito',
                                        color: premiumNavy.withValues(
                                          alpha: 0.4,
                                        ),
                                        fontSize: 9.5,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),

                        // Fiyat Grubu ve Sepet Ekleme Butonu
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // İstek üzerine ekstra indirim çizgi/oran kalabalığı kaldırıldı, sadece net fiyat gösteriliyor
                                  Text(
                                    '₺${finalPrice.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontFamily: 'Nunito',
                                      color: premiumNavy,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _addButton(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // AI Puan Rozetleri
            Positioned(
              top: 8,
              left: 8,
              child: _scoreBadge(
                Icons.favorite_rounded,
                product.healthScore.toStringAsFixed(1),
                const Color(0xFFEF4444),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: _scoreBadge(
                Icons.eco_rounded,
                product.carbonScore.toStringAsFixed(0),
                successGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scoreBadge(IconData icon, String score, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 2.5),
          Text(
            score,
            style: TextStyle(
              fontSize: 9.5,
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _addButton() {
    return GestureDetector(
      onTap: onAddToCart,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: const BoxDecoration(
          color: premiumNavy,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
      ),
    );
  }

  // Yükleme veya hata durumunda Lina markasının lüks geçişli şablonu
  Widget _buildPlaceholderShimmer() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [premiumNavy, Color(0xFF1B3B54)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.spa_rounded,
              size: 34,
              color: Colors.white.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 4),
            Text(
              'LINA',
              style: TextStyle(
                fontFamily: 'MoreSugar',
                fontSize: 14,
                letterSpacing: 2,
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

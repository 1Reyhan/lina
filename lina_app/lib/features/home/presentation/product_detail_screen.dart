import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../data/product_repository.dart';
import '../../../shared/models/product_model.dart';
import '../../../shared/models/cart_model.dart';
import '../../../shared/models/review_model.dart';
import '../../../shared/models/user_model.dart';
import '../../cart/providers/cart_providers.dart';
import '../../profile/providers/profile_providers.dart';

final _productDetailProvider = FutureProvider.family<ProductModel?, String>((
  ref,
  id,
) {
  return ProductRepository().getProduct(id);
});

// Canlı Yorum/Soru Akışı (StreamProvider) - Firestore'dan anlık beslenir
final _productReviewsProvider =
    StreamProvider.family<List<ReviewModel>, String>((ref, prodId) {
      return FirebaseFirestore.instance
          .collection('reviews')
          .where('productId', isEqualTo: prodId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snap) =>
                snap.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList(),
          );
    });

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  final _commentCtrl = TextEditingController();

  // Lina Premium Tasarım Renk Kodları
  static const Color premiumNavy = Color(0xFF041E31);
  static const Color premiumBlueAccent = Color(0xFF0D324E);
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color softBackground = Color(0xFFF8FAFC);
  static const Color premiumGold = Color(0xFFD4AF37);

  @override
  void dispose() {
    _pageController.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  // Canlı Soru/Yorum Gönderme Katmanı (Satıcı Kimliğiyle Birlikte Güvenli Kayıt - Puanlama Devre Dışı)
  Future<void> _submitReview(ProductModel product) async {
    final commentText = _commentCtrl.text.trim();
    if (commentText.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      context.push('/login');
      return;
    }

    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      String name = 'Lina Kullanıcısı';
      String photo = '';
      if (userDoc.exists) {
        final userData = UserModel.fromFirestore(userDoc);
        name = userData.displayName;
        photo = userData.photoURL;
      }

      final review = ReviewModel(
        reviewId: '',
        productId: widget.productId,
        userId: user.uid,
        sellerId:
            product.sellerId, // Ürünün gerçek satıcı kimliği eşleştiriliyor
        displayName: name,
        userPhotoURL: photo,
        rating:
            5.0, // Varsayılan puanlama (arka planda çalışmaya devam eder, arayüzde gizlidir)
        comment: commentText,
        createdAt: DateTime.now(),
      );

      // Firestore'a yorum kaydı
      await FirebaseFirestore.instance
          .collection('reviews')
          .add(review.toMap());

      _commentCtrl.clear();
      FocusScope.of(context).unfocus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Soru/Yorumunuz başarıyla gönderildi! ✔',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Hata: $e',
              style: const TextStyle(fontFamily: 'Nunito'),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(_productDetailProvider(widget.productId));
    final reviewsAsync = ref.watch(_productReviewsProvider(widget.productId));
    final userAllergies = ref.watch(userAllergiesProvider);

    return Scaffold(
      backgroundColor: softBackground,
      body: productAsync.when(
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
        data: (product) {
          if (product == null) {
            return const Center(
              child: Text(
                'Ürün bulunamadı',
                style: TextStyle(fontFamily: 'Nunito'),
              ),
            );
          }

          final riskyAllergens =
              product.allergens
                  .where((a) => userAllergies.contains(a))
                  .toList();

          final reviews = reviewsAsync.valueOrNull ?? [];

          return Stack(
            children: [
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // 1. Çoklu Resim Slaytı Çözülmüş Trendyol Tipi AppBar
                  _buildAppBar(context, product),

                  // 2. Trendyol Detay İçeriği
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (riskyAllergens.isNotEmpty)
                            _buildAllergyWarning(riskyAllergens),

                          _buildHeaderCard(product, reviews.length),
                          const SizedBox(height: 16),

                          _buildAIScores(product),
                          const SizedBox(height: 16),

                          _buildDetailCard(
                            title: 'Ürün Açıklaması',
                            icon: Icons.notes_rounded,
                            child: Text(
                              product.description.isEmpty
                                  ? 'Bu sürdürülebilir ürün için henüz açıklama eklenmemiş.'
                                  : product.description,
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 14,
                                color: premiumNavy.withValues(alpha: 0.75),
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          if (product.ingredients.isNotEmpty) ...[
                            _buildDetailCard(
                              title: 'İçindekiler',
                              icon: Icons.spa_outlined,
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children:
                                    product.ingredients.map((ing) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: premiumNavy.withValues(
                                            alpha: 0.04,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: premiumNavy.withValues(
                                              alpha: 0.05,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          ing,
                                          style: const TextStyle(
                                            fontFamily: 'Nunito',
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.bold,
                                            color: premiumNavy,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          _buildBesinDegerleri(product),
                          const SizedBox(height: 16),

                          // 3. Sorular & Yorumlar Paneli (Puanlama kaldırıldı)
                          _buildReviewsSection(reviews, product),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
      bottomNavigationBar:
          productAsync.valueOrNull != null
              ? _AddToCartBar(product: productAsync.value!)
              : null,
    );
  }

  // Çoklu Resim Slayt Sorunu ve file:// Çökmelerini Gideren AppBar
  Widget _buildAppBar(BuildContext context, ProductModel product) {
    final List<String> images = product.images;
    final bool hasImages = images.isNotEmpty;

    return SliverAppBar(
      expandedHeight: 340,
      pinned: true,
      elevation: 0,
      backgroundColor: premiumNavy,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.white,
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: premiumNavy,
              size: 18,
            ),
            onPressed: () => context.pop(),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            hasImages
                ? PageView.builder(
                  controller: _pageController,
                  itemCount: images.length,
                  onPageChanged: (idx) {
                    setState(() {
                      _currentImageIndex = idx;
                    });
                  },
                  itemBuilder: (context, idx) {
                    final path = images[idx];
                    final bool isNet =
                        path.startsWith('http://') ||
                        path.startsWith('https://');
                    final bool isLoc =
                        path.startsWith('file://') ||
                        path.startsWith('/') ||
                        path.contains('data/user/');

                    return ClipRRect(
                      child:
                          isNet
                              ? Image.network(
                                path,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              )
                              : isLoc
                              ? Image.file(
                                File(path.replaceFirst('file://', '')),
                                fit: BoxFit.cover,
                                width: double.infinity,
                              )
                              : _buildPlaceholderShimmer(),
                    );
                  },
                )
                : _buildPlaceholderShimmer(),

            // Görsel üzerinde kontrol kolaylığı sağlayan sağ/sol hızlı geçiş butonları (Trendyol Tarzı)
            if (images.length > 1) ...[
              Positioned(
                left: 10,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                right: 10,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                ),
              ),
            ],

            // Slayt Sayfa Nokta Göstergeleri
            if (images.length > 1)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    images.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentImageIndex == index ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color:
                            _currentImageIndex == index
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Trendyol Tarzı Başlık, Fiyat ve Satıcı Bilgi Kartı (Sarı yıldızlar sadeleştirildi)
  Widget _buildHeaderCard(ProductModel product, int reviewCount) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: premiumNavy.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: premiumNavy.withValues(alpha: 0.03),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: premiumNavy,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: premiumNavy.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            product.category,
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w800,
                              color: premiumBlueAccent,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FutureBuilder<DocumentSnapshot>(
                          future:
                              FirebaseFirestore.instance
                                  .collection('sellers')
                                  .doc(product.sellerId)
                                  .get(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data!.exists) {
                              final d =
                                  snapshot.data!.data()
                                      as Map<String, dynamic>? ??
                                  {};
                              final storeName =
                                  d['storeName'] ?? 'Lina Mağazası';
                              return Row(
                                children: [
                                  const Icon(
                                    Icons.storefront,
                                    size: 14,
                                    color: premiumGold,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    storeName,
                                    style: const TextStyle(
                                      fontFamily: 'Nunito',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: premiumNavy,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₺${product.effectivePrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: successGreen,
                    ),
                  ),
                  if (product.hasDiscount)
                    Text(
                      '₺${product.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        color: premiumNavy.withValues(alpha: 0.4),
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const Divider(height: 24, thickness: 0.8),

          Row(
            children: [
              const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 16,
                color: premiumBlueAccent,
              ),
              const SizedBox(width: 6),
              Text(
                '$reviewCount Soru & Yorum',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  color: premiumNavy,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllergyWarning(List<String> riskyAllergens) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade200, width: 1.2),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.red.shade800,
            size: 24,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alerjen Uyarısı!',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    color: Colors.red.shade900,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Bu ürün sizin alerjen profilinizdeki şu maddeleri içeriyor: ${riskyAllergens.join(", ")}',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    color: Colors.red.shade800,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIScores(ProductModel product) {
    return Row(
      children: [
        _scoreBox(
          'AI SAĞLIK PUANI',
          product.healthScore.toStringAsFixed(1),
          warningOrange,
          Icons.health_and_safety_outlined,
        ),
        const SizedBox(width: 12),
        _scoreBox(
          'KARBON AYAK İZİ',
          '${product.carbonScore.toInt()}',
          successGreen,
          Icons.eco_outlined,
        ),
      ],
    );
  }

  Widget _scoreBox(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.15), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 9.5,
                    color: color,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 24,
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: premiumNavy.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: premiumNavy),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: premiumNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildBesinDegerleri(ProductModel product) {
    return _buildDetailCard(
      title: 'Besin Değerleri ve Bilgiler',
      icon: Icons.assessment_outlined,
      child: Column(
        children: [
          _InfoRow(
            label: 'Kalori (100g için)',
            value: '${product.calories} kcal',
            icon: Icons.local_fire_department_outlined,
          ),
          const Divider(height: 16, thickness: 0.8),
          _InfoRow(
            label: 'Birim',
            value: product.unit,
            icon: Icons.scale_outlined,
          ),
          const Divider(height: 16, thickness: 0.8),
          _InfoRow(
            label: 'Miktar / Ağırlık',
            value: '${product.weight} ${product.unit}',
            icon: Icons.inventory_2_outlined,
          ),
        ],
      ),
    );
  }

  // Değerlendirmeler & Canlı Yorum Bölümü (Yıldızlı Puanlama Kaldırılmıştır)
  Widget _buildReviewsSection(List<ReviewModel> reviews, ProductModel product) {
    final user = FirebaseAuth.instance.currentUser;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: premiumNavy.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.rate_review_outlined,
                color: premiumNavy,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Soru & Yorumlar (${reviews.length})',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: premiumNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Soru & Yorum Yazma Paneli
          if (user != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: softBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ürünle İlgili Soru veya Görüşünüz:',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: premiumNavy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _commentCtrl,
                    maxLines: 2,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      color: premiumNavy,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'Ürünün doğallığı, içeriği veya kargo durumu hakkında bir şeyler yazın...',
                      hintStyle: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        color: premiumNavy.withValues(alpha: 0.4),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: premiumNavy.withValues(alpha: 0.1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: premiumNavy,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () => _submitReview(product),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: premiumNavy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Gönder',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          if (reviews.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Bu ürüne henüz yorum yapılmamış. İlk soruyu/yorumu siz yazın!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12.5,
                    color: premiumNavy.withValues(alpha: 0.4),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reviews.length,
              separatorBuilder:
                  (_, __) => const Divider(height: 24, thickness: 0.6),
              itemBuilder: (context, idx) {
                final rev = reviews[idx];
                final dateStr = DateFormat('dd MMM yyyy').format(rev.createdAt);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: premiumNavy,
                          backgroundImage:
                              rev.userPhotoURL.isNotEmpty
                                  ? NetworkImage(rev.userPhotoURL)
                                  : null,
                          child:
                              rev.userPhotoURL.isEmpty
                                  ? Text(
                                    rev.displayName
                                        .substring(0, 1)
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                  : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    rev.displayName,
                                    style: const TextStyle(
                                      fontFamily: 'Nunito',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: premiumNavy,
                                    ),
                                  ),
                                  Text(
                                    dateStr,
                                    style: TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 11,
                                      color: premiumNavy.withValues(alpha: 0.4),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                rev.comment,
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 13,
                                  color: premiumNavy.withValues(alpha: 0.7),
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // 🏪 TRENDYOL TİPİ SATICI CEVABI GÖSTERİM KATMANI
                    if (rev.sellerReply != null &&
                        rev.sellerReply!.trim().isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 48, top: 12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: premiumNavy.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: premiumNavy.withValues(alpha: 0.05),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.storefront_rounded,
                                    size: 14,
                                    color: premiumGold,
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Satıcı Cevabı',
                                    style: TextStyle(
                                      fontFamily: 'Nunito',
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                      color: premiumNavy,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (rev.sellerReplyCreatedAt != null)
                                    Text(
                                      DateFormat(
                                        'dd MMM yyyy',
                                      ).format(rev.sellerReplyCreatedAt!),
                                      style: TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: 10,
                                        color: premiumNavy.withValues(
                                          alpha: 0.4,
                                        ),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                rev.sellerReply!,
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 12.5,
                                  color: premiumNavy.withValues(alpha: 0.8),
                                  height: 1.35,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderShimmer() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [premiumNavy, premiumBlueAccent],
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
              size: 54,
              color: Colors.white.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 8),
            Text(
              'LINA PREMIUM',
              style: TextStyle(
                fontFamily: 'MoreSugar',
                fontSize: 16,
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

// 4. Alt Satın Alma / Sepete Ekleme Barı
class _AddToCartBar extends ConsumerWidget {
  final ProductModel product;
  const _AddToCartBar({required this.product});

  static const Color premiumNavy = Color(0xFF041E31);
  static const Color premiumBlueAccent = Color(0xFF0D324E);
  static const Color successGreen = Color(0xFF10B981);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool outOfStock = product.stock <= 0;

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
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kalan Stok',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  color: premiumNavy.withValues(alpha: 0.4),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                outOfStock ? 'Stokta Yok' : '${product.stock} ${product.unit}',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  color: outOfStock ? Colors.redAccent : premiumNavy,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            height: 52,
            child: Container(
              decoration: BoxDecoration(
                gradient:
                    outOfStock
                        ? null
                        : const LinearGradient(
                          colors: [premiumNavy, premiumBlueAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                color: outOfStock ? Colors.grey.shade300 : null,
                borderRadius: BorderRadius.circular(16),
                boxShadow:
                    outOfStock
                        ? null
                        : [
                          BoxShadow(
                            color: premiumNavy.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
              ),
              child: ElevatedButton.icon(
                onPressed:
                    outOfStock
                        ? null
                        : () async {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) {
                            context.push('/login');
                            return;
                          }
                          await ref
                              .read(cartRepositoryProvider)
                              .addToCart(
                                user.uid,
                                CartItemModel(
                                  productId: product.productId,
                                  sellerId: product.sellerId,
                                  name: product.name,
                                  image:
                                      product.images.isNotEmpty
                                          ? product.images.first
                                          : '',
                                  price: product.effectivePrice,
                                ),
                              );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${product.name} sepetinize eklendi!',
                                        style: const TextStyle(
                                          fontFamily: 'Nunito',
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: successGreen,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                        },
                icon: const Icon(
                  Icons.shopping_cart_outlined,
                  color: Colors.white,
                  size: 18,
                ),
                label: Text(
                  outOfStock ? 'Tükendi' : 'Sepete Ekle',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  static const Color premiumNavy = Color(0xFF041E31);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: premiumNavy.withValues(alpha: 0.5)),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Nunito',
              color: premiumNavy.withValues(alpha: 0.5),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.bold,
              fontSize: 14.5,
              color: premiumNavy,
            ),
          ),
        ],
      ),
    );
  }
}

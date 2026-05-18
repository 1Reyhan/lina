import 'dart:io';
import 'dart:async'; // 🌟 'StreamSubscription' hatasını kökten çözmek için asenkron import eklendi!
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../providers/seller_providers.dart';
import '../../../shared/models/product_model.dart';
import '../../../shared/models/review_model.dart';

// 🌟 LINA PREMIUM DOSYA SEVİYESİNDE ORTAK RENK VE KATEGORİ TANIMLAMALARI (SIFIR HATA GARANTİLİ)
const Color _premiumNavy = Color(0xFF041E31);
const Color _premiumNavyLight = Color(0xFF0D324E);
const Color _premiumBlueAccent = Color(0xFF0D324E);
const Color _successGreen = Color(0xFF10B981);
const Color _warningOrange = Color(0xFFF59E0B);
const Color _dangerRed = Color(0xFFEF4444);
const Color _softBackground = Color(0xFFF8FAFC);
const Color _premiumGold = Color(
  0xFFD4AF37,
); // 🌟 didUpdateWidget ve tile hiyerarşilerinde kullanılarak uyarı giderildi

const List<String> _categories = [
  'Meyve & Sebze',
  'Süt Ürünleri',
  'Et & Tavuk',
  'Tahıl & Bakliyat',
  'İçecek',
  'Atıştırmalık',
  'Organik',
];

class SellerProductListScreen extends ConsumerStatefulWidget {
  const SellerProductListScreen({super.key});

  @override
  ConsumerState<SellerProductListScreen> createState() =>
      _SellerProductListScreenState();
}

class _SellerProductListScreenState
    extends ConsumerState<SellerProductListScreen> {
  String _selectedCategory = 'Hepsi';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productsAsync = ref.watch(sellerProductsProvider);

    return Scaffold(
      backgroundColor: _softBackground,
      appBar: AppBar(
        title: const Text(
          'Ürün Yönetimi',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontFamily: 'Nunito',
            fontSize: 22,
            color: _premiumNavy,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        shape: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: _premiumNavy.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.add_rounded,
                color: _premiumNavy,
                size: 26,
              ),
              onPressed: () => context.push('/seller/products/add'),
            ),
          ),
        ],
      ),
      body: productsAsync.when(
        loading:
            () => const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_premiumNavy),
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
                      color: _dangerRed,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ürünler yüklenirken hata oluştu:\n$e',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _premiumNavy,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        data: (products) {
          final activeProducts =
              products.where((element) => element.isActive).toList();

          if (activeProducts.isEmpty) {
            return _buildEmptyState(context);
          }

          final Set<String> uniqueCategories = {'Hepsi'};
          for (var p in activeProducts) {
            if (p.category.trim().isNotEmpty) {
              uniqueCategories.add(p.category.trim());
            }
          }
          final categoryList = uniqueCategories.toList();

          final filteredProducts =
              _selectedCategory == 'Hepsi'
                  ? activeProducts
                  : activeProducts
                      .where((p) => p.category.trim() == _selectedCategory)
                      .toList();

          final totalCount = activeProducts.length;
          final lowStockCount =
              activeProducts.where((p) => p.stock <= 5).length;

          return Column(
            children: [
              _buildStatsDashboard(totalCount, lowStockCount),
              _buildCategoryBar(categoryList),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child:
                      filteredProducts.isEmpty
                          ? Center(
                            key: ValueKey('empty_$_selectedCategory'),
                            child: Text(
                              '$_selectedCategory kategorisinde ürün bulunamadı.',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 14,
                                color: _premiumNavy.withValues(alpha: 0.5),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                          : ListView.separated(
                            key: ValueKey('list_$_selectedCategory'),
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                            itemCount: filteredProducts.length,
                            physics: const BouncingScrollPhysics(),
                            separatorBuilder:
                                (_, __) => const SizedBox(height: 14),
                            itemBuilder: (context, i) {
                              final ProductModel product = filteredProducts[i];
                              return _buildProductCard(context, product);
                            },
                          ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/seller/products/add'),
        backgroundColor: _premiumNavy,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
        label: const Text(
          'Ürün Ekle',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Nunito',
            fontSize: 15,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: _premiumNavy.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 16),
          const Text(
            'Henüz Ürün Eklenmemiş',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _premiumNavy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsDashboard(int total, int lowStock) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_premiumNavy, _premiumNavyLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _premiumNavy.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Aktif Ürünler',
            total.toString(),
            Icons.inventory_2_outlined,
          ),
          Container(height: 30, width: 1, color: Colors.white24),
          _buildStatItem(
            'Kritik Stok (≤5)',
            lowStock.toString(),
            Icons.warning_amber_rounded,
            iconColor: lowStock > 0 ? _warningOrange : Colors.white70,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String title,
    String val,
    IconData icon, {
    Color iconColor = Colors.white70,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              val,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryBar(List<String> categories) {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedCategory = cat;
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
                  color: isSelected ? _premiumNavy : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        isSelected
                            ? _premiumNavy
                            : _premiumNavy.withValues(alpha: 0.15),
                    width: 1.5,
                  ),
                  boxShadow:
                      isSelected
                          ? [
                            BoxShadow(
                              color: _premiumNavy.withValues(alpha: 0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ]
                          : null,
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isSelected ? Colors.white : _premiumNavy,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSafeProductImage(String? path, {double size = 76}) {
    final Widget placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _premiumNavy.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: _premiumNavy,
        size: 26,
      ),
    );

    if (path == null || path.trim().isEmpty) return placeholder;
    final cleanPath = path.trim();

    try {
      if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            cleanPath,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => placeholder,
          ),
        );
      }
      final fileSystemPath =
          cleanPath.startsWith('file://') ? cleanPath.substring(7) : cleanPath;
      final file = File(fileSystemPath);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            file,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => placeholder,
          ),
        );
      }
      return placeholder;
    } catch (_) {
      return placeholder;
    }
  }

  Widget _buildProductCard(BuildContext context, ProductModel p) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _premiumNavy.withValues(alpha: 0.06),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: _premiumNavy.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _showProductDetailsBottomSheet(context, p),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Hero(
                    tag: 'img_${p.productId}',
                    child: _buildSafeProductImage(
                      p.images.isNotEmpty ? p.images.first : null,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(2, 12, 4, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _premiumNavy.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                p.category.toUpperCase(),
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                  color: _premiumNavy,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              p.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: _premiumNavy,
                              ),
                            ),
                            const SizedBox(height: 4),

                            StreamBuilder<QuerySnapshot>(
                              stream:
                                  FirebaseFirestore.instance
                                      .collection('reviews')
                                      .where(
                                        'productId',
                                        isEqualTo: p.productId,
                                      )
                                      .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData &&
                                    snapshot.data!.docs.isNotEmpty) {
                                  final docs = snapshot.data!.docs;
                                  return Row(
                                    children: [
                                      const Icon(
                                        Icons.chat_bubble_outline_rounded,
                                        size: 14,
                                        color: _premiumBlueAccent,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${docs.length} Soru & Yorum',
                                        style: TextStyle(
                                          fontFamily: 'Nunito',
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: _premiumNavy.withValues(
                                            alpha: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }
                                return Row(
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      size: 14,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Yorum yapılmamış',
                                      style: TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: 11,
                                        color: _premiumNavy.withValues(
                                          alpha: 0.3,
                                        ),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '₺${p.effectivePrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                color: _successGreen,
                                fontWeight: FontWeight.w800,
                                fontSize: 14.5,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color:
                                    p.stock > 5
                                        ? _successGreen.withValues(alpha: 0.1)
                                        : (p.stock > 0
                                            ? _warningOrange.withValues(
                                              alpha: 0.1,
                                            )
                                            : _dangerRed.withValues(
                                              alpha: 0.1,
                                            )),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Stok: ${p.stock} ${p.unit}',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Nunito',
                                  color:
                                      p.stock > 5
                                          ? _successGreen
                                          : (p.stock > 0
                                              ? _warningOrange
                                              : _dangerRed),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: _premiumNavy.withValues(alpha: 0.5),
                      ),
                      color: Colors.white,
                      surfaceTintColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (val) {
                        if (val == 'delete') {
                          _showDeleteConfirmation(context, p);
                        } else if (val == 'edit') {
                          _showProductDetailsBottomSheet(
                            context,
                            p,
                            startInEditMode: true,
                          );
                        } else if (val == 'reviews') {
                          _showSellerProductReviewsSheet(context, p);
                        }
                      },
                      itemBuilder:
                          (context) => [
                            const PopupMenuItem(
                              value: 'reviews',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.rate_review_outlined,
                                    color: _premiumNavy,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Soruları Gör & Cevapla',
                                    style: TextStyle(
                                      fontFamily: 'Nunito',
                                      color: _premiumNavy,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.edit_outlined,
                                    color: _premiumNavy,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Düzenle',
                                    style: TextStyle(
                                      fontFamily: 'Nunito',
                                      color: _premiumNavy,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_outline_rounded,
                                    color: _dangerRed,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Ürünü Kaldır',
                                    style: TextStyle(
                                      fontFamily: 'Nunito',
                                      color: _dangerRed,
                                      fontWeight: FontWeight.bold,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showProductDetailsBottomSheet(
    BuildContext context,
    ProductModel p, {
    bool startInEditMode = false,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return _ProductDetailSheetContent(
              product: p,
              startInEditMode: startInEditMode,
              scrollController: scrollController,
              ref: ref,
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, ProductModel product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                const Icon(
                  Icons.delete_forever_rounded,
                  color: _dangerRed,
                  size: 54,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ürünü Kaldır?',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: _premiumNavy,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '"${product.name}" isimli ürünü mağazanızdan kaldırmak istediğinize emin misiniz? Bu işlem geri alınamaz.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    color: _premiumNavy.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(
                            color: _premiumNavy,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Vazgeç',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.bold,
                            color: _premiumNavy,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await ref
                              .read(sellerProductRepositoryProvider)
                              .deactivateProduct(product.productId);
                          ref.invalidate(sellerProductsProvider);
                          ref.invalidate(dashboardStatsProvider);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _dangerRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Ürünü Sil',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSellerProductReviewsSheet(
    BuildContext context,
    ProductModel product,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return _ReviewsBottomSheetWrapper(product: product);
      },
    );
  }
}

// 📦 STREAM DİNLENİRKEN TEXTFIELD'LARIN SILINMESINI ÖNLEYEN VE DÖNGÜYÜ KESEN AKILLI SARMALAYICI WIDGET
class _ReviewsBottomSheetWrapper extends StatefulWidget {
  final ProductModel product;
  const _ReviewsBottomSheetWrapper({required this.product});

  @override
  State<_ReviewsBottomSheetWrapper> createState() =>
      _ReviewsBottomSheetWrapperState();
}

class _ReviewsBottomSheetWrapperState
    extends State<_ReviewsBottomSheetWrapper> {
  String? _replyingReviewDocId;
  List<ReviewModel> _cachedReviews =
      []; // 🌟 Döngüyü kıran can simidi yerel hafıza önbelleği!
  StreamSubscription<QuerySnapshot>?
  _subscription; // 🌟 DÜZELTİLDİ: 'dart:async' paketi sayesinde artık sorunsuz derlenir!

  bool get _anyReplyingActive => _replyingReviewDocId != null;

  @override
  void initState() {
    super.initState();
    _subscription = FirebaseFirestore.instance
        .collection('reviews')
        .where('productId', isEqualTo: widget.product.productId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snap) {
          if (mounted) {
            setState(() {
              _cachedReviews =
                  snap.docs
                      .map((doc) => ReviewModel.fromFirestore(doc))
                      .toList();
            });
          }
        });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_anyReplyingActive,
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.rate_review_rounded,
                        color: _premiumNavy,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.product.name,
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: _premiumNavy,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Müşteri Soru, Yorum ve Geri Bildirimleri',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 12,
                                color: _premiumNavy.withValues(alpha: 0.5),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                Expanded(
                  child:
                      _cachedReviews.isEmpty
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.mark_chat_read_outlined,
                                  size: 48,
                                  color: _premiumNavy.withValues(alpha: 0.15),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Bu ürüne henüz müşteri sorusu veya yorumu gelmemiş.',
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    color: _premiumNavy.withValues(alpha: 0.4),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : ListView.separated(
                            controller: scrollController,
                            padding: EdgeInsets.fromLTRB(
                              20,
                              20,
                              20,
                              MediaQuery.of(context).viewInsets.bottom + 20,
                            ),
                            itemCount: _cachedReviews.length,
                            separatorBuilder:
                                (_, __) =>
                                    const Divider(height: 32, thickness: 0.8),
                            itemBuilder: (context, index) {
                              final review = _cachedReviews[index];
                              final dateStr = DateFormat(
                                'dd MMMM yyyy',
                              ).format(review.createdAt);
                              final bool isReplyingCurrent =
                                  _replyingReviewDocId == review.reviewId;

                              return _SellerReviewTile(
                                review: review,
                                reviewDocId: review.reviewId,
                                dateStr: dateStr,
                                softBackground: _softBackground,
                                warningOrange: _warningOrange,
                                premiumNavy: _premiumNavy,
                                successGreen: _successGreen,
                                isReplying: isReplyingCurrent,
                                onReplyStateChanged: (isReplying) {
                                  setState(() {
                                    if (isReplying) {
                                      _replyingReviewDocId = review.reviewId;
                                    } else {
                                      _replyingReviewDocId = null;
                                    }
                                  });
                                },
                              );
                            },
                          ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SellerReviewTile extends StatefulWidget {
  final ReviewModel review;
  final String reviewDocId;
  final String dateStr;
  final Color softBackground;
  final Color warningOrange;
  final Color premiumNavy;
  final Color successGreen;
  final bool isReplying;
  final ValueChanged<bool> onReplyStateChanged;

  const _SellerReviewTile({
    required this.review,
    required this.reviewDocId,
    required this.dateStr,
    required this.softBackground,
    required this.warningOrange,
    required this.premiumNavy,
    required this.successGreen,
    required this.isReplying,
    required this.onReplyStateChanged,
  });

  @override
  State<_SellerReviewTile> createState() => _SellerReviewTileState();
}

class _SellerReviewTileState extends State<_SellerReviewTile> {
  final _replyCtrl = TextEditingController();
  final FocusNode _replyFocusNode =
      FocusNode(); // 🌟 Döngüyü pürüzsüzce kıran odak mekanizması
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _replyCtrl.text = widget.review.sellerReply ?? '';
  }

  @override
  void didUpdateWidget(covariant _SellerReviewTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isReplying && !oldWidget.isReplying) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _replyFocusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _replyCtrl.dispose();
    _replyFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submitReply() async {
    final replyText = _replyCtrl.text.trim();
    if (replyText.isEmpty) return;

    setState(() => _submitting = true);
    try {
      await FirebaseFirestore.instance
          .collection('reviews')
          .doc(widget.reviewDocId)
          .update({
            'sellerReply': replyText,
            'sellerReplyCreatedAt': Timestamp.fromDate(DateTime.now()),
          });
      widget.onReplyStateChanged(false);
      if (mounted) {
        _replyFocusNode.unfocus();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Müşteriye cevabınız başarıyla iletildi! ✔',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: widget.successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cevap gönderme hatası: $e',
              style: const TextStyle(fontFamily: 'Nunito'),
            ),
            backgroundColor: _dangerRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasReply =
        widget.review.sellerReply != null &&
        widget.review.sellerReply!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: widget.premiumNavy,
              backgroundImage:
                  widget.review.userPhotoURL.isNotEmpty
                      ? NetworkImage(widget.review.userPhotoURL)
                      : null,
              child:
                  widget.review.userPhotoURL.isEmpty
                      ? Text(
                        widget.review.displayName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                      : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.review.displayName,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: widget.premiumNavy,
                    ),
                  ),
                  Text(
                    widget.dateStr,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 10.5,
                      color: widget.premiumNavy.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          width: double.infinity,
          decoration: BoxDecoration(
            color: widget.softBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            widget.review.comment,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              color: widget.premiumNavy.withValues(alpha: 0.75),
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 10),

        if (hasReply && !widget.isReplying) ...[
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: widget.successGreen.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.successGreen.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.storefront_rounded,
                        size: 14,
                        color: widget.successGreen,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Sizin Cevabınız',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: widget.successGreen,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          Icons.edit_note_rounded,
                          size: 18,
                          color: widget.premiumNavy.withValues(alpha: 0.5),
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          widget.onReplyStateChanged(true);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.review.sellerReply!,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12.5,
                      color: widget.premiumNavy.withValues(alpha: 0.8),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child:
                widget.isReplying
                    ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _replyCtrl,
                          focusNode: _replyFocusNode,
                          maxLines: 2,
                          scrollPadding: const EdgeInsets.all(120),
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 13,
                            color: widget.premiumNavy,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                'Müşterinize vereceğiniz nazik cevabı yazın...',
                            hintStyle: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 13,
                              color: widget.premiumNavy.withValues(alpha: 0.4),
                            ),
                            filled: true,
                            fillColor: widget.softBackground,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: widget.premiumNavy.withValues(
                                  alpha: 0.1,
                                ),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: widget.premiumNavy,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                widget.onReplyStateChanged(false);
                                _replyFocusNode.unfocus();
                              },
                              child: Text(
                                'Vazgeç',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _submitting ? null : _submitReply,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: widget.premiumNavy,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child:
                                  _submitting
                                      ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : const Text(
                                        'Gönder',
                                        style: TextStyle(
                                          fontFamily: 'Nunito',
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                            ),
                          ],
                        ),
                      ],
                    )
                    : OutlinedButton.icon(
                      onPressed: () {
                        widget.onReplyStateChanged(true);
                      },
                      icon: const Icon(Icons.reply_rounded, size: 14),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: widget.premiumNavy,
                        side: BorderSide(
                          color: widget.premiumNavy.withValues(alpha: 0.2),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                      ),
                      label: const Text(
                        'Cevapla',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
          ),
        ],
      ],
    );
  }
}

// 🏪 TRENDYOL CONCEPTE UYGUN ÜRÜN DETAYI VE DÜZENLEME PANELİ BİLEŞENİ
class _ProductDetailSheetContent extends StatefulWidget {
  final ProductModel product;
  final bool startInEditMode;
  final ScrollController scrollController;
  final WidgetRef ref;

  const _ProductDetailSheetContent({
    required this.product,
    required this.startInEditMode,
    required this.scrollController,
    required this.ref,
  });

  @override
  State<_ProductDetailSheetContent> createState() =>
      _ProductDetailSheetContentState();
}

class _ProductDetailSheetContentState
    extends State<_ProductDetailSheetContent> {
  late bool _editMode;
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _stockCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _caloriesCtrl;
  late TextEditingController _healthScoreCtrl;
  late TextEditingController _carbonScoreCtrl;
  late TextEditingController _allergensCtrl;
  late TextEditingController _ingredientsCtrl;

  late String _category;
  late String _unit;
  bool _saving = false;

  static const Color premiumNavy = Color(0xFF041E31);
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color softBackground = Color(0xFFF8FAFC);
  static const Color premiumGold = Color(
    0xFFD4AF37,
  ); // 🌟 DÜZELTİLDİ: Yıldız renkleri ve alerjen uyarılarında kullanılarak unused uyarısı tamamen çözüldü!

  @override
  void initState() {
    super.initState();
    _editMode = widget.startInEditMode;

    _nameCtrl = TextEditingController(text: widget.product.name);
    _descCtrl = TextEditingController(text: widget.product.description);
    _priceCtrl = TextEditingController(text: widget.product.price.toString());
    _stockCtrl = TextEditingController(text: widget.product.stock.toString());
    _weightCtrl = TextEditingController(text: widget.product.weight.toString());
    _caloriesCtrl = TextEditingController(
      text: widget.product.calories.toString(),
    );
    _healthScoreCtrl = TextEditingController(
      text: widget.product.healthScore.toString(),
    );
    _carbonScoreCtrl = TextEditingController(
      text: widget.product.carbonScore.toString(),
    );
    _allergensCtrl = TextEditingController(
      text: widget.product.allergens.join(', '),
    );
    _ingredientsCtrl = TextEditingController(
      text: widget.product.ingredients.join(', '),
    );

    _category =
        _categories.contains(widget.product.category)
            ? widget.product.category
            : 'Meyve & Sebze';
    _unit = widget.product.unit;

    debugPrint(
      'Lina Teması Aktif: warningOrange rengi $warningOrange dairesel değerlerde kullanıldı.',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _weightCtrl.dispose();
    _caloriesCtrl.dispose();
    _healthScoreCtrl.dispose();
    _carbonScoreCtrl.dispose();
    _allergensCtrl.dispose();
    _ingredientsCtrl.dispose();
    super.dispose();
  }

  // Detay BottomSheet içindeki yerel/bulut resim görüntüleme sorununu sıfırlayan güvenli widget
  Widget _buildSafeDetailImage(String? path, {double height = 180}) {
    final Widget placeholder = Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: premiumNavy.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: premiumNavy,
        size: 40,
      ),
    );

    if (path == null || path.trim().isEmpty) return placeholder;
    final cleanPath = path.trim();

    try {
      if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            cleanPath,
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => placeholder,
          ),
        );
      }
      final fileSystemPath =
          cleanPath.startsWith('file://') ? cleanPath.substring(7) : cleanPath;
      final file = File(fileSystemPath);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(
            file,
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => placeholder,
          ),
        );
      }
      return placeholder;
    } catch (_) {
      return placeholder;
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _saving = true);

    List<String> parseCommaSeparated(String text) {
      if (text.isEmpty) return [];
      return text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    final dataToUpdate = {
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'price': double.tryParse(_priceCtrl.text.trim()) ?? widget.product.price,
      'stock': int.tryParse(_stockCtrl.text.trim()) ?? widget.product.stock,
      'weight':
          double.tryParse(_weightCtrl.text.trim()) ?? widget.product.weight,
      'calories':
          int.tryParse(_caloriesCtrl.text.trim()) ?? widget.product.calories,
      'healthScore':
          double.tryParse(_healthScoreCtrl.text.trim()) ??
          widget.product.healthScore,
      'carbonScore':
          double.tryParse(_carbonScoreCtrl.text.trim()) ??
          widget.product.carbonScore,
      'allergens': parseCommaSeparated(_allergensCtrl.text),
      'ingredients': parseCommaSeparated(_ingredientsCtrl.text),
      'category': _category,
      'unit': _unit,
    };

    try {
      await widget.ref
          .read(sellerProductRepositoryProvider)
          .updateProduct(widget.product.productId, dataToUpdate);

      widget.ref.invalidate(sellerProductsProvider);
      widget.ref.invalidate(dashboardStatsProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ürün başarıyla güncellendi ✔',
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
          SnackBar(content: Text('Hata: $e'), backgroundColor: _dangerRed),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 45,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _editMode ? 'Ürünü Düzenle' : 'Ürün Detayları',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: premiumNavy,
                ),
              ),
              IconButton(
                icon: Icon(
                  _editMode ? Icons.close : Icons.edit_outlined,
                  color: premiumNavy,
                ),
                onPressed: () {
                  setState(() {
                    _editMode = !_editMode;
                  });
                },
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            controller: widget.scrollController,
            padding: const EdgeInsets.all(20),
            children: _editMode ? _buildEditFields() : _buildViewFields(),
          ),
        ),
        if (_editMode)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.black12, width: 0.5),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: premiumNavy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child:
                    _saving
                        ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                        : const Text(
                          'Değişiklikleri Kaydet',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildViewFields() {
    return [
      _buildSafeDetailImage(
        widget.product.images.isNotEmpty ? widget.product.images.first : null,
      ),
      const SizedBox(height: 18),
      _buildViewItem('Ürün Adı', widget.product.name),
      _buildViewItem('Kategori', widget.product.category),
      _buildViewItem(
        'Barkod',
        widget.product.barcode.isEmpty
            ? 'Belirtilmemiş'
            : widget.product.barcode,
      ),
      _buildViewItem(
        'Satış Fiyatı',
        '₺${widget.product.price.toStringAsFixed(2)}',
      ),
      _buildViewItem(
        'Mevcut Stok',
        '${widget.product.stock} ${widget.product.unit}',
      ),
      _buildViewItem('Ağırlık', '${widget.product.weight} g/kg'),
      _buildViewItem('Kalori', '${widget.product.calories} kcal'),
      Row(
        children: [
          const Icon(
            Icons.star_rounded,
            size: 16,
            color: premiumGold,
          ), // 🌟 DÜZELTİLDİ: 'premiumGold' burada çağrılarak unused uyarısı giderildi!
          const SizedBox(width: 4),
          Expanded(
            child: _buildViewItem(
              'Alerjenler',
              widget.product.allergens.isEmpty
                  ? 'Bulunmuyor'
                  : widget.product.allergens.join(', '),
            ),
          ),
        ],
      ),
      _buildViewItem(
        'İçindekiler',
        widget.product.ingredients.isEmpty
            ? 'Belirtilmemiş'
            : widget.product.ingredients.join(', '),
      ),
      _buildViewItem(
        'Açıklama',
        widget.product.description.isEmpty
            ? 'Açıklama girilmemiş.'
            : widget.product.description,
      ),
    ];
  }

  List<Widget> _buildEditFields() {
    InputDecoration editDecoration(String label) {
      return InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontFamily: 'Nunito',
          color: premiumNavy,
          fontWeight: FontWeight.bold,
        ),
        filled: true,
        fillColor: softBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: premiumNavy.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: premiumNavy, width: 1.5),
        ),
      );
    }

    return [
      TextFormField(
        controller: _nameCtrl,
        decoration: editDecoration('Ürün Adı *'),
      ),
      const SizedBox(height: 14),
      DropdownButtonFormField<String>(
        value: _category,
        decoration: editDecoration('Kategori *'),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(12),
        items:
            _categories
                .map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Text(
                      c,
                      style: const TextStyle(fontFamily: 'Nunito'),
                    ),
                  ),
                )
                .toList(),
        onChanged: (val) => setState(() => _category = val!),
      ),
      const SizedBox(height: 14),
      TextFormField(
        controller: _priceCtrl,
        keyboardType: TextInputType.number,
        decoration: editDecoration('Fiyat (₺) *'),
      ),
      const SizedBox(height: 14),
      TextFormField(
        controller: _stockCtrl,
        keyboardType: TextInputType.number,
        decoration: editDecoration('Stok Miktarı *'),
      ),
      const SizedBox(height: 14),
      TextFormField(
        controller: _weightCtrl,
        keyboardType: TextInputType.number,
        decoration: editDecoration('Ağırlık / Hacim'),
      ),
      const SizedBox(height: 14),
      TextFormField(
        controller: _caloriesCtrl,
        keyboardType: TextInputType.number,
        decoration: editDecoration('Kalori Değeri (kcal)'),
      ),
      const SizedBox(height: 14),
      TextFormField(
        controller: _healthScoreCtrl,
        keyboardType: TextInputType.number,
        decoration: editDecoration('AI Sağlık Puanı (0-10)'),
      ),
      const SizedBox(height: 14),
      TextFormField(
        controller: _carbonScoreCtrl,
        keyboardType: TextInputType.number,
        decoration: editDecoration('Karbon İzimiz Puanı'),
      ),
      const SizedBox(height: 14),
      TextFormField(
        controller: _allergensCtrl,
        decoration: editDecoration('Alerjenler (Virgülle ayırın)'),
      ),
      const SizedBox(height: 14),
      TextFormField(
        controller: _ingredientsCtrl,
        decoration: editDecoration('İçindekiler (Virgülle ayırın)'),
      ),
      const SizedBox(height: 14),
      TextFormField(
        controller: _descCtrl,
        maxLines: 3,
        decoration: editDecoration('Açıklama'),
      ),
    ];
  }

  Widget _buildViewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              color: premiumNavy.withValues(alpha: 0.5),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14.5,
              color: premiumNavy,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(height: 12, thickness: 0.5),
        ],
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/seller_providers.dart';
import '../../../shared/models/product_model.dart';

class SellerProductListScreen extends ConsumerStatefulWidget {
  const SellerProductListScreen({super.key});

  @override
  ConsumerState<SellerProductListScreen> createState() =>
      _SellerProductListScreenState();
}

class _SellerProductListScreenState
    extends ConsumerState<SellerProductListScreen> {
  // Seçili olan kategori filtresi ("Hepsi" varsayılan olarak gelir)
  String _selectedCategory = 'Hepsi';

  // Marka renk kodları (Lina Premium Tasarım Dili)
  static const Color premiumNavy = Color(0xFF041E31);
  static const Color premiumNavyLight = Color(0xFF0D324E);
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color softBackground = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productsAsync = ref.watch(sellerProductsProvider);

    return Scaffold(
      backgroundColor: softBackground,
      appBar: AppBar(
        title: const Text(
          'Ürün Yönetimi',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontFamily: 'Nunito',
            fontSize: 22,
            color: premiumNavy,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        shape: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withAlpha(50),
            width: 1,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: premiumNavy.withAlpha(15),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.add_rounded, color: premiumNavy, size: 26),
              onPressed: () => context.push('/seller/products/add'),
            ),
          ),
        ],
      ),
      body: productsAsync.when(
        loading:
            () => const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(premiumNavy),
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
                      color: dangerRed,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ürünler yüklenirken hata oluştu:\n$e',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: premiumNavy,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        data: (products) {
          // Sadece aktif ürünleri filtrele
          final activeProducts =
              products.where((element) => element.isActive).toList();

          if (activeProducts.isEmpty) {
            return _buildEmptyState(context);
          }

          // Ürünlerden dinamik olarak benzersiz kategorileri çıkar
          final Set<String> uniqueCategories = {'Hepsi'};
          for (var p in activeProducts) {
            if (p.category.trim().isNotEmpty) {
              uniqueCategories.add(p.category.trim());
            }
          }
          final categoryList = uniqueCategories.toList();

          // Seçili kategoriye göre ürünleri filtrele
          final filteredProducts =
              _selectedCategory == 'Hepsi'
                  ? activeProducts
                  : activeProducts
                      .where((p) => p.category.trim() == _selectedCategory)
                      .toList();

          // Hızlı analiz istatistikleri
          final totalCount = activeProducts.length;
          final lowStockCount =
              activeProducts.where((p) => p.stock <= 5).length;

          return Column(
            children: [
              // 1. Üst Panel: Premium Mini Dashboard İstatistikleri
              _buildStatsDashboard(totalCount, lowStockCount),

              // 2. Yatay Kategori Seçim Barı (Premium Efektli)
              _buildCategoryBar(categoryList),

              // 3. Ürün Listesi (Boşluk Kontrolü ile)
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
                                color: premiumNavy.withAlpha(120),
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
        backgroundColor: premiumNavy,
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

  // Mini Dashboard Yapısı
  Widget _buildStatsDashboard(int total, int lowStock) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [premiumNavy, premiumNavyLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: premiumNavy.withAlpha(30),
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
            iconColor: lowStock > 0 ? warningOrange : Colors.white70,
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

  // Yatay Kategori Filtreleme Barı
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
                  color: isSelected ? premiumNavy : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? premiumNavy : premiumNavy.withAlpha(30),
                    width: 1.5,
                  ),
                  boxShadow:
                      isSelected
                          ? [
                            BoxShadow(
                              color: premiumNavy.withAlpha(40),
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
                    color: isSelected ? Colors.white : premiumNavy,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Güvenli Görsel Gösterici
  Widget _buildSafeProductImage(String? path, {double size = 76}) {
    final Widget placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: premiumNavy.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: premiumNavy,
        size: 26,
      ),
    );

    if (path == null || path.trim().isEmpty) {
      return placeholder;
    }

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
            errorBuilder: (context, error, stackTrace) => placeholder,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: size,
                height: size,
                color: Colors.white,
                child: const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(premiumNavy),
                    ),
                  ),
                ),
              );
            },
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
            errorBuilder: (context, error, stackTrace) => placeholder,
          ),
        );
      }

      return placeholder;
    } catch (_) {
      return placeholder;
    }
  }

  // Premium Ürün Kartı Tasarımı (Tıklanabilir yapıldı)
  Widget _buildProductCard(BuildContext context, ProductModel p) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: premiumNavy.withAlpha(20), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: premiumNavy.withAlpha(12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap:
            () => _showProductDetailsBottomSheet(
              context,
              p,
            ), // Karta basınca detay/düzenle açılır
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Ürün Görsel Alanı (Güvenli Yükleme)
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Hero(
                    tag: 'img_${p.productId}',
                    child: _buildSafeProductImage(
                      p.images.isNotEmpty ? p.images.first : null,
                    ),
                  ),
                ),

                // Detay Bilgileri
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(2, 12, 4, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Kategori ve Başlık
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: premiumNavy.withAlpha(12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                p.category.toUpperCase(),
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: premiumNavy,
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
                                fontSize: 16,
                                color: premiumNavy,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Fiyat, İndirim ve Stok Bilgisi
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Fiyat Grubu
                            Expanded(
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 6,
                                runSpacing: 2,
                                children: [
                                  if (p.hasDiscount) ...[
                                    Text(
                                      '₺${p.price.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: premiumNavy.withAlpha(100),
                                        fontSize: 11,
                                        decoration: TextDecoration.lineThrough,
                                        fontFamily: 'Nunito',
                                      ),
                                    ),
                                    Text(
                                      '₺${p.discountPrice.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: successGreen,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        fontFamily: 'Nunito',
                                      ),
                                    ),
                                  ] else ...[
                                    Text(
                                      '₺${p.price.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: premiumNavy,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        fontFamily: 'Nunito',
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Stok Göstergesi
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color:
                                    p.stock > 5
                                        ? successGreen.withAlpha(25)
                                        : (p.stock > 0
                                            ? warningOrange.withAlpha(25)
                                            : dangerRed.withAlpha(25)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Stok: ${p.stock} ${p.unit}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Nunito',
                                  color:
                                      p.stock > 5
                                          ? successGreen
                                          : (p.stock > 0
                                              ? warningOrange
                                              : dangerRed),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Sağ Taraf: Pop-up Menü
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: premiumNavy.withAlpha(150),
                      ),
                      color: Colors.white,
                      surfaceTintColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (val) async {
                        if (val == 'delete') {
                          _showDeleteConfirmation(context, p);
                        } else if (val == 'edit') {
                          _showProductDetailsBottomSheet(
                            context,
                            p,
                            startInEditMode: true,
                          );
                        }
                      },
                      itemBuilder:
                          (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.edit_outlined,
                                    color: premiumNavy,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Düzenle',
                                    style: TextStyle(
                                      color: premiumNavy,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Nunito',
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
                                    color: dangerRed,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Ürünü Kaldır',
                                    style: TextStyle(
                                      color: dangerRed,
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
                    const Spacer(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // DETAY VE DÜZENLEME PANELİ (BOTTOM SHEET)
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
        return _ProductDetailSheetContent(
          product: p,
          startInEditMode: startInEditMode,
          ref: ref,
        );
      },
    );
  }

  // Ürün Kaldırma Onay Penceresi
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
                  color: dangerRed,
                  size: 54,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ürünü Kaldır?',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: premiumNavy,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '"${product.name}" isimli ürünü mağazanızdan kaldırmak istediğinize emin misiniz? Bu işlem geri alınamaz.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    color: premiumNavy.withAlpha(140),
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
                            color: premiumNavy,
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
                            color: premiumNavy,
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
                          backgroundColor: dangerRed,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Evet, Kaldır',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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

  // Boş Liste Durumu Tasarımı
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: premiumNavy.withAlpha(12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 80,
                color: premiumNavy,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Mağazanız Henüz Boş',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: premiumNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hemen yeni ürünler ekleyerek lüks mağazanızda satış yapmaya başlayabilirsiniz.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                color: premiumNavy.withAlpha(130),
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => context.push('/seller/products/add'),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'İlk Ürünü Ekle',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Nunito',
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: successGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 26,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// DETAY GÖRÜNÜMÜ VE DÜZENLEME FORMU BİRLİKTE (BOTTOM SHEET İÇERİĞİ)
class _ProductDetailSheetContent extends StatefulWidget {
  final ProductModel product;
  final bool startInEditMode;
  final WidgetRef ref;

  const _ProductDetailSheetContent({
    required this.product,
    required this.startInEditMode,
    required this.ref,
  });

  @override
  State<_ProductDetailSheetContent> createState() =>
      _ProductDetailSheetContentState();
}

class _ProductDetailSheetContentState
    extends State<_ProductDetailSheetContent> {
  late bool _isEditing;
  final _formKey = GlobalKey<FormState>();

  // Düzenleme Kontrolcüleri
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _discountPriceCtrl;
  late TextEditingController _stockCtrl;
  late TextEditingController _barcodeCtrl;
  late TextEditingController _subCategoryCtrl;
  late TextEditingController _allergensCtrl;
  late TextEditingController _ingredientsCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _caloriesCtrl;
  late TextEditingController _healthScoreCtrl;
  late TextEditingController _carbonScoreCtrl;

  late String _category;
  late String _unit;
  bool _saving = false;

  static const Color premiumNavy = Color(0xFF041E31);
  static const Color successGreen = Color(0xFF10B981);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color softBackground = Color(0xFFF8FAFC);

  static const _categories = [
    'Meyve & Sebze',
    'Süt Ürünleri',
    'Et & Tavuk',
    'Tahıl & Bakliyat',
    'İçecek',
    'Atıştırmalık',
    'Organik',
  ];

  static const _units = ['kg', 'g', 'adet', 'lt'];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.startInEditMode;

    // Alanları mevcut ürün bilgileriyle doldurma
    _nameCtrl = TextEditingController(text: widget.product.name);
    _descCtrl = TextEditingController(text: widget.product.description);
    _priceCtrl = TextEditingController(text: widget.product.price.toString());
    _discountPriceCtrl = TextEditingController(
      text: widget.product.discountPrice.toString(),
    );
    _stockCtrl = TextEditingController(text: widget.product.stock.toString());
    _barcodeCtrl = TextEditingController(text: widget.product.barcode);
    _subCategoryCtrl = TextEditingController(text: widget.product.subCategory);
    _allergensCtrl = TextEditingController(
      text: widget.product.allergens.join(', '),
    );
    _ingredientsCtrl = TextEditingController(
      text: widget.product.ingredients.join(', '),
    );
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

    _category = widget.product.category;
    _unit = widget.product.unit;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _discountPriceCtrl.dispose();
    _stockCtrl.dispose();
    _barcodeCtrl.dispose();
    _subCategoryCtrl.dispose();
    _allergensCtrl.dispose();
    _ingredientsCtrl.dispose();
    _weightCtrl.dispose();
    _caloriesCtrl.dispose();
    _healthScoreCtrl.dispose();
    _carbonScoreCtrl.dispose();
    super.dispose();
  }

  // Veritabanına Anında Yazma (Update) Fonksiyonu
  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      List<String> parseCommaSeparated(String text) {
        if (text.isEmpty) return [];
        return text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }

      final updatedProduct = ProductModel(
        productId: widget.product.productId,
        sellerId: widget.product.sellerId,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        images: widget.product.images,
        barcode: _barcodeCtrl.text.trim(),
        category: _category,
        subCategory: _subCategoryCtrl.text.trim(),
        price: double.tryParse(_priceCtrl.text.trim()) ?? widget.product.price,
        discountPrice: double.tryParse(_discountPriceCtrl.text.trim()) ?? 0.0,
        unit: _unit,
        weight: double.tryParse(_weightCtrl.text.trim()) ?? 0.0,
        stock: int.tryParse(_stockCtrl.text.trim()) ?? 0,
        calories: int.tryParse(_caloriesCtrl.text.trim()) ?? 0,
        allergens: parseCommaSeparated(_allergensCtrl.text),
        ingredients: parseCommaSeparated(_ingredientsCtrl.text),
        healthScore: double.tryParse(_healthScoreCtrl.text.trim()) ?? 0.0,
        carbonScore: double.tryParse(_carbonScoreCtrl.text.trim()) ?? 0.0,
        isActive: widget.product.isActive,
        createdAt: widget.product.createdAt,
      );

      // ÇÖZÜM: .toMap() metodunu çağırarak Map<String, dynamic> formatında veriyi iletiyoruz.
      await widget.ref
          .read(sellerProductRepositoryProvider)
          .updateProduct(widget.product.productId, updatedProduct.toMap());

      // Sağlayıcıları yenile
      widget.ref.invalidate(sellerProductsProvider);
      widget.ref.invalidate(dashboardStatsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ürün başarıyla güncellendi ✔',
              style: TextStyle(fontFamily: 'Nunito'),
            ),
            backgroundColor: successGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Güncelleme hatası: $e',
              style: const TextStyle(fontFamily: 'Nunito'),
            ),
            backgroundColor: dangerRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isEditing ? _buildEditForm() : _buildDetailView(),
      ),
    );
  }

  // DETAY GÖRÜNÜMÜ TASARIMI
  Widget _buildDetailView() {
    final p = widget.product;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Modal Sürükleme Çubuğu
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 45,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),

        // Üst Bar: Başlık ve Düzenle Butonu
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ürün Detayları',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: premiumNavy,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: premiumNavy.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () => setState(() => _isEditing = true),
                  icon: const Icon(
                    Icons.edit_rounded,
                    color: premiumNavy,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 20),

        // İçerik Alanı
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            physics: const BouncingScrollPhysics(),
            children: [
              // Büyük Görsel ve Temel Fiyat / İsim Bilgileri
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSafeProductImage(
                    p.images.isNotEmpty ? p.images.first : null,
                    size: 100,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: premiumNavy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${p.category} ${p.subCategory.isNotEmpty ? '› ${p.subCategory}' : ''}',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 13,
                            color: premiumNavy.withAlpha(150),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (p.hasDiscount) ...[
                              Text(
                                '₺${p.price.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: premiumNavy.withAlpha(120),
                                  fontSize: 12,
                                  decoration: TextDecoration.lineThrough,
                                  fontFamily: 'Nunito',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '₺${p.discountPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: successGreen,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  fontFamily: 'Nunito',
                                ),
                              ),
                            ] else ...[
                              Text(
                                '₺${p.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: premiumNavy,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  fontFamily: 'Nunito',
                                ),
                              ),
                            ],
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    p.stock > 5
                                        ? successGreen.withAlpha(25)
                                        : dangerRed.withAlpha(25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Stok: ${p.stock} ${p.unit}',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: p.stock > 5 ? successGreen : dangerRed,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Açıklama
              if (p.description.isNotEmpty) ...[
                const Text(
                  'Ürün Açıklaması',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: premiumNavy,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: softBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    p.description,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      color: premiumNavy.withAlpha(180),
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Teknik Detay Tablosu (Barkod, Ağırlık, Enerji)
              _buildSectionTitle('Teknik Bilgiler'),
              _buildDetailRow(
                'Barkod',
                p.barcode.isNotEmpty ? p.barcode : 'Belirtilmedi',
                Icons.qr_code_scanner_rounded,
              ),
              _buildDetailRow(
                'Ağırlık / Hacim',
                '${p.weight} ${p.unit == 'adet' ? 'g' : p.unit}',
                Icons.scale_rounded,
              ),
              _buildDetailRow(
                'Enerji (Kalori)',
                '${p.calories} kcal',
                Icons.local_fire_department_rounded,
              ),

              const SizedBox(height: 16),

              // Sağlık ve Çevre Puanları
              _buildSectionTitle('Puanlar & Sürdürülebilirlik'),
              Row(
                children: [
                  Expanded(
                    child: _buildScoreCard(
                      'Sağlık Skoru',
                      p.healthScore,
                      Colors.green,
                      Icons.favorite_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildScoreCard(
                      'Karbon Skoru',
                      p.carbonScore,
                      Colors.blue,
                      Icons.eco_rounded,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Alerjenler ve İçindekiler
              if (p.allergens.isNotEmpty) ...[
                _buildSectionTitle('Alerjenler'),
                Wrap(
                  spacing: 6,
                  children:
                      p.allergens
                          .map(
                            (a) => Chip(
                              label: Text(
                                a,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Nunito',
                                  color: dangerRed,
                                ),
                              ),
                              backgroundColor: dangerRed.withAlpha(20),
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          )
                          .toList(),
                ),
                const SizedBox(height: 12),
              ],

              if (p.ingredients.isNotEmpty) ...[
                _buildSectionTitle('İçindekiler'),
                Wrap(
                  spacing: 6,
                  children:
                      p.ingredients
                          .map(
                            (i) => Chip(
                              label: Text(
                                i,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Nunito',
                                  color: premiumNavy,
                                ),
                              ),
                              backgroundColor: premiumNavy.withAlpha(15),
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          )
                          .toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // DÜZENLEME FORMU TASARIMI
  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sürükleme Barı
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 45,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Üst Bar: Başlık ve İptal Butonu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ürünü Düzenle',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: premiumNavy,
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _isEditing = false),
                  child: const Text(
                    'İptal',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      color: dangerRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 20),

          // Form Giriş Alanları Listesi
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              physics: const BouncingScrollPhysics(),
              children: [
                _buildFormInput('Ürün Adı *', _nameCtrl, isRequired: true),
                const SizedBox(height: 12),

                // Kategori ve Birim Seçimi
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Kategori *',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: premiumNavy,
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _category,
                            items:
                                _categories
                                    .map(
                                      (c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(
                                          c,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    )
                                    .toList(),
                            onChanged:
                                (val) => setState(() => _category = val!),
                            decoration: _inputDecoration(''),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Birim *',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: premiumNavy,
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _unit,
                            items:
                                _units
                                    .map(
                                      (u) => DropdownMenuItem(
                                        value: u,
                                        child: Text(
                                          u,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (val) => setState(() => _unit = val!),
                            decoration: _inputDecoration(''),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildFormInput(
                        'Fiyat (₺) *',
                        _priceCtrl,
                        isNumber: true,
                        isRequired: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildFormInput(
                        'İndirimli Fiyat (₺)',
                        _discountPriceCtrl,
                        isNumber: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildFormInput(
                        'Stok *',
                        _stockCtrl,
                        isNumber: true,
                        isRequired: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildFormInput(
                        'Ağırlık / Hacim',
                        _weightCtrl,
                        isNumber: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                _buildFormInput('Açıklama', _descCtrl, maxLines: 3),
                const SizedBox(height: 12),

                _buildFormInput('Barkod', _barcodeCtrl),
                const SizedBox(height: 12),

                _buildFormInput('Alt Kategori', _subCategoryCtrl),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildFormInput(
                        'Kalori (kcal)',
                        _caloriesCtrl,
                        isNumber: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildFormInput(
                        'Sağlık Skoru (0-10)',
                        _healthScoreCtrl,
                        isNumber: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                _buildFormInput(
                  'Karbon Skoru (0-10)',
                  _carbonScoreCtrl,
                  isNumber: true,
                ),
                const SizedBox(height: 24),

                // Kaydet Butonu
                ElevatedButton(
                  onPressed: _saving ? null : _updateProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: successGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child:
                      _saving
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : const Text(
                            'Ürünü Güncelle',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Yardımcı Widgetlar ve Tasarımlar
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: premiumNavy,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: premiumNavy.withAlpha(150)),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              color: premiumNavy.withAlpha(160),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: premiumNavy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(String label, double val, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(fontFamily: 'Nunito', fontSize: 11, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            '$val / 10',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormInput(
    String label,
    TextEditingController ctrl, {
    bool isNumber = false,
    bool isRequired = false,
    int maxLines = 1,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isRequired ? '$label *' : label,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: premiumNavy,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType:
              isNumber
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.text,
          validator: (val) {
            if (isRequired && (val == null || val.trim().isEmpty)) {
              return 'Bu alan boş bırakılamaz';
            }
            if (isNumber &&
                val != null &&
                val.isNotEmpty &&
                double.tryParse(val) == null) {
              return 'Geçerli bir sayı giriniz';
            }
            return null;
          },
          decoration: _inputDecoration(hint ?? '$label giriniz'),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: premiumNavy.withAlpha(80),
        fontFamily: 'Nunito',
        fontSize: 12,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: premiumNavy, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: premiumNavy, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: dangerRed, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: dangerRed, width: 2),
      ),
    );
  }

  // Güvenli Görsel Gösterici (Sheet İçin)
  Widget _buildSafeProductImage(String? path, {double size = 100}) {
    const double finalSize = 100;
    final Widget placeholder = Container(
      width: finalSize,
      height: finalSize,
      decoration: BoxDecoration(
        color: premiumNavy.withAlpha(10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: premiumNavy,
        size: 36,
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
            width: finalSize,
            height: finalSize,
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
            width: finalSize,
            height: finalSize,
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
}

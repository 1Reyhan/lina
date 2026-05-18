import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/product_repository.dart';
import '../../../shared/models/product_model.dart';
import '../../../shared/models/cart_model.dart';
import '../../../shared/models/campaign_model.dart';
import '../../cart/providers/cart_providers.dart';
import 'widgets/product_card.dart';

// Orijinal ürün kategorilerin (Model yapınla ve CategoryFilter ile tam uyumlu)
const List<String> _homeCategories = [
  'Tümü',
  'Meyve & Sebze',
  'Süt Ürünleri',
  'Et & Tavuk',
  'Tahıl & Bakliyat',
  'İçecek',
  'Atıştırmalık',
  'Organik',
];

final _productRepoProvider = Provider((ref) => ProductRepository());
final _productsProvider = StreamProvider.family<List<ProductModel>, String>((
  ref,
  category,
) {
  return ref.watch(_productRepoProvider).getProducts(category: category);
});

final _selectedCategoryProvider = StateProvider<String>((ref) => 'Tümü');

// Firestore'daki gerçek ve aktif olan satıcı kampanyalarını anlık dinleyen StreamProvider
final _activeCampaignsProvider = StreamProvider<List<CampaignModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('campaigns')
      .where('isActive', isEqualTo: true)
      .snapshots()
      .map(
        (snap) =>
            snap.docs.map((doc) => CampaignModel.fromFirestore(doc)).toList(),
      );
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Lina Premium Tasarım Renk Kodları
  static const Color premiumNavy = Color(0xFF041E31);
  static const Color premiumBlueAccent = Color(0xFF0D324E);
  static const Color softBackground = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _homeCategories.length, vsync: this);

    // Parmağıyla kaydırınca TabBar ve Grid içeriklerini senkronize eden dinleyici
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(_selectedCategoryProvider.notifier).state =
            _homeCategories[_tabController.index];
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Kategori seçildiğinde TabController indexini de dinamik olarak günceller
    final selectedCat = ref.watch(_selectedCategoryProvider);
    final tabIndex = _homeCategories.indexOf(selectedCat);
    if (tabIndex != -1 && tabIndex != _tabController.index) {
      _tabController.index = tabIndex;
    }

    final campaignsAsync = ref.watch(_activeCampaignsProvider);
    final cartCount = ref.watch(cartItemCountProvider);
    final campaigns = campaignsAsync.valueOrNull ?? [];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: softBackground,
      drawer: _buildPremiumDrawer(context), // Sol çekmece menüsü
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            // 1. Üst Başlık - MoreSugar Fontlu LINA Dev Logo
            SliverAppBar(
              floating: true,
              pinned: true,
              backgroundColor: Colors.white,
              elevation: 0,
              scrolledUnderElevation: 1,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(
                  Icons.menu_rounded,
                  color: premiumNavy,
                  size: 28,
                ),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              centerTitle: true,
              title: const Text(
                'LINA',
                style: TextStyle(
                  fontFamily: 'MoreSugar',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 6,
                  color: premiumNavy,
                ),
              ),
              actions: [
                _buildCartIcon(context, cartCount),
                IconButton(
                  icon: const Icon(
                    Icons.person_outline_rounded,
                    color: premiumNavy,
                    size: 26,
                  ),
                  onPressed: () => context.push('/profile'),
                ),
                const SizedBox(width: 8),
              ],
            ),

            // 2. Arama Kutusu
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: GestureDetector(
                  onTap: () => context.push('/search'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: premiumNavy.withValues(alpha: 0.08),
                      ),
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
                        const Icon(
                          Icons.search_rounded,
                          color: premiumNavy,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Ürün veya kategori ara...',
                          style: TextStyle(
                            color: premiumNavy,
                            fontSize: 14,
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 3. Kategori Filtre Kapsülleri (Swipe kaydırma destekli)
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverCategoryDelegate(
                child: Container(
                  color: softBackground,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    physics: const BouncingScrollPhysics(),
                    indicator: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [premiumNavy, premiumBlueAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: premiumNavy.withValues(alpha: 0.7),
                    labelStyle: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    tabs:
                        _homeCategories.map((cat) {
                          return Tab(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color:
                                      _tabController.index ==
                                              _homeCategories.indexOf(cat)
                                          ? Colors.transparent
                                          : premiumNavy.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Align(
                                alignment: Alignment.center,
                                child: Text(cat),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ),
            ),
          ];
        },
        // 4. Parmakla Sağa-Sola Kaydırılabilir Alan (Dinamik TabBarView)
        body: TabBarView(
          controller: _tabController,
          children:
              _homeCategories.map((category) {
                return _buildProductGrid(category, campaigns);
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildProductGrid(String category, List<CampaignModel> campaigns) {
    final productsAsync = ref.watch(_productsProvider(category));

    return productsAsync.when(
      loading:
          () => const Center(
            child: CircularProgressIndicator(color: premiumNavy),
          ),
      error: (e, _) => Center(child: Text('Hata: $e')),
      data: (products) {
        if (products.isEmpty) {
          return const Center(
            child: Text(
              'Bu kategoride ürün bulunamadı.',
              style: TextStyle(fontFamily: 'Nunito'),
            ),
          );
        }

        return GridView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio:
                0.63, // Sığma sorunlarını ve taşmaları çözen kusursuz oran
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final p = products[index];
            return ProductCard(
              product: p,
              activeCampaigns:
                  campaigns, // Veritabanındaki gerçek kampanyalar karta paslanır
              onTap: () => context.push('/product/${p.productId}'),
              onAddToCart: () => _handleAddToCart(context, ref, p, campaigns),
            );
          },
        );
      },
    );
  }

  // Sol Üst Çekmece Menüsü
  Widget _buildPremiumDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [premiumNavy, premiumBlueAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LINA',
                  style: TextStyle(
                    fontFamily: 'MoreSugar',
                    fontSize: 32,
                    letterSpacing: 6,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Kategoriler Arası Hızlı Keşif',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              itemCount: _homeCategories.length,
              itemBuilder: (context, index) {
                final cat = _homeCategories[index];
                return ListTile(
                  leading: const Icon(
                    Icons.label_important_outline_rounded,
                    color: premiumNavy,
                    size: 20,
                  ),
                  title: Text(
                    cat,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                      color: premiumNavy,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                  onTap: () {
                    ref.read(_selectedCategoryProvider.notifier).state = cat;
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartIcon(BuildContext context, int count) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(
            Icons.shopping_cart_outlined,
            color: premiumNavy,
            size: 26,
          ),
          onPressed: () => context.push('/cart'),
        ),
        if (count > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _handleAddToCart(
    BuildContext context,
    WidgetRef ref,
    ProductModel p,
    List<CampaignModel> campaigns,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      context.push('/login');
      return;
    }

    // Sepete ekleme esnasında satıcının bu ürüne tanımladığı en yüksek kampanya oranını bul
    double maxDiscount = 0.0;
    for (final camp in campaigns) {
      if (camp.sellerId == p.sellerId) {
        final appliesToAll = camp.productIds.isEmpty;
        final appliesToThisProduct = camp.productIds.contains(p.productId);

        if (appliesToAll || appliesToThisProduct) {
          if (camp.discountRate > maxDiscount) {
            maxDiscount = camp.discountRate;
          }
        }
      }
    }

    // İndirimli gerçek fiyatı hesaplar
    final finalPrice =
        maxDiscount > 0
            ? p.effectivePrice * (1 - (maxDiscount / 100))
            : p.effectivePrice;

    await ref
        .read(cartRepositoryProvider)
        .addToCart(
          user.uid,
          CartItemModel(
            productId: p.productId,
            sellerId: p.sellerId,
            name: p.name,
            image: p.images.isNotEmpty ? p.images.first : '',
            price: finalPrice,
            quantity: 1,
          ),
        );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${p.name} sepete eklendi! ✔'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _SliverCategoryDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _SliverCategoryDelegate({required this.child});

  @override
  double get minExtent => 64;
  @override
  double get maxExtent => 64;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => child;
  @override
  bool shouldRebuild(covariant _SliverCategoryDelegate oldDelegate) => false;
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/product_repository.dart';
import '../../../shared/models/product_model.dart';
import '../../../shared/models/cart_model.dart';
import '../../cart/providers/cart_providers.dart';
import 'widgets/category_filter.dart';
import 'widgets/product_card.dart';

// Ana sayfa için ürün sağlayıcısı
final _productRepoProvider = Provider((ref) => ProductRepository());
final _productsProvider = StreamProvider.family<List<ProductModel>, String>((
  ref,
  category,
) {
  return ref.watch(_productRepoProvider).getProducts(category: category);
});

final _selectedCategoryProvider = StateProvider<String>((ref) => 'Tümü');

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCat = ref.watch(_selectedCategoryProvider);
    final productsAsync = ref.watch(_productsProvider(selectedCat));
    final cartCount = ref.watch(cartItemCountProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // 1. Üst Başlık ve Sepet/Profil İkonları
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: false,
            title: const Text(
              'lina',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 28,
                letterSpacing: -0.5,
              ),
            ),
            actions: [
              _buildCartIcon(context, cartCount),
              IconButton(
                icon: const Icon(Icons.person_outline, color: Colors.black),
                onPressed: () => context.push('/profile'),
              ),
              const SizedBox(width: 8),
            ],
          ),

          // 2. Arama Kutusu (Kaydırınca başlık ile beraber hareket eder)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: GestureDetector(
                onTap:
                    () => context.push('/search'), // Arama sayfasına yönlendir
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: Colors.grey.shade600),
                      const SizedBox(width: 12),
                      Text(
                        'Ürün veya kategori ara...',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. Kategori Filtresi (Yukarı kaysak da en üstte sabit kalır)
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverCategoryDelegate(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: CategoryFilter(
                  selected: selectedCat,
                  onSelected:
                      (c) =>
                          ref.read(_selectedCategoryProvider.notifier).state =
                              c,
                ),
              ),
            ),
          ),

          // 4. Ürün Listesi (Grid)
          productsAsync.when(
            loading:
                () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
            error:
                (e, _) =>
                    SliverFillRemaining(child: Center(child: Text('Hata: $e'))),
            data: (products) {
              if (products.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text('Bu kategoride ürün bulunamadı.')),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.70, // Kart tasarımı için ideal oran
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final p = products[index];
                    return ProductCard(
                      product: p,
                      onTap: () => context.push('/product/${p.productId}'),
                      onAddToCart: () => _handleAddToCart(context, ref, p),
                    );
                  }, childCount: products.length),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Sepet İkonu ve Badge (Kırmızı Nokta)
  Widget _buildCartIcon(BuildContext context, int count) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black),
          onPressed: () => context.push('/cart'),
        ),
        if (count > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  // Sepete Ekleme Mantığı
  Future<void> _handleAddToCart(
    BuildContext context,
    WidgetRef ref,
    ProductModel p,
  ) async {
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
            productId: p.productId,
            sellerId: p.sellerId,
            name: p.name,
            image: p.images.isNotEmpty ? p.images.first : '',
            price: p.effectivePrice,
          ),
        );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${p.name} sepete eklendi'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green.shade700,
        ),
      );
    }
  }
}

// Kategorileri yukarıda sabitlemek için gereken yardımcı sınıf
class _SliverCategoryDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _SliverCategoryDelegate({required this.child});

  @override
  double get minExtent => 60;
  @override
  double get maxExtent => 60;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _SliverCategoryDelegate oldDelegate) => false;
}

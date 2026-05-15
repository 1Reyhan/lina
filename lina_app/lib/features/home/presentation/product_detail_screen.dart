import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/product_repository.dart';
import '../../../shared/models/product_model.dart';
import '../../../shared/models/cart_model.dart';
import '../../cart/providers/cart_providers.dart';
import '../../profile/providers/profile_providers.dart';

final _productDetailProvider = FutureProvider.family<ProductModel?, String>((
  ref,
  id,
) {
  return ProductRepository().getProduct(id);
});

class ProductDetailScreen extends ConsumerWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(_productDetailProvider(productId));
    final userAllergies = ref.watch(userAllergiesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (product) {
          if (product == null)
            return const Center(child: Text('Ürün bulunamadı'));

          final riskyAllergens =
              product.allergens
                  .where((a) => userAllergies.contains(a))
                  .toList();

          return CustomScrollView(
            slivers: [
              _buildAppBar(context, product),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (riskyAllergens.isNotEmpty)
                        _buildAllergyWarning(riskyAllergens),
                      _buildHeader(product),
                      const SizedBox(height: 20),
                      _buildAIScores(product),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Açıklama'),
                      Text(
                        product.description,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle('İçindekiler'),
                      Text(
                        product.ingredients.join(', '),
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 24),
                      _buildBesinDegerleri(product),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
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

  Widget _buildAllergyWarning(List<String> riskyAllergens) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'DİKKAT: Profilindeki şu alerjenleri içeriyor: ${riskyAllergens.join(", ")}',
              style: TextStyle(
                color: Colors.red.shade900,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
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
          'AI Sağlık Puanı',
          product.healthScore.toStringAsFixed(1),
          Colors.orange,
        ),
        const SizedBox(width: 12),
        _scoreBox(
          'Karbon İzimiz',
          '${product.carbonScore.toInt()}',
          Colors.green,
        ),
      ],
    );
  }

  Widget _scoreBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withAlpha(25), // withOpacity yerine yeni standart
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(75)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, ProductModel product) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background:
            product.images.isNotEmpty
                ? Image.network(product.images.first, fit: BoxFit.cover)
                : Container(color: Colors.grey.shade200),
      ),
    );
  }

  Widget _buildHeader(ProductModel product) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                product.category,
                style: TextStyle(color: Colors.green.shade700),
              ),
            ],
          ),
        ),
        Text(
          '₺${product.effectivePrice.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildBesinDegerleri(ProductModel product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Besin Değerleri'),
        _InfoRow(
          label: 'Kalori (100g için)',
          value: '${product.calories} kcal',
        ),
        _InfoRow(label: 'Birim', value: product.unit),
        _InfoRow(label: 'Miktar', value: '${product.weight} ${product.unit}'),
      ],
    );
  }
}

// --- EKSİK OLAN ALT SINIFLAR BURADA ---

class _AddToCartBar extends ConsumerWidget {
  final ProductModel product;
  const _AddToCartBar({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            'Stok: ${product.stock} ${product.unit}',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed:
                product.stock > 0
                    ? () async {
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
                            content: Text('${product.name} sepete eklendi'),
                            backgroundColor: Colors.green.shade700,
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      }
                    }
                    : null,
            icon: const Icon(Icons.shopping_cart_outlined),
            label: Text(product.stock > 0 ? 'Sepete Ekle' : 'Stok Yok'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

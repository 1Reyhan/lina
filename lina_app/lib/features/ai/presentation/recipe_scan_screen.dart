import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';

// İlgili modül, model ve sağlayıcı importları
import '../providers/ai_providers.dart';
import '../../cart/providers/cart_providers.dart';
import '../../../shared/models/cart_model.dart';
import '../../../shared/models/product_model.dart';
// 🌟 DÜZELTİLDİ: ProductRepository'nin gerçek dosya yolu doğrudan import edildi
import '../../home/data/product_repository.dart';

const Color kPremiumNavy = Color(0xFF041E31);
const Color kAccentGreen = Color(0xFF2ECC71);
const Color kLightBackground = Color(0xFFF8FAFC);

// Ürün Arama İşlemleri için ProductRepository Provider Yapısı
final _productRepoProvider = Provider((ref) => ProductRepository());

// Arama sonuçlarını listeleyen FutureProvider
final _ingredientSearchProvider =
    FutureProvider.family<List<ProductModel>, String>((ref, query) async {
      if (query.isEmpty) return [];
      final repo = ref.read(_productRepoProvider);
      // Tüm ürünleri çekip başlıklarında akıllıca filtreleme yapıyoruz
      final allProducts = await repo.getProducts(category: 'Tümü').first;
      return allProducts
          .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });

class RecipeScanScreen extends ConsumerStatefulWidget {
  const RecipeScanScreen({super.key});

  @override
  ConsumerState<RecipeScanScreen> createState() => _RecipeScanScreenState();
}

class _RecipeScanScreenState extends ConsumerState<RecipeScanScreen> {
  Uint8List? _imageBytes;
  List<String> _ingredients = [];
  bool _loading = false;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _ingredients = [];
    });
    await _analyze(bytes);
  }

  Future<void> _analyze(Uint8List bytes) async {
    setState(() => _loading = true);
    try {
      final ingredients = await ref
          .read(geminiRepositoryProvider)
          .analyzeRecipeImage(bytes);
      if (mounted) {
        setState(() {
          _ingredients = ingredients;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLightBackground,
      appBar: AppBar(
        title: const Text(
          'Tarif Analizi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: kPremiumNavy,
            fontFamily: 'Nunito',
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ImageSelector(
              imageBytes: _imageBytes,
              onTap: _showImageSourceDialog,
            ),
            const SizedBox(height: 24),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: kPremiumNavy),
                      SizedBox(height: 16),
                      Text(
                        'Lina AI Malzemeleri Çıkarıyor...',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.bold,
                          color: kPremiumNavy,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_ingredients.isNotEmpty) ...[
              const Text(
                'Algılanan Malzemeler ve Mağaza Eşleşmeleri',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kPremiumNavy,
                  fontFamily: 'Nunito',
                ),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _ingredients.length,
                itemBuilder: (context, index) {
                  final ingredient = _ingredients[index];
                  return _IngredientMatchTile(ingredient: ingredient);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (_) => Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Görsel Yükle',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kPremiumNavy,
                    fontFamily: 'Nunito',
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: kPremiumNavy),
                  title: const Text(
                    'Fotoğraf Çek',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: kPremiumNavy),
                  title: const Text(
                    'Galeriden Seç',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
    );
  }
}

class _ImageSelector extends StatelessWidget {
  final Uint8List? imageBytes;
  final VoidCallback onTap;
  const _ImageSelector({this.imageBytes, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kPremiumNavy.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: kPremiumNavy.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child:
            imageBytes != null
                ? ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.memory(imageBytes!, fit: BoxFit.cover),
                )
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add_a_photo_outlined,
                      size: 40,
                      color: kPremiumNavy,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Yemek veya Malzeme Görseli Yükle',
                      style: TextStyle(
                        color: kPremiumNavy,
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Yapay zeka malzemeleri bulup mağazadan getirir.',
                      style: TextStyle(
                        color: kPremiumNavy.withValues(alpha: 0.5),
                        fontFamily: 'Nunito',
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}

/// Her bir çıkarılan malzeme için veritabanında arama yapan ve gerçek ürünleri sunan akıllı Tile
class _IngredientMatchTile extends ConsumerWidget {
  final String ingredient;
  const _IngredientMatchTile({required this.ingredient});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchAsync = ref.watch(_ingredientSearchProvider(ingredient));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPremiumNavy.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.shopping_basket_outlined,
                color: kAccentGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              // 🌟 DÜZELTİLDİ: 'const FontWeight.extrabold' ve 'invalid_constant' hatalarını önlemek için 'const' kaldırıldı ve standarda ('FontWeight.w800') çekildi.
              Text(
                ingredient.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Nunito',
                  color: kPremiumNavy,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          searchAsync.when(
            loading:
                () => const LinearProgressIndicator(
                  color: kPremiumNavy,
                  backgroundColor: Colors.black12,
                ),
            error:
                (e, _) => Text(
                  'Arama Hatası: $e',
                  style: const TextStyle(fontSize: 11, color: Colors.red),
                ),
            data: (products) {
              if (products.isEmpty) {
                return Text(
                  'Mağazada "$ingredient" ile eşleşen ürün bulunamadı.',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: kPremiumNavy.withValues(alpha: 0.5),
                    fontFamily: 'Nunito',
                  ),
                );
              }

              return Column(
                children:
                    products.map((product) {
                      return _ProductMiniTile(product: product);
                    }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Eşleşen ürünlerin listelendiği ve anında sepete eklenebildiği mini arayüz
class _ProductMiniTile extends ConsumerWidget {
  final ProductModel product;
  const _ProductMiniTile({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: kLightBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Ürün Görseli
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child:
                product.images.isNotEmpty
                    ? Image.network(
                      product.images.first,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildFallbackIcon(),
                    )
                    : _buildFallbackIcon(),
          ),
          const SizedBox(width: 12),
          // Ürün Adı & Fiyatı
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: kPremiumNavy,
                    fontFamily: 'Nunito',
                  ),
                ),
                Text(
                  '${product.effectivePrice.toStringAsFixed(2)} ₺',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: kAccentGreen,
                  ),
                ),
              ],
            ),
          ),
          // Sepete Ekle Butonu
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kPremiumNavy,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => _addToCart(context, ref),
            child: const Row(
              children: [
                Icon(Icons.add_shopping_cart, size: 14, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'Ekle',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Nunito',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackIcon() {
    return Container(
      width: 44,
      height: 44,
      color: Colors.white,
      child: const Icon(Icons.shopping_basket, color: kPremiumNavy, size: 20),
    );
  }

  Future<void> _addToCart(BuildContext context, WidgetRef ref) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lütfen önce giriş yapın.')));
      return;
    }

    try {
      await ref
          .read(cartRepositoryProvider)
          .addToCart(
            user.uid,
            CartItemModel(
              productId: product.productId,
              sellerId: product.sellerId,
              name: product.name,
              image: product.images.isNotEmpty ? product.images.first : '',
              price: product.effectivePrice,
              quantity: 1,
            ),
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} sepete eklendi! ✔'),
            backgroundColor: kAccentGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sepete eklenemedi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

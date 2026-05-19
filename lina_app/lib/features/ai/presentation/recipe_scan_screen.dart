import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../providers/ai_providers.dart';
import '../../cart/providers/cart_providers.dart';
import '../../../shared/models/cart_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

const Color kPremiumNavy = Color(0xFF041E31);
const Color kAccentGreen = Color(0xFF2ECC71);

class RecipeScanScreen extends ConsumerStatefulWidget {
  const RecipeScanScreen({super.key});

  @override
  ConsumerState<RecipeScanScreen> createState() => _RecipeScanScreenState();
}

class _RecipeScanScreenState extends ConsumerState<RecipeScanScreen> {
  Uint8List? _imageBytes;
  List<String> _ingredients = [];
  bool _loading = false;
  bool _addingToCart = false;

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

  Future<void> _addAllToCart() async {
    if (_ingredients.isEmpty) return;
    setState(() => _addingToCart = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      for (final ingredient in _ingredients) {
        await ref
            .read(cartRepositoryProvider)
            .addToCart(
              uid,
              CartItemModel(
                productId: 'ingredient_$ingredient',
                sellerId: '',
                name: ingredient,
                price: 0,
              ),
            );
      }
    }
    setState(() => _addingToCart = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_ingredients.length} malzeme sepete eklendi!'),
          backgroundColor: kAccentGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Lina AI ile Keşfet',
          style: TextStyle(fontWeight: FontWeight.bold, color: kPremiumNavy),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _ImageSelector(
              imageBytes: _imageBytes,
              onTap: _showImageSourceDialog,
            ),
            const SizedBox(height: 32),
            if (_loading)
              const Center(
                child: CircularProgressIndicator(color: kAccentGreen),
              ),
            if (_ingredients.isNotEmpty)
              _IngredientsResultView(
                ingredients: _ingredients,
                addingToCart: _addingToCart,
                onAddAll: _addAllToCart,
              ),
          ],
        ),
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder:
          (_) => Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Tarif Analizi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: kAccentGreen),
                  title: const Text('Fotoğraf Çek'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: kAccentGreen),
                  title: const Text('Galeriden Seç'),
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
        height: 240,
        width: double.infinity,
        decoration: BoxDecoration(
          color: kPremiumNavy.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: kPremiumNavy.withValues(alpha: 0.1)),
        ),
        child:
            imageBytes != null
                ? ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.memory(imageBytes!, fit: BoxFit.cover),
                )
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add_a_photo,
                      size: 48,
                      color: kPremiumNavy,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tarif Fotoğrafı Yükle',
                      style: TextStyle(
                        color: kPremiumNavy.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}

class _IngredientsResultView extends StatelessWidget {
  final List<String> ingredients;
  final bool addingToCart;
  final VoidCallback onAddAll;
  const _IngredientsResultView({
    required this.ingredients,
    required this.addingToCart,
    required this.onAddAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Algılanan Malzemeler',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: kPremiumNavy,
          ),
        ),
        const SizedBox(height: 16),
        ...ingredients.map(
          (ing) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ListTile(
              leading: const Icon(Icons.check_circle, color: kAccentGreen),
              title: Text(
                ing,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: addingToCart ? null : onAddAll,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPremiumNavy,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              addingToCart ? 'Ekleniyor...' : 'Tümünü Sepete Ekle',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

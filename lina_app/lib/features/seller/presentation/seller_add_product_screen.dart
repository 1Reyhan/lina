import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/seller_providers.dart';
import '../../../shared/models/product_model.dart';

class SellerAddProductScreen extends ConsumerStatefulWidget {
  const SellerAddProductScreen({super.key});

  @override
  ConsumerState<SellerAddProductScreen> createState() =>
      _SellerAddProductScreenState();
}

class _SellerAddProductScreenState
    extends ConsumerState<SellerAddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  // Model alanlarının tamamını kapsayan kontrolcüler
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _discountPriceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _caloriesCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _subCategoryCtrl = TextEditingController();
  final _allergensCtrl = TextEditingController();
  final _ingredientsCtrl = TextEditingController();
  final _healthScoreCtrl = TextEditingController();
  final _carbonScoreCtrl = TextEditingController();

  String _category = 'Meyve & Sebze';
  String _unit = 'adet';
  bool _loading = false;

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
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _discountPriceCtrl.dispose();
    _stockCtrl.dispose();
    _weightCtrl.dispose();
    _caloriesCtrl.dispose();
    _barcodeCtrl.dispose();
    _subCategoryCtrl.dispose();
    _allergensCtrl.dispose();
    _ingredientsCtrl.dispose();
    _healthScoreCtrl.dispose();
    _carbonScoreCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Kullanıcı oturumu bulunamadı.');

      List<String> parseCommaSeparated(String text) {
        if (text.isEmpty) return [];
        return text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }

      final product = ProductModel(
        productId: '',
        sellerId: uid,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        barcode: _barcodeCtrl.text.trim(),
        category: _category,
        subCategory: _subCategoryCtrl.text.trim(),
        price: double.tryParse(_priceCtrl.text.trim()) ?? 0.0,
        discountPrice: double.tryParse(_discountPriceCtrl.text.trim()) ?? 0.0,
        unit: _unit,
        weight: double.tryParse(_weightCtrl.text.trim()) ?? 0.0,
        stock: int.tryParse(_stockCtrl.text.trim()) ?? 0,
        calories: int.tryParse(_caloriesCtrl.text.trim()) ?? 0,
        allergens: parseCommaSeparated(_allergensCtrl.text),
        ingredients: parseCommaSeparated(_ingredientsCtrl.text),
        healthScore: double.tryParse(_healthScoreCtrl.text.trim()) ?? 0.0,
        carbonScore: double.tryParse(_carbonScoreCtrl.text.trim()) ?? 0.0,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await ref.read(sellerProductRepositoryProvider).addProduct(product);

      ref.invalidate(dashboardStatsProvider);

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ürün başarıyla mağazanıza eklendi',
              style: TextStyle(fontFamily: 'Nunito'),
            ),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'faz3 Ürün ekleme hatası: $e',
              style: const TextStyle(fontFamily: 'Nunito'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // HATA 1 DÜZELTİLDİ: İpuçları (hintText) için fonksiyona opsiyonel [String? hint] parametresi eklendi
    InputDecoration modernInputDecoration(String label, {String? hint}) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(
          color: theme.colorScheme.onSurface.withAlpha(80),
          fontFamily: 'Nunito',
          fontSize: 13,
        ),
        labelStyle: TextStyle(
          color: theme.colorScheme.onSurface.withAlpha(140),
          fontFamily: 'Nunito',
          fontSize: 14,
        ),
        floatingLabelStyle: const TextStyle(
          color: Color(0xFF10B981),
          fontWeight: FontWeight.bold,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.outlineVariant.withAlpha(102),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.error, width: 1.5),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Yeni Ürün Ekle',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Nunito',
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withAlpha(76),
            width: 1,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child:
                _loading
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF10B981),
                      ),
                    )
                    : const Text(
                      'Kaydet',
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Nunito',
                        fontSize: 15,
                      ),
                    ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 1. KART: Temel Kimlik Bilgileri
              _FormCard(
                title: 'Temel Bilgiler',
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: modernInputDecoration('Ürün Adı *'),
                    validator:
                        (v) =>
                            v == null || v.trim().isEmpty
                                ? 'Ürün adı zorunludur'
                                : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _descCtrl,
                    decoration: modernInputDecoration('Ürün Açıklaması'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _barcodeCtrl,
                    decoration: modernInputDecoration(
                      'Barkod Numarası (GTIN/EAN)',
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _category,
                          decoration: modernInputDecoration('Ana Kategori'),
                          dropdownColor: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          items:
                              _categories
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(
                                        c,
                                        style: const TextStyle(
                                          fontFamily: 'Nunito',
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) => setState(() => _category = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _subCategoryCtrl,
                          decoration: modernInputDecoration('Alt Kategori'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 2. KART: Ticari Maliyet ve Stok Sayımları
              _FormCard(
                title: 'Fiyat & Stok Yönetimi',
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceCtrl,
                          decoration: modernInputDecoration(
                            'Satış Fiyatı (₺) *',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator:
                              (v) =>
                                  v == null || v.trim().isEmpty
                                      ? 'Fiyat zorunludur'
                                      : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _discountPriceCtrl,
                          decoration: modernInputDecoration(
                            'İndirimli Fiyat (₺)',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _stockCtrl,
                          decoration: modernInputDecoration(
                            'Mevcut Stok Adedi *',
                          ),
                          keyboardType: TextInputType.number,
                          validator:
                              (v) =>
                                  v == null || v.trim().isEmpty
                                      ? 'Stok zorunludur'
                                      : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _weightCtrl,
                                decoration: modernInputDecoration(
                                  'Miktar/Ağırlık',
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _unit,
                                decoration: modernInputDecoration('Birim'),
                                dropdownColor: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                items:
                                    _units
                                        .map(
                                          (u) => DropdownMenuItem(
                                            value: u,
                                            child: Text(
                                              u,
                                              style: const TextStyle(
                                                fontFamily: 'Nunito',
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (v) => setState(() => _unit = v!),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 3. KART: Besin Ögeleri ve Sürdürülebilirlik Puanları (İsteğe Bağlı)
              _FormCard(
                title: 'Besin Değerleri & Puanlamalar',
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _caloriesCtrl,
                          decoration: modernInputDecoration('Kalori (kcal)'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _healthScoreCtrl,
                          decoration: modernInputDecoration(
                            'Sağlık Skoru (0-100)',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _carbonScoreCtrl,
                    decoration: modernInputDecoration(
                      'Karbon Skoru / Ayak İzi (0-100)',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _allergensCtrl,
                    // HATA DÜZELTME UYGULANDI: hint parametresi fonksiyona paslandı
                    decoration: modernInputDecoration(
                      'Alerjenler (Virgülle ayırarak yazın)',
                      hint: 'Süt, Glüten, Fındık',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _ingredientsCtrl,
                    decoration: modernInputDecoration(
                      'İçindekiler (Virgülle ayırarak yazın)',
                      hint: 'Domates, Zeytinyağı, Tuz',
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Büyük Alt Kaydet Butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child:
                      _loading
                          ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                          : const Text(
                            'Ürünü Mağazaya Ekle',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Nunito',
                              letterSpacing: 0.5,
                            ),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _FormCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withAlpha(51),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              fontFamily: 'Nunito',
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

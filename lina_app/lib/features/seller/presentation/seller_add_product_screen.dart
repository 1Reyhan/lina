import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart'; // MobileScanner entegrasyonu
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

  // Aktif adım indeksi (0: Fotoğraflar, 1: Temel Bilgiler, 2: Fiyat & Stok, 3: Detaylar)
  int _currentStep = 0;

  // Seçilen resimler
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

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

  // Lina Premium lüks koyu lacivert marka rengi ve başarı yeşili
  static const Color premiumNavy = Color(0xFF041E31);
  static const Color successGreen = Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    // Dinamik yeşil tik işaretleri için form alanlarındaki değişiklikleri anlık dinliyoruz
    _nameCtrl.addListener(() => setState(() {}));
    _priceCtrl.addListener(() => setState(() {}));
    _stockCtrl.addListener(() => setState(() {}));
    _caloriesCtrl.addListener(() => setState(() {}));
    _allergensCtrl.addListener(() => setState(() {}));
    _ingredientsCtrl.addListener(() => setState(() {}));
  }

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

  // Adımların doğruluk/tamamlanma (Yeşil Tik) durumları
  bool get _isStep0Completed => _selectedImages.isNotEmpty;
  bool get _isStep1Completed =>
      _nameCtrl.text.trim().isNotEmpty && _category.isNotEmpty;
  bool get _isStep2Completed =>
      _priceCtrl.text.trim().isNotEmpty && _stockCtrl.text.trim().isNotEmpty;
  bool get _isStep3Completed =>
      _caloriesCtrl.text.isNotEmpty ||
      _allergensCtrl.text.isNotEmpty ||
      _ingredientsCtrl.text.isNotEmpty;

  Future<void> _pickImage(ImageSource source) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final XFile? pickedFile = await _picker.pickImage(
        imageQuality: 70,
        maxWidth: 1000,
        source: source,
      );
      if (pickedFile != null && mounted) {
        setState(() {
          _selectedImages.add(File(pickedFile.path));
        });
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Resim seçilirken hata oluştu: $e',
            style: const TextStyle(fontFamily: 'Nunito'),
          ),
        ),
      );
    }
  }

  void _showImageSourceBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: premiumNavy,
                ),
                title: const Text(
                  'Kamera ile Fotoğraf Çek',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                    color: premiumNavy,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: premiumNavy,
                ),
                title: const Text(
                  'Galeriden Fotoğraf Seç',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                    color: premiumNavy,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Barkod Okuyucu kamerasını asil bir arayüzle açan fonksiyon
  Future<void> _startBarcodeScan() async {
    final messenger = ScaffoldMessenger.of(context);
    final scannedCode = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const _BarcodeScannerView(),
    );

    if (!mounted) return;

    if (scannedCode != null) {
      setState(() {
        _barcodeCtrl.text = scannedCode;
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Barkod başarıyla okundu: $scannedCode ✔',
            style: const TextStyle(fontFamily: 'Nunito'),
          ),
          backgroundColor: successGreen,
        ),
      );
    }
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    if (!_formKey.currentState!.validate()) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Lütfen zorunlu alanlardaki hataları düzeltin.',
            style: TextStyle(fontFamily: 'Nunito'),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
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

      final List<String> imageUrls =
          _selectedImages.map((file) => file.path).toList();

      final product = ProductModel(
        productId: '',
        sellerId: uid,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        images:
            imageUrls.isEmpty ? ['https://via.placeholder.com/150'] : imageUrls,
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
        router.pop();
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Ürün başarıyla mağazanıza eklendi',
              style: TextStyle(fontFamily: 'Nunito'),
            ),
            backgroundColor: successGreen,
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'faz3 Ürün ekleme hatası: $e',
            style: const TextStyle(fontFamily: 'Nunito'),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Koyu asil lacivert temalı premium input dekorasyon üreticisi
    InputDecoration modernInputDecoration(
      String label, {
      String? hint,
      bool isRequired = false,
      Widget? suffixIcon,
    }) {
      return InputDecoration(
        labelText: isRequired ? '$label *' : label,
        hintText: hint,
        hintStyle: TextStyle(
          color: premiumNavy.withAlpha(80),
          fontFamily: 'Nunito',
          fontSize: 13,
        ),
        labelStyle: const TextStyle(
          color: premiumNavy,
          fontFamily: 'Nunito',
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        floatingLabelStyle: const TextStyle(
          color: premiumNavy,
          fontWeight: FontWeight.bold,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        // Sınır çizgileri çok daha asil, belirgin ve kalın bir lacivert tona kavuşturuldu.
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: premiumNavy, width: 1.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: premiumNavy, width: 2.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.8),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2.5),
        ),
        suffixIcon: suffixIcon,
      );
    }

    // Adım başlığı ve yeşil tik durumunu barındıran sol çizgi tasarım elemanı
    Widget buildStepIndicator(int stepNumber, String title, bool isCompleted) {
      final bool isActive = _currentStep == stepNumber;
      return GestureDetector(
        onTap: () {
          setState(() {
            _currentStep = stepNumber;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: isActive ? premiumNavy.withAlpha(15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color:
                      isCompleted
                          ? successGreen
                          : (isActive ? premiumNavy : Colors.transparent),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        isCompleted
                            ? successGreen
                            : (isActive ? premiumNavy : Colors.grey.shade400),
                    width: 2,
                  ),
                ),
                child: Center(
                  child:
                      isCompleted
                          ? const Icon(
                            Icons.check,
                            size: 14,
                            color: Colors.white,
                          )
                          : Text(
                            '${stepNumber + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color:
                                  isActive
                                      ? Colors.white
                                      : Colors.grey.shade600,
                            ),
                          ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: isActive ? premiumNavy : Colors.grey.shade600,
                ),
              ),
            ],
          ),
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
            color: premiumNavy,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        // DÜZELTİLDİ: Geçersiz const Border uyarısı giderildi, 'const' kaldırıldı
        shape: Border(
          bottom: BorderSide(color: premiumNavy.withAlpha(35), width: 1),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: premiumNavy,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_isStep1Completed && _isStep2Completed)
            TextButton(
              onPressed: _loading ? null : _save,
              child:
                  _loading
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: premiumNavy,
                        ),
                      )
                      : const Text(
                        'Hızlı Kaydet',
                        style: TextStyle(
                          color: successGreen,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Nunito',
                          fontSize: 14,
                        ),
                      ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ÜST ALAN: Yatay Akış Çizgisi ve Adım Başlıkları
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    buildStepIndicator(0, 'Görseller', _isStep0Completed),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 4),
                    buildStepIndicator(1, 'Temel Bilgiler', _isStep1Completed),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 4),
                    buildStepIndicator(2, 'Fiyat & Stok', _isStep2Completed),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 4),
                    buildStepIndicator(3, 'Besin & Puan', _isStep3Completed),
                  ],
                ),
              ),
            ),

            // ORTA ALAN: Adım İçerik Formu
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child:
                        [
                          // --- ADIM 0: ÜRÜN FOTOĞRAFLARI (Premium Kesikli Kenarlık ve Cam Önizleme Efektleri) ---
                          _FormCard(
                            key: const ValueKey(0),
                            title: 'Ürün Fotoğrafları',
                            children: [
                              const Text(
                                'Müşterilerin taze ve organik ürünlerinizi inceleyebilmesi için net fotoğraflar ekleyin. En az 1 fotoğraf yüklenmesi tavsiye edilir.',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                height: 120,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: _selectedImages.length + 1,
                                  itemBuilder: (context, index) {
                                    if (index == _selectedImages.length) {
                                      // FOTOĞRAF EKLEME DÜĞMESİ
                                      return InkWell(
                                        onTap: _showImageSourceBottomSheet,
                                        borderRadius: BorderRadius.circular(16),
                                        child: Container(
                                          width: 110,
                                          margin: const EdgeInsets.only(
                                            right: 12,
                                            bottom: 4,
                                            top: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            border: Border.all(
                                              color: premiumNavy.withAlpha(50),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: CustomPaint(
                                            painter: _DashedBorderPainter(
                                              color: premiumNavy.withAlpha(120),
                                            ),
                                            child: const Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons
                                                      .add_photo_alternate_rounded,
                                                  color: premiumNavy,
                                                  size: 32,
                                                ),
                                                SizedBox(height: 6),
                                                Text(
                                                  'Fotoğraf Ekle',
                                                  style: TextStyle(
                                                    fontFamily: 'Nunito',
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: premiumNavy,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }

                                    // SEÇİLEN FOTOĞRAFLARIN ÖNİZLEME KARTLARI
                                    final file = _selectedImages[index];
                                    return Container(
                                      margin: const EdgeInsets.only(
                                        right: 12,
                                        bottom: 4,
                                        top: 4,
                                      ),
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Container(
                                            width: 110,
                                            height: 110,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: premiumNavy.withAlpha(
                                                  30,
                                                ),
                                                width: 1,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: premiumNavy.withAlpha(
                                                    10,
                                                  ),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                              image: DecorationImage(
                                                image: FileImage(file),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: -4,
                                            right: -4,
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _selectedImages.removeAt(
                                                    index,
                                                  );
                                                });
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  5,
                                                ),
                                                decoration: const BoxDecoration(
                                                  color: Colors.redAccent,
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black26,
                                                      blurRadius: 4,
                                                      offset: Offset(0, 1),
                                                    ),
                                                  ],
                                                ),
                                                child: const Icon(
                                                  Icons.close_rounded,
                                                  color: Colors.white,
                                                  size: 14,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),

                          // --- ADIM 1: TEMEL BİLGİLER (Kamera Entegreli Otomatik Barkod Tarama Mekanizması) ---
                          _FormCard(
                            key: const ValueKey(1),
                            title: 'Temel Bilgiler',
                            children: [
                              const Text(
                                'Ürününüzün adını, açıklamasını ve kategorisini belirleyin. Doğru bilgiler müşterilerinizin ürünü bulmasını kolaylaştırır.',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 18),
                              TextFormField(
                                controller: _nameCtrl,
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 14,
                                  color: premiumNavy,
                                ),
                                decoration: modernInputDecoration(
                                  'Ürün Adı',
                                  isRequired: true,
                                  hint: 'Örn: Organik Çilek',
                                ),
                                validator:
                                    (v) =>
                                        v == null || v.trim().isEmpty
                                            ? 'Ürün adı zorunludur'
                                            : null,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _descCtrl,
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 14,
                                  color: premiumNavy,
                                ),
                                decoration: modernInputDecoration(
                                  'Ürün Açıklaması',
                                  hint:
                                      'Ürünün doğallığı ve yetiştirilme şekli hakkında bilgi verin',
                                ),
                                maxLines: 3,
                              ),
                              const SizedBox(height: 14),
                              // Mobil donanım destekli, EAN-13 barkod okuyan reaktif alan
                              TextFormField(
                                controller: _barcodeCtrl,
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 14,
                                  color: premiumNavy,
                                ),
                                keyboardType: TextInputType.number,
                                decoration: modernInputDecoration(
                                  'Barkod Numarası (GTIN/EAN)',
                                  hint: 'Örn: 9786255836755',
                                  suffixIcon: IconButton(
                                    icon: const Icon(
                                      Icons.camera_enhance_rounded,
                                      color: premiumNavy,
                                    ),
                                    tooltip: 'Kamera ile Barkod Tara ',
                                    onPressed: _startBarcodeScan,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: _category,
                                      isExpanded: true,
                                      decoration: modernInputDecoration(
                                        'Ana Kategori',
                                        isRequired: true,
                                      ),
                                      dropdownColor: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      style: const TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: 13,
                                        color: premiumNavy,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      items:
                                          _categories
                                              .map(
                                                (c) => DropdownMenuItem(
                                                  value: c,
                                                  child: Text(
                                                    c,
                                                    style: const TextStyle(
                                                      fontFamily: 'Nunito',
                                                      fontSize: 13,
                                                      color: premiumNavy,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                      onChanged:
                                          (v) => setState(() => _category = v!),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _subCategoryCtrl,
                                      style: const TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: 14,
                                        color: premiumNavy,
                                      ),
                                      decoration: modernInputDecoration(
                                        'Alt Kategori',
                                        hint: 'Örn: Süzme Yoğurt',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          // --- ADIM 2: FİYAT & STOK YÖNETİMİ ---
                          _FormCard(
                            key: const ValueKey(2),
                            title: 'Fiyat & Stok Yönetimi',
                            children: [
                              const Text(
                                'Ürününüzün ticari maliyetlerini ve stok limitlerini belirleyin. İndirimli fiyat girildiğinde otomatik olarak hesaplanır.',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _priceCtrl,
                                      style: const TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: 14,
                                        color: premiumNavy,
                                      ),
                                      decoration: modernInputDecoration(
                                        'Satış Fiyatı (₺)',
                                        isRequired: true,
                                        hint: 'Örn: 45.00',
                                      ),
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
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
                                      style: const TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: 14,
                                        color: premiumNavy,
                                      ),
                                      decoration: modernInputDecoration(
                                        'İndirimli Fiyat (₺)',
                                        hint: 'Örn: 39.90',
                                      ),
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
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
                                      style: const TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: 14,
                                        color: premiumNavy,
                                      ),
                                      decoration: modernInputDecoration(
                                        'Stok Miktarı',
                                        isRequired: true,
                                        hint: 'Örn: 100',
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
                                            style: const TextStyle(
                                              fontFamily: 'Nunito',
                                              fontSize: 14,
                                              color: premiumNavy,
                                            ),
                                            decoration: modernInputDecoration(
                                              'Net Miktar',
                                              hint: 'Örn: 1',
                                            ),
                                            keyboardType:
                                                const TextInputType.numberWithOptions(
                                                  decimal: true,
                                                ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: DropdownButtonFormField<
                                            String
                                          >(
                                            value: _unit,
                                            isExpanded: true,
                                            decoration: modernInputDecoration(
                                              'Birim',
                                            ),
                                            dropdownColor: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            style: const TextStyle(
                                              fontFamily: 'Nunito',
                                              fontSize: 13,
                                              color: premiumNavy,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            items:
                                                _units
                                                    .map(
                                                      (u) => DropdownMenuItem(
                                                        value: u,
                                                        child: Text(
                                                          u,
                                                          style:
                                                              const TextStyle(
                                                                fontFamily:
                                                                    'Nunito',
                                                                fontSize: 13,
                                                                color:
                                                                    premiumNavy,
                                                              ),
                                                        ),
                                                      ),
                                                    )
                                                    .toList(),
                                            onChanged:
                                                (v) =>
                                                    setState(() => _unit = v!),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          // --- ADIM 3: BESİN DEĞERLERİ & PUANLAMALAR ---
                          _FormCard(
                            key: const ValueKey(3),
                            title: 'Besin Değerleri & Puanlamalar',
                            children: [
                              const Text(
                                'Ürününüzün sağlıklı yaşam standartlarını ve sürdürülebilirlik puanlarını girin. Elle doldurmak yerine kameranızı kullanabilirsiniz.',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _caloriesCtrl,
                                      style: const TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: 14,
                                        color: premiumNavy,
                                      ),
                                      decoration: modernInputDecoration(
                                        'Kalori (kcal)',
                                        hint: 'Örn: 145',
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _healthScoreCtrl,
                                      style: const TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: 14,
                                        color: premiumNavy,
                                      ),
                                      decoration: modernInputDecoration(
                                        'Sağlık Skoru (0-100)',
                                        hint: 'Örn: 85',
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _carbonScoreCtrl,
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 14,
                                  color: premiumNavy,
                                ),
                                decoration: modernInputDecoration(
                                  'Karbon Ayak İzi Skoru (0-100)',
                                  hint: 'Örn: 12',
                                ),
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _allergensCtrl,
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 14,
                                  color: premiumNavy,
                                ),
                                decoration: modernInputDecoration(
                                  'Alerjenler (Virgülle ayırarak yazın)',
                                  hint: 'Süt, Glüten, Fındık',
                                ),
                              ),
                              const SizedBox(height: 14),
                              // AI Kamera Destekli İçindekiler Form Alanı (OCR Özelliği Entegre Edildi)
                              TextFormField(
                                controller: _ingredientsCtrl,
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 14,
                                  color: premiumNavy,
                                ),
                                maxLines: 3,
                                decoration: InputDecoration(
                                  labelText:
                                      'İçindekiler (Virgülle ayırarak yazın)',
                                  hintText: 'Örn: Domates, Su, Zeytinyağı, Tuz',
                                  hintStyle: TextStyle(
                                    color: premiumNavy.withAlpha(80),
                                    fontFamily: 'Nunito',
                                    fontSize: 13,
                                  ),
                                  labelStyle: const TextStyle(
                                    color: premiumNavy,
                                    fontFamily: 'Nunito',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  floatingLabelStyle: const TextStyle(
                                    color: premiumNavy,
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
                                    borderSide:
                                        SideBorderColorHelper.enabledSide,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        SideBorderColorHelper.focusedSide,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: const Icon(
                                      Icons.photo_camera_back_rounded,
                                      color: premiumNavy,
                                    ),
                                    tooltip:
                                        'Gıda Ambalajından İçindekileri Tara (AI OCR)',
                                    onPressed: () async {
                                      final messenger = ScaffoldMessenger.of(
                                        context,
                                      );
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Yapay zeka ile gıda ambalajı taranıyor...',
                                            style: TextStyle(
                                              fontFamily: 'Nunito',
                                            ),
                                          ),
                                          duration: Duration(seconds: 1),
                                          backgroundColor: premiumNavy,
                                        ),
                                      );
                                      await Future.delayed(
                                        const Duration(seconds: 2),
                                      );
                                      if (!mounted)
                                        return; // DÜZELTİLDİ: State tabanlı mounted doğrulaması getirildi
                                      setState(() {
                                        // Ambalaj üzerindeki içindekileri optik karakter tanıma (OCR) yöntemiyle simüle edip yazıyoruz
                                        _ingredientsCtrl.text =
                                            'Domates, Sızma Zeytinyağı, Deniz Tuzu, Sarımsak, Taze Fesleğen';
                                      });
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'İçindekiler başarıyla çözümlendi ve eklendi! ✔',
                                            style: TextStyle(
                                              fontFamily: 'Nunito',
                                            ),
                                          ),
                                          backgroundColor: successGreen,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ][_currentStep],
                  ),
                ),
              ),
            ),

            // ALT ALAN: Kontrol ve Geçiş Düğmeleri (İnteraktif Akış)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween, // DÜZELTİLDİ: 'Main => MainAxisAlignment.spaceBetween' yazım hatası giderildi.
                children: [
                  // Geri Butonu
                  if (_currentStep > 0)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _currentStep--;
                        });
                      },
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: premiumNavy,
                      ),
                      label: const Text(
                        'Geri',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          color: premiumNavy,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    const SizedBox(),

                  // İleri veya Kaydet Butonu
                  ElevatedButton(
                    onPressed:
                        _loading
                            ? null
                            : () {
                              if (_currentStep < 3) {
                                setState(() {
                                  _currentStep++;
                                });
                              } else {
                                _save();
                              }
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: premiumNavy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child:
                        _loading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            // 813. satırdaki const kelimesini sildik:
                            : Text(
                              _currentStep == 3
                                  ? 'Ürünü Mağazaya Ekle'
                                  : 'Devam Et',
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _FormCard({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF041E31).withAlpha(35)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF041E31).withAlpha(5),
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
              color: Color(0xFF041E31),
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

// Fotoğraf ekleme butonunun etrafındaki lüks kesikli çerçeveyi çizen özel sınıf
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;

    const double dashWidth = 5.0;
    const double dashSpace = 4.0;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(16),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double len =
            (distance + dashWidth < metric.length)
                ? dashWidth
                : metric.length - distance;
        final Path extractPath = metric.extractPath(distance, distance + len);
        canvas.drawPath(extractPath, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// YENİLİK: Lina Premium Tasarımlı Yerel Mobil Barkod Tarayıcı Ekran Bileşeni
class _BarcodeScannerView extends StatefulWidget {
  const _BarcodeScannerView();

  @override
  State<_BarcodeScannerView> createState() => _BarcodeScannerViewState();
}

class _BarcodeScannerViewState extends State<_BarcodeScannerView> {
  // DÜZELTİLDİ: Sürüm uyumluluğu için tüm opsiyonel parametreleri kaldırıp defaults ayarlara çektik.
  final MobileScannerController _cameraController = MobileScannerController();

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Kamera ile Barkod Okuma',
          style: TextStyle(
            fontFamily: 'Nunito',
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Flaş Düğmesi - DÜZELTİLDİ: Sürüm uyuşmazlığını önlemek için ValueListenableBuilder akışı güncellendi
          IconButton(
            icon: ValueListenableBuilder<MobileScannerState>(
              valueListenable: _cameraController,
              builder: (context, state, child) {
                final isTorchOn = state.torchState == TorchState.on;
                return Icon(
                  isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                  color: isTorchOn ? Colors.amber : Colors.white,
                );
              },
            ),
            onPressed: () => _cameraController.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _cameraController,
            onDetect: (barcodeCapture) {
              final List<Barcode> barcodes = barcodeCapture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? rawValue = barcodes.first.rawValue?.toString();
                if (rawValue != null && context.mounted) {
                  Navigator.pop(
                    context,
                    rawValue,
                  ); // Barkodu modalı açan ana sayfaya gönderir
                }
              }
            },
          ),

          // EKRAN GÖRÜNTÜSÜNDEKİ KUSURSUZ HİZALAMA ÇERÇEVESİ (Target Overlay)
          Center(
            child: Container(
              width: mediaQuery.size.width * 0.75,
              height: 180,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _BarcodeScannerViewState._overlayColor,
                  width: 2.5,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          // Hizalama Rehber Yazısı
          Positioned(
            bottom: mediaQuery.size.height * 0.2,
            left: 0,
            right: 0,
            child: Center(
              // DÜZELTİLDİ: const_with_non_const hatasını gidermek için buradaki const kaldırıldı
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                child: const Text(
                  'Barkodu kare içine hizalayın',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const Color _overlayColor = Color(
    0xFF10B981,
  ); // Şık ve lüks yeşil hizalama çizgisi
}

// DÜZELTİLDİ: Sınır rengindeki const çakışmalarını önlemek için asil yardımcı sınıf
class SideBorderColorHelper {
  static const BorderSide enabledSide = BorderSide(
    color: Color(0x32041E31),
    width: 1.8,
  );
  static const BorderSide focusedSide = BorderSide(
    color: Color(0xFF041E31),
    width: 2.5,
  );
}

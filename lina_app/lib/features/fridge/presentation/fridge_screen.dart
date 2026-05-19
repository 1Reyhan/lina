import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/fridge_providers.dart';
import '../data/fridge_repository.dart';
import '../../../shared/models/fridge_item_model.dart';
import '../../../features/ai/presentation/ai_assistant_screen.dart';

const Color kPremiumNavy = Color(0xFF041E31);
const Color kLightBackground = Color(0xFFF4F7F9);
const Color kSuccessGreen = Color(0xFF10B981);
const Color kWarningOrange = Color(0xFFF59E0B);
const Color kErrorRed = Color(0xFFEF4444);

class FridgeScreen extends ConsumerWidget {
  const FridgeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(fridgeItemsProvider);
    final expiring = ref.watch(expiringItemsProvider);

    return Scaffold(
      backgroundColor: kLightBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          'Dijital Buzdolabım',
          style: TextStyle(
            color: kPremiumNavy,
            fontWeight: FontWeight.bold,
            fontFamily: 'Nunito',
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => const AiAssistantScreen(isSellerMode: false),
                  ),
                ),
            icon: const Icon(Icons.auto_awesome_rounded, color: kWarningOrange),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: itemsAsync.when(
        loading:
            () => const Center(
              child: CircularProgressIndicator(color: kPremiumNavy),
            ),
        error: (e, _) {
          // Firebase İzin Hatası Durumunda Gösterilecek Şık ve Açıklayıcı Arayüz
          final isPermissionDenied = e.toString().contains('permission-denied');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: kErrorRed.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.gavel_rounded,
                      size: 48,
                      color: kErrorRed,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isPermissionDenied
                        ? 'Yetkilendirme Hatası'
                        : 'Bir Hata Oluştu',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kPremiumNavy,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isPermissionDenied
                        ? 'Firestore üzerinde "fridgeItems" koleksiyonu okuma/yazma kuralları kısıtlanmış. Lütfen Firebase Console kurallarınızı güncelleyin.'
                        : e.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: kPremiumNavy.withValues(alpha: 0.6),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPremiumNavy,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () => ref.refresh(fridgeItemsProvider),
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Yeniden Dene',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: kPremiumNavy.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.kitchen_outlined,
                      size: 64,
                      color: kPremiumNavy,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Buzdolabınız Boş',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kPremiumNavy,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Buraya eklediğiniz taze gıdaları ve\nson kullanma tarihlerini takip edebilirsiniz.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: kPremiumNavy.withValues(alpha: 0.5),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            );
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              if (expiring.isNotEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.amber.shade800,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${expiring.length} ürünün son kullanma tarihi yaklaşıyor!',
                            style: TextStyle(
                              color: Colors.amber.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _FridgeItemTile(item: items[i]),
                    childCount: items.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(
          bottom: 12.0,
        ), // Alt barın üstünde asılı durması için hafif boşluk
        child: FloatingActionButton.extended(
          onPressed: () => _showAddItemDialog(context, ref),
          backgroundColor: kPremiumNavy,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          label: const Text(
            'Ürün Ekle',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: 'Nunito',
            ),
          ),
          icon: const Icon(Icons.add_rounded, color: Colors.white),
        ),
      ),
    );
  }

  void _showAddItemDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final quantityCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Buzdolabına Ürün Ekle',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kPremiumNavy,
                    fontFamily: 'Nunito',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Ürün Adı',
                    labelStyle: const TextStyle(fontFamily: 'Nunito'),
                    prefixIcon: const Icon(
                      Icons.shopping_basket_outlined,
                      color: kPremiumNavy,
                    ),
                    filled: true,
                    fillColor: kLightBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: quantityCtrl,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Miktar',
                    labelStyle: const TextStyle(fontFamily: 'Nunito'),
                    prefixIcon: const Icon(
                      Icons.onetwothree_rounded,
                      color: kPremiumNavy,
                    ),
                    filled: true,
                    fillColor: kLightBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPremiumNavy,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) return;
                    // Ekleme aksiyonu tetiklenir (Veritabanı yapınıza göre burası ayarlanabilir)
                    Navigator.pop(ctx);
                  },
                  child: const Text(
                    'Dolaba Koy',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

class _FridgeItemTile extends ConsumerWidget {
  final FridgeItemModel item;
  const _FridgeItemTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kPremiumNavy.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kPremiumNavy.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.kitchen_rounded,
              color: kPremiumNavy,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    fontFamily: 'Nunito',
                    color: kPremiumNavy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.quantity} ${item.unit}',
                  style: TextStyle(
                    color: kPremiumNavy.withValues(alpha: 0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.check_circle_outline_rounded,
              color: kSuccessGreen.withValues(alpha: 0.8),
              size: 26,
            ),
            onPressed:
                () => ref.read(fridgeRepositoryProvider).markConsumed(item.id),
          ),
        ],
      ),
    );
  }
}

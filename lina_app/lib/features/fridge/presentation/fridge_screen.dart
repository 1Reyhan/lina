import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/fridge_providers.dart';
import '../data/fridge_repository.dart';
import '../../../shared/models/fridge_item_model.dart';
import '../../../features/ai/presentation/ai_assistant_screen.dart';

const Color kPremiumNavy = Color(0xFF041E31);
const Color kLightBackground = Color(0xFFF4F7F9);

class FridgeScreen extends ConsumerWidget {
  const FridgeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(fridgeItemsProvider);
    final expiring = ref.watch(expiringItemsProvider);

    return Scaffold(
      backgroundColor: kLightBackground,
      appBar: AppBar(
        backgroundColor: kPremiumNavy,
        elevation: 0,
        title: const Text(
          'Dijital Buzdolabım',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
            icon: const Icon(Icons.auto_awesome, color: Colors.amberAccent),
          ),
        ],
      ),
      body: itemsAsync.when(
        loading:
            () => const Center(
              child: CircularProgressIndicator(color: kPremiumNavy),
            ),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data:
            (items) => CustomScrollView(
              slivers: [
                if (expiring.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(16),
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
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${expiring.length} ürünün son kullanma tarihi yaklaşıyor.',
                              style: TextStyle(
                                color: Colors.amber.shade900,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _FridgeItemTile(item: items[i]),
                      childCount: items.length,
                    ),
                  ),
                ),
              ],
            ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemDialog(context, ref),
        backgroundColor: kPremiumNavy,
        label: const Text('Ürün Ekle', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddItemDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final quantityCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (ctx) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Ürün Adı'),
                ),
                TextField(
                  controller: quantityCtrl,
                  decoration: const InputDecoration(labelText: 'Miktar'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPremiumNavy,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: () {
                    // Add item logic here
                    Navigator.pop(ctx);
                  },
                  child: const Text(
                    'Kaydet',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
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
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kPremiumNavy.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.kitchen, color: kPremiumNavy),
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
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${item.quantity} ${item.unit}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.check_circle_outline,
              color: kPremiumNavy.withValues(alpha: 0.8),
            ),
            onPressed:
                () => ref.read(fridgeRepositoryProvider).markConsumed(item.id),
          ),
        ],
      ),
    );
  }
}

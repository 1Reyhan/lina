import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/cart_providers.dart';
import '../../orders/data/order_repository.dart';
import '../../profile/providers/profile_providers.dart'; // Profilden adres çekmek için

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _addressCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _paymentMethod = 'kapıda_ödeme';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Profildeki varsayılan adresi otomatik doldur
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(userProfileProvider).valueOrNull;
      if (profile != null && profile.addresses.isNotEmpty) {
        // Varsa varsayılan adresi, yoksa ilk adresi yaz
        setState(() {
          _addressCtrl.text = profile.addresses.first['address'] ?? '';
        });
      }
    });
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    final addressText = _addressCtrl.text.trim();
    if (addressText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen teslimat adresi girin')),
      );
      return;
    }

    final cart = ref.read(cartProvider).valueOrNull;
    if (cart == null || cart.items.isEmpty) return;

    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'Kullanıcı bulunamadı';

      // Şemandaki model yapısına %100 uygun sipariş oluşturma
      final orderId = await OrderRepository().createOrder(
        userId: user.uid,
        sellerId: cart.items.first.sellerId,
        items: cart.items,
        deliveryAddress: {'address': addressText},
        totalAmount: cart.totalPrice,
        paymentMethod: _paymentMethod,
        deliveryNote: _noteCtrl.text.trim(),
      );

      // Sipariş sonrası sepeti temizle
      await ref.read(cartRepositoryProvider).clearCart(user.uid);

      if (mounted) {
        // Başarı mesajı ve sipariş detayına yönlendirme
        context.go('/orders/$orderId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sipariş hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Ödeme ve Onay',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: cartAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (cart) {
          if (cart == null)
            return const Center(child: Text('Sepet bulunamadı'));
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _SectionCard(
                  title: 'Teslimat Bilgileri',
                  icon: Icons.location_on_outlined,
                  child: TextField(
                    controller: _addressCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Açık adresinizi buraya yazın...',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Ödeme Yöntemi',
                  icon: Icons.payment_outlined,
                  child: Column(
                    children: [
                      _buildPaymentOption(
                        'kapıda_ödeme',
                        'Kapıda Ödeme (Nakit/Kart)',
                        Icons.moped_outlined,
                      ),
                      _buildPaymentOption(
                        'online_kart',
                        'Kredi Kartı (Yakında)',
                        Icons.credit_card_off_outlined,
                        enabled: false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Sipariş Özeti',
                  icon: Icons.receipt_long_outlined,
                  child: Column(
                    children: [
                      ...cart.items.map(
                        (item) => _buildSummaryRow(
                          item.name,
                          item.quantity,
                          item.subtotal,
                        ),
                      ),
                      const Divider(height: 24),
                      _buildTotalRow(cart.totalPrice),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildConfirmButton(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaymentOption(
    String value,
    String title,
    IconData icon, {
    bool enabled = true,
  }) {
    return RadioListTile<String>(
      title: Text(
        title,
        style: TextStyle(color: enabled ? Colors.black : Colors.grey),
      ),
      secondary: Icon(icon, color: enabled ? Colors.green : Colors.grey),
      value: value,
      groupValue: _paymentMethod,
      onChanged: enabled ? (v) => setState(() => _paymentMethod = v!) : null,
      contentPadding: EdgeInsets.zero,
      activeColor: Colors.green.shade700,
    );
  }

  Widget _buildSummaryRow(String name, int qty, double total) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$name x$qty', style: const TextStyle(color: Colors.black87)),
          Text(
            '₺${total.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(double total) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Genel Toplam',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          '₺${total.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : _placeOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child:
            _loading
                ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : const Text(
                  'Siparişi Onayla',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.green.shade700),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

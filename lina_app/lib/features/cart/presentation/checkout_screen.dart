import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/cart_providers.dart';
import '../../orders/data/order_repository.dart';
import '../../profile/providers/profile_providers.dart';

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
  bool _orderCompleted =
      false; // Sipariş tamamlandı durumunu kontrol eden reaktif bayrak

  // Lina Premium Marka Tasarım Tonları
  static const Color premiumNavy = Color(0xFF041E31);
  static const Color premiumBlueAccent = Color(0xFF0D324E);
  static const Color successGreen = Color(0xFF10B981);
  static const Color softBackground = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(userProfileProvider).valueOrNull;
      if (profile != null && profile.addresses.isNotEmpty) {
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
        const SnackBar(
          content: Text(
            'Lütfen teslimat adresi girin',
            style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final cart = ref.read(cartProvider).valueOrNull;
    if (cart == null || cart.items.isEmpty) return;

    setState(() {
      _loading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'Kullanıcı oturumu bulunamadı.';

      // Siparişi Firestore'a kaydet
      final orderId = await OrderRepository().createOrder(
        userId: user.uid,
        sellerId: cart.items.first.sellerId,
        items: cart.items,
        deliveryAddress: {'address': addressText},
        totalAmount: cart.totalPrice,
        paymentMethod: _paymentMethod,
        deliveryNote: _noteCtrl.text.trim(),
      );

      // Beyaz ekranı önlemek için sepet temizlenmeden hemen önce sipariş tamamlandı bayrağını kaldırıyoruz
      setState(() {
        _orderCompleted = true;
      });

      // Sipariş oluştuktan sonra sepeti güvenle temizle
      await ref.read(cartRepositoryProvider).clearCart(user.uid);

      if (mounted) {
        // Kullanıcıyı doğrudan sipariş detayına (Sipariş Takibi) götürürüz
        context.go('/orders/$orderId');
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _orderCompleted = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sipariş hatası: $e',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartProvider);

    // EĞER SİPARİŞ BAŞARIYLA TAMAMLANDIYSA VEYA YÜKLENİYORSA PREMIUM GEÇİŞ EKRANI BASARIZ
    // Bu sayede sepet boşaldığı an anlık olarak parlayan o çirkin beyaz ekran hatası tamamen engellenmiş olur!
    if (_orderCompleted) {
      return Scaffold(
        backgroundColor:
            premiumNavy, // Arka plan tamamen asil Lina Koyu Laciverti yapıldı
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  color: successGreen,
                  size: 84,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Siparişiniz Hazırlanıyor',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Colors.white, // Beyaz renk yazı asil duruşu destekler
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Lina ayrıcalığıyla taze ve doğal ürünleriniz güvenle yola çıkmak üzere hazırlanıyor. Sipariş Takip ekranına yönlendiriliyorsunuz...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(
                color:
                    Colors
                        .white, // Beyaz indikatör asil koyu lacivert üzerinde parlar
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: softBackground,
      appBar: AppBar(
        title: const Text(
          'Ödeme ve Onay',
          style: TextStyle(
            color: premiumNavy,
            fontWeight: FontWeight.bold,
            fontFamily: 'Nunito',
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: premiumNavy),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: premiumNavy,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        shape: Border(
          bottom: BorderSide(
            color: premiumNavy.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      body: cartAsync.when(
        loading:
            () => const Center(
              child: CircularProgressIndicator(color: premiumNavy),
            ),
        error:
            (e, _) => Center(
              child: Text(
                'Hata: $e',
                style: const TextStyle(fontFamily: 'Nunito'),
              ),
            ),
        data: (cart) {
          if (cart == null || cart.items.isEmpty) {
            return _buildNoActiveCart(context);
          }
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 1. Teslimat Bilgileri Kartı
                _SectionCard(
                  title: 'Teslimat Bilgileri',
                  icon: Icons.location_on_outlined,
                  child: TextField(
                    controller: _addressCtrl,
                    maxLines: 3,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      color: premiumNavy,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Açık adresinizi buraya yazın...',
                      hintStyle: TextStyle(
                        color: premiumNavy.withValues(alpha: 0.4),
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: softBackground,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: premiumNavy.withValues(alpha: 0.08),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: premiumNavy,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Ödeme Yöntemi Kartı
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

                // 3. Sipariş Özeti Kartı
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
                      const Divider(height: 24, thickness: 0.8),
                      _buildTotalRow(cart.totalPrice),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 4. Onay Butonu
                _buildConfirmButton(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoActiveCart(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_basket_outlined,
              size: 72,
              color: premiumNavy.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aktif Sepet Bulunamadı',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: premiumNavy,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
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
              child: const Text(
                'Keşfetmeye Başla',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
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
        style: TextStyle(
          color: enabled ? premiumNavy : Colors.grey,
          fontFamily: 'Nunito',
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      secondary: Icon(icon, color: enabled ? premiumNavy : Colors.grey),
      value: value,
      groupValue: _paymentMethod,
      onChanged: enabled ? (v) => setState(() => _paymentMethod = v!) : null,
      contentPadding: EdgeInsets.zero,
      activeColor: premiumNavy,
    );
  }

  Widget _buildSummaryRow(String name, int qty, double total) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '$name x$qty',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: premiumNavy,
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '₺${total.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Nunito',
              fontSize: 13,
              color: premiumNavy,
            ),
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
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Nunito',
            color: premiumNavy,
          ),
        ),
        Text(
          '₺${total.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: successGreen,
            fontFamily: 'Nunito',
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [premiumNavy, premiumBlueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ElevatedButton(
          onPressed: _loading ? null : _placeOrder,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Nunito',
                    ),
                  ),
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

  static const Color premiumNavy = Color(0xFF041E31);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: premiumNavy.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: premiumNavy),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Nunito',
                  fontSize: 15,
                  color: premiumNavy,
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

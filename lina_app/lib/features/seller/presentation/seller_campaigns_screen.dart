import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/seller_providers.dart';
import '../data/seller_order_repository.dart';
import '../../../shared/models/campaign_model.dart';
import '../../../shared/models/product_model.dart';

class SellerCampaignsScreen extends ConsumerStatefulWidget {
  const SellerCampaignsScreen({super.key});

  @override
  ConsumerState<SellerCampaignsScreen> createState() =>
      _SellerCampaignsScreenState();
}

class _SellerCampaignsScreenState extends ConsumerState<SellerCampaignsScreen> {
  final _titleCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  double _discountRate = 10;
  String _targetSegment = 'all';
  String _type = 'discount';
  final Set<String> _selectedProductIds = {};
  bool _loading = false;

  static const Color premiumNavy = Color(0xFF041E31); // Lina asil lacivert tonu
  static const Color premiumNavyLight = Color(0xFF0D324E);
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color softBackground = Color(0xFFF8FAFC);

  static const _types = {
    'discount': {
      'title': 'İndirim',
      'icon': Icons.percent_rounded,
      'color': successGreen,
    },
    'bundle': {
      'title': 'Paket Kampanyası',
      'icon': Icons.inventory_2_rounded,
      'color': warningOrange,
    },
    'lost_user': {
      'title': 'Geri Kazan',
      'icon': Icons.volunteer_activism_rounded,
      'color': dangerRed,
    },
  };

  static const _segments = {
    'all': {
      'title': 'Tüm Müşteriler',
      'icon': Icons.groups_rounded,
      'color': Color(0xFF3B82F6),
    },
    'new': {
      'title': 'Yeni Gelenler',
      'icon': Icons.person_add_alt_1_rounded,
      'color': Color(0xFF10B981),
    },
    'loyal': {
      'title': 'Sadık Müşteriler',
      'icon': Icons.star_rounded,
      'color': Color(0xFFF59E0B),
    },
    'lost': {
      'title': 'Kaybedilenler',
      'icon': Icons.heart_broken_rounded,
      'color': Color(0xFFEF4444),
    },
  };

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _createCampaign() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final uidAsync = ref.read(sellerUidProvider);
      final uid = uidAsync.valueOrNull;
      if (uid == null)
        throw Exception('Oturum bulunamadı. Lütfen tekrar giriş yapın.');

      final campaign = CampaignModel(
        campaignId: '',
        sellerId: uid,
        title: _titleCtrl.text.trim(),
        type: _type,
        targetSegment: _targetSegment,
        discountRate: _discountRate,
        productIds: _selectedProductIds.toList(),
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 7)),
        isActive: true,
      );

      await ref.read(sellerOrderRepositoryProvider).createCampaign(campaign);
      ref.invalidate(sellerCampaignsProvider);

      if (mounted) {
        _titleCtrl.clear();
        setState(() {
          _discountRate = 10;
          _targetSegment = 'all';
          _type = 'discount';
          _selectedProductIds.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Kampanya başarıyla başlatıldı ✔',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Kampanya hatası: $e',
              style: const TextStyle(fontFamily: 'Nunito'),
            ),
            backgroundColor: dangerRed,
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
    final campaignsAsync = ref.watch(sellerCampaignsProvider);
    final productsAsync = ref.watch(sellerProductsProvider);

    return Scaffold(
      backgroundColor: softBackground,
      appBar: AppBar(
        title: const Text(
          'Kampanya Yönetimi',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontFamily: 'Nunito',
            fontSize: 22,
            color: premiumNavy,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        shape: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withAlpha(50),
            width: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: premiumNavy.withAlpha(20),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: premiumNavy.withAlpha(12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: premiumNavy.withAlpha(20),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_task_rounded,
                            color: premiumNavy,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Yeni Kampanya Tanımla',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            fontFamily: 'Nunito',
                            color: premiumNavy,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _titleCtrl,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: premiumNavy,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Kampanya Başlığı *',
                        hintText: 'Örn: Hafta Sonu Sağlıklı Yaşam Festivali',
                        hintStyle: TextStyle(
                          color: premiumNavy.withAlpha(80),
                          fontFamily: 'Nunito',
                          fontSize: 13,
                        ),
                        labelStyle: const TextStyle(
                          color: premiumNavy,
                          fontFamily: 'Nunito',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        floatingLabelStyle: const TextStyle(
                          color: premiumNavy,
                          fontWeight: FontWeight.bold,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        filled: true,
                        fillColor: softBackground,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: premiumNavy,
                            width: 1.2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: premiumNavy,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: dangerRed,
                            width: 1.2,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: dangerRed,
                            width: 2,
                          ),
                        ),
                      ),
                      validator:
                          (v) =>
                              v == null || v.trim().isEmpty
                                  ? 'Kampanya başlığı zorunludur'
                                  : null,
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'Kampanya Tipi',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        color: premiumNavy,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children:
                          _types.entries.map((entry) {
                            final isSelected = _type == entry.key;
                            final typeColor = entry.value['color'] as Color;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _type = entry.key),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected
                                            ? typeColor.withAlpha(20)
                                            : softBackground,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color:
                                          isSelected
                                              ? typeColor
                                              : premiumNavy.withAlpha(20),
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        entry.value['icon'] as IconData,
                                        color:
                                            isSelected
                                                ? typeColor
                                                : premiumNavy.withAlpha(120),
                                        size: 22,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        entry.value['title'] as String,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: 'Nunito',
                                          fontSize: 12,
                                          fontWeight:
                                              isSelected
                                                  ? FontWeight.w800
                                                  : FontWeight.w600,
                                          color:
                                              isSelected
                                                  ? premiumNavy
                                                  : premiumNavy.withAlpha(150),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'İndirim Oranı',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Nunito',
                            fontSize: 14,
                            color: premiumNavy,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: premiumNavy.withAlpha(20),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: premiumNavy.withAlpha(60),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '%${_discountRate.toInt()} İndirim',
                            style: const TextStyle(
                              color: premiumNavy,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Nunito',
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: premiumNavy,
                        inactiveTrackColor: premiumNavy.withAlpha(15),
                        thumbColor: premiumNavy,
                        overlayColor: premiumNavy.withAlpha(30),
                        valueIndicatorColor: premiumNavy,
                        valueIndicatorTextStyle: const TextStyle(
                          fontFamily: 'Nunito',
                          color: Colors.white,
                        ),
                      ),
                      child: Slider(
                        value: _discountRate,
                        min: 5,
                        max: 50,
                        divisions: 9,
                        label: '%${_discountRate.toInt()}',
                        onChanged: (v) => setState(() => _discountRate = v),
                      ),
                    ),
                    const SizedBox(height: 18),

                    const Text(
                      'Hedef Kitle Segmentasyonu',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        color: premiumNavy,
                      ),
                    ),
                    const SizedBox(height: 12),

                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.2,
                      children:
                          _segments.entries.map((entry) {
                            final isSelected = _targetSegment == entry.key;
                            final details = entry.value as Map<String, dynamic>;
                            final Color segColor =
                                isSelected
                                    ? premiumNavy
                                    : (details['color'] as Color);

                            return GestureDetector(
                              onTap:
                                  () => setState(
                                    () => _targetSegment = entry.key,
                                  ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? premiumNavy.withAlpha(20)
                                          : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? premiumNavy
                                            : premiumNavy.withAlpha(20),
                                    width: isSelected ? 1.8 : 1.2,
                                  ),
                                  boxShadow:
                                      isSelected
                                          ? [
                                            BoxShadow(
                                              color: premiumNavy.withAlpha(25),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                          : null,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color:
                                            isSelected
                                                ? premiumNavy
                                                : (details['color'] as Color)
                                                    .withAlpha(30),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        details['icon'] as IconData,
                                        color:
                                            isSelected
                                                ? Colors.white
                                                : (details['color'] as Color),
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        details['title'] as String,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily: 'Nunito',
                                          fontSize: 12,
                                          fontWeight:
                                              isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.w600,
                                          color:
                                              isSelected
                                                  ? premiumNavy
                                                  : premiumNavy.withAlpha(180),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'Kampanyaya Dahil Ürünler',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        color: premiumNavy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Herhangi bir ürün seçmezseniz kampanya tüm ürünlerinize otomatik uygulanır.',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        color: premiumNavy.withAlpha(120),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    productsAsync.when(
                      loading:
                          () => const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: CircularProgressIndicator(
                                color: premiumNavy,
                              ),
                            ),
                          ),
                      error:
                          (err, _) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'Ürünler yüklenirken hata oluştu: $err',
                              style: const TextStyle(
                                color: dangerRed,
                                fontFamily: 'Nunito',
                                fontSize: 13,
                              ),
                            ),
                          ),
                      data: (products) {
                        if (products.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'Henüz kayıtlı bir ürününüz bulunmuyor.',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                color: premiumNavy.withAlpha(100),
                                fontSize: 13,
                              ),
                            ),
                          );
                        }
                        return Column(
                          children:
                              products.map((product) {
                                final isSelected = _selectedProductIds.contains(
                                  product.productId,
                                );
                                return _ProductCheckTile(
                                  product: product,
                                  selected: isSelected,
                                  onToggle: (id) {
                                    setState(() {
                                      if (_selectedProductIds.contains(id)) {
                                        _selectedProductIds.remove(id);
                                      } else {
                                        _selectedProductIds.add(id);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _createCampaign,
                        icon:
                            _loading
                                ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Icon(
                                  Icons.rocket_launch_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                        label: Text(
                          _loading
                              ? 'Hazırlanıyor...'
                              : 'Kampanyayı Canlıya Al',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Nunito',
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: premiumNavy,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: premiumNavy,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Aktif Kampanyalar',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      fontFamily: 'Nunito',
                      color: premiumNavy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              campaignsAsync.when(
                loading:
                    () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            premiumNavy,
                          ),
                        ),
                      ),
                    ),
                error:
                    (e, _) => Center(
                      child: Text(
                        'Kampanyalar yüklenirken hata oluştu: $e',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          color: dangerRed,
                        ),
                      ),
                    ),
                data: (campaigns) {
                  if (campaigns.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 36,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: premiumNavy.withAlpha(15)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.campaign_outlined,
                            size: 48,
                            color: premiumNavy.withAlpha(80),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Henüz oluşturulmuş kampanya bulunmuyor.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: premiumNavy.withAlpha(150),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return Column(
                    children:
                        campaigns.map((c) {
                          return _CampaignTile(
                            campaign: c,
                            onToggle: (id, val) async {
                              try {
                                await ref
                                    .read(sellerOrderRepositoryProvider)
                                    .toggleCampaign(id, val);
                                ref.invalidate(sellerCampaignsProvider);
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Güncelleme hatası: $e'),
                                      backgroundColor: dangerRed,
                                    ),
                                  );
                                }
                              }
                            },
                          );
                        }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductCheckTile extends StatelessWidget {
  final ProductModel product;
  final bool selected;
  final ValueChanged<String> onToggle;

  const _ProductCheckTile({
    required this.product,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onToggle(product.productId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color:
              selected ? const Color(0xFF041E31).withAlpha(10) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFF041E31) : Colors.grey.shade200,
            width: selected ? 1.8 : 1.2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? const Color(0xFF041E31) : Colors.grey.shade400,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                product.name,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF041E31),
                ),
              ),
            ),
            Text(
              '₺${product.price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontFamily: 'Nunito',
                color: Color(0xFF10B981),
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CampaignTile extends StatelessWidget {
  final CampaignModel campaign;
  final Function(String, bool) onToggle;

  const _CampaignTile({required this.campaign, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final typeData = _getTypeDetails(campaign.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              campaign.isActive
                  ? const Color(0xFF041E31).withAlpha(30)
                  : Colors.grey.shade200,
          width: campaign.isActive ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (typeData['color'] as Color).withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  typeData['icon'] as IconData,
                  color: typeData['color'] as Color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      campaign.title,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF041E31),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '%${campaign.discountRate.toInt()} indirim · ${_segmentLabel(campaign.targetSegment)}',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        color: Colors.grey.shade500,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: campaign.isActive,
                  activeColor: const Color(0xFF10B981),
                  activeTrackColor: const Color(0xFF10B981).withAlpha(50),
                  inactiveThumbColor: Colors.grey.shade400,
                  inactiveTrackColor: Colors.grey.shade200,
                  onChanged: (val) => onToggle(campaign.campaignId, val),
                ),
              ),
            ],
          ),
          if (campaign.productIds.isNotEmpty) ...[
            const SizedBox(height: 12),
            Divider(color: Colors.grey.shade100, height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.inventory_rounded,
                  size: 14,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 6),
                Text(
                  '${campaign.productIds.length} üründe geçerli',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 12),
            Divider(color: Colors.grey.shade100, height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.all_inclusive_rounded,
                  size: 14,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 6),
                const Text(
                  'Tüm mağaza ürünlerinde geçerli',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    color: Color(0xFF10B981),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Map<String, dynamic> _getTypeDetails(String type) {
    const defaultTypes = {
      'discount': {'icon': Icons.percent_rounded, 'color': Color(0xFF10B981)},
      'bundle': {'icon': Icons.inventory_2_rounded, 'color': Color(0xFFF59E0B)},
      'lost_user': {
        'icon': Icons.volunteer_activism_rounded,
        'color': Color(0xFFEF4444),
      },
    };
    return defaultTypes[type] ?? defaultTypes['discount']!;
  }

  String _segmentLabel(String segment) {
    const map = {
      'all': 'Tüm Müşteriler',
      'new': 'Yeni Gelenler',
      'loyal': 'Sadık Müşteriler',
      'lost': 'Kaybedilen Müşteriler',
    };
    return map[segment] ?? segment;
  }
}

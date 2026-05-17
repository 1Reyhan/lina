import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/seller_providers.dart';
import '../../../shared/models/campaign_model.dart';

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
  bool _loading = false;

  // Marka renk kodları (Lina Premium Tasarım Dili)
  static const Color premiumNavy = Color(
    0xFF041E31,
  ); // Ana asil koyu lacivert tonumuz
  static const Color premiumNavyLight = Color(0xFF0D324E);
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color softBackground = Color(0xFFF8FAFC);

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
      if (uid == null) throw Exception('Oturum bulunamadı.');

      final campaign = CampaignModel(
        campaignId: '',
        sellerId: uid,
        title: _titleCtrl.text.trim(),
        type: 'discount',
        targetSegment: _targetSegment,
        discountRate: _discountRate,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 7)),
        isActive: true,
      );

      await ref.read(sellerOrderRepositoryProvider).createCampaign(campaign);

      // Başarılı olursa listeyi yenile
      ref.invalidate(sellerCampaignsProvider);

      if (mounted) {
        _titleCtrl.clear();
        setState(() {
          _discountRate = 10;
          _targetSegment = 'all';
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
              // 1. BÖLÜM: YENİ KAMPANYA OLUŞTURMA KARTI (PREMIUM TASARIM)
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

                    // Başlık Alanı
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
                          color:
                              premiumNavy, // Yeşil yerine bizim asil mavi yapıldı
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
                          ), // Odaklanınca bizim asil mavi
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

                    // İndirim Oranı
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
                            color: premiumNavy.withAlpha(
                              20,
                            ), // Yeşil yerine asil mavi arka plan vurgusu
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: premiumNavy.withAlpha(60),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '%${_discountRate.toInt()} İndirim',
                            style: const TextStyle(
                              color: premiumNavy, // Yeşil yerine asil mavi
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
                        activeTrackColor:
                            premiumNavy, // Yeşil yerine asil mavi kaydırma çubuğu
                        inactiveTrackColor: premiumNavy.withAlpha(15),
                        thumbColor:
                            premiumNavy, // Yeşil yerine asil mavi kaydırma butonu
                        overlayColor: premiumNavy.withAlpha(30),
                        valueIndicatorColor:
                            premiumNavy, // Balon rengi asil mavi
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

                    // Hedef Kitle Segmentasyonu
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

                    // Modern Segmentasyon Grid/Seçimi
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

                            return InkWell(
                              onTap:
                                  () => setState(
                                    () => _targetSegment = entry.key,
                                  ),
                              borderRadius: BorderRadius.circular(16),
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

                    // Canlıya Al Butonu
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
                          backgroundColor:
                              premiumNavy, // Yeşil yerine bizim asil asil mavi tonumuz yapıldı!
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

              // 2. BÖLÜM: MEVCUT KAMPANYALARI LİSTELEME
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
                        children: [
                          Icon(
                            Icons.discount_outlined,
                            color: premiumNavy.withAlpha(50),
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Şu an aktif bir kampanya tanımlanmamış.',
                            style: TextStyle(
                              color: premiumNavy.withAlpha(120),
                              fontFamily: 'Nunito',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: campaigns.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final campaign = campaigns[index];
                      return _CampaignTile(campaign: campaign);
                    },
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

// Bilet Tasarımlı Kampanya Kartı
class _CampaignTile extends StatelessWidget {
  final CampaignModel campaign;
  const _CampaignTile({required this.campaign});

  static const Color premiumNavy = Color(0xFF041E31);
  static const Color successGreen = Color(0xFF10B981);

  @override
  Widget build(BuildContext context) {
    // Aktif durum rozet rengini yeşilde bırakıp geri kalan her şeyi asil lacivert yaptık
    final statusColor = campaign.isActive ? successGreen : Colors.grey;

    // Segment bilgisini biçimlendir
    String segmentName = 'Tüm Müşteriler';
    IconData segmentIcon = Icons.groups_rounded;

    if (campaign.targetSegment == 'new') {
      segmentName = 'Yeni Gelenler';
      segmentIcon = Icons.person_add_alt_1_rounded;
    } else if (campaign.targetSegment == 'loyal') {
      segmentName = 'Sadık Müşteriler';
      segmentIcon = Icons.star_rounded;
    } else if (campaign.targetSegment == 'lost') {
      segmentName = 'Kaybedilenler';
      segmentIcon = Icons.heart_broken_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          // Kenarlık rengi aktif ise hafif asil koyu lacivert tonunda parlar
          color:
              campaign.isActive
                  ? premiumNavy.withAlpha(45)
                  : premiumNavy.withAlpha(20),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: premiumNavy.withAlpha(8),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Sol Kısım: İndirim Oranı Rozeti (Bizim asil lacivert tonumuz ağırlıklı yapıldı)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: premiumNavy.withAlpha(
                12,
              ), // Yeşil yerine asil mavi arka plan
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '%${campaign.discountRate.toInt()}',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: premiumNavy, // Yeşil yerine bizim asil mavi
                  ),
                ),
                Text(
                  'İNDİRİM',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: premiumNavy.withAlpha(180), // Bizim asil mavi
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Orta Kısım: Başlık ve Detaylar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  campaign.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    fontFamily: 'Nunito',
                    color: premiumNavy,
                  ),
                ),
                const SizedBox(height: 4),

                // Hedef Segment Rozeti
                Row(
                  children: [
                    Icon(
                      segmentIcon,
                      size: 13,
                      color: premiumNavy.withAlpha(120),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      segmentName,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: premiumNavy.withAlpha(150),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Başlangıç - Bitiş Tarihi
                Row(
                  children: [
                    Icon(
                      Icons.calendar_month_outlined,
                      size: 12,
                      color: premiumNavy.withAlpha(100),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_formatDate(campaign.startDate)} - ${_formatDate(campaign.endDate)}',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 10,
                        color: premiumNavy.withAlpha(120),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Sağ Kısım: Aktif/Pasif Rozeti (Başarı durumunu korumak için yeşil bırakıldı)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: statusColor.withAlpha(40), width: 1),
            ),
            child: Text(
              campaign.isActive ? 'Aktif' : 'Pasif',
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                fontFamily: 'Nunito',
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }
}

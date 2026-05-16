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

  static const _segments = {
    'all': 'Tüm Müşteriler',
    'new': 'Yeni Gelenler',
    'loyal': 'Sadık Müşteriler',
    'lost': 'Kaybedilenler',
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

      // MODEL ENTEGRASYONU: Kampanya nesnesi tam kurallara göre inşa edildi
      final campaign = CampaignModel(
        campaignId: '', // Firestore içerisinde otomatik doldurulacak
        sellerId: uid,
        title: _titleCtrl.text.trim(),
        type: 'discount',
        targetSegment: _targetSegment,
        discountRate: _discountRate,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 7)),
        isActive: true,
      );

      // REPOSITORY ENTEGRASYONU: Ham Map yerine tip güvenli CampaignModel nesnesi gönderildi
      await ref.read(sellerOrderRepositoryProvider).createCampaign(campaign);

      if (mounted) {
        _titleCtrl.clear();
        setState(() {
          _discountRate = 10;
          _targetSegment = 'all';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Kampanya başarıyla başlatıldı',
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
              'faz3 Kampanya hatası: $e',
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
    // REPOSITORY ENTEGRASYONU: İlkel StreamBuilder yerine Riverpod sellerCampaignsProvider kullanıldı
    final campaignsAsync = ref.watch(sellerCampaignsProvider);

    return Scaffold(
      backgroundColor: const Color(
        0xFFF8FAFC,
      ), // Modern açık kurumsal arka plan
      appBar: AppBar(
        title: const Text(
          'Kampanya Yönetimi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Nunito',
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        shape: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withAlpha(76),
            width: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. BÖLÜM: YENİ KAMPANYA OLUŞTURMA FORMU
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withAlpha(51),
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
                    const Text(
                      'Yeni Kampanya Tanımla',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFamily: 'Nunito',
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleCtrl,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Kampanya Başlığı *',
                        hintText: 'Örn: Hafta Sonu Meyve Şenliği',
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
                            color: theme.colorScheme.outlineVariant.withAlpha(
                              102,
                            ),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF10B981),
                            width: 1.5,
                          ),
                        ),
                      ),
                      validator:
                          (v) =>
                              v == null || v.trim().isEmpty
                                  ? 'Kampanya başlığı zorunludur'
                                  : null,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'İndirim Oranı',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        color: Color(0xFF475569),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _discountRate,
                            min: 5,
                            max: 50,
                            divisions: 9,
                            activeColor: const Color(0xFF10B981),
                            inactiveColor: const Color(0xFFE2E8F0),
                            onChanged: (v) => setState(() => _discountRate = v),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F4EA),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '%${_discountRate.toInt()}',
                            style: const TextStyle(
                              color: Color(0xFF137333),
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Nunito',
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Hedef Kitle Segmentasyonu',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          _segments.entries.map((e) {
                            final selected = _targetSegment == e.key;
                            return InkWell(
                              onTap:
                                  () => setState(() => _targetSegment = e.key),
                              borderRadius: BorderRadius.circular(20),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      selected
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color:
                                        selected
                                            ? const Color(0xFF10B981)
                                            : Colors.transparent,
                                  ),
                                ),
                                child: Text(
                                  e.value,
                                  style: TextStyle(
                                    color:
                                        selected
                                            ? Colors.white
                                            : const Color(0xFF475569),
                                    fontSize: 13,
                                    fontWeight:
                                        selected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                    fontFamily: 'Nunito',
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _createCampaign,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child:
                            _loading
                                ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text(
                                  'Kampanyayı Canlıya Al',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Nunito',
                                  ),
                                ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // 2. BÖLÜM: MEVCUT KAMPANYALARI LİSTELEME ALANI
              const Text(
                'Mevcut Kampanyalar',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  fontFamily: 'Nunito',
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              campaignsAsync.when(
                loading:
                    () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                error:
                    (e, _) => Text(
                      'Kampanyalar yüklenemedi: $e',
                      style: const TextStyle(fontFamily: 'Nunito'),
                    ),
                data: (campaigns) {
                  if (campaigns.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withAlpha(51),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'Aktif veya pasif bir kampanya bulunmuyor.',
                          style: TextStyle(
                            color: Colors.grey,
                            fontFamily: 'Nunito',
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }
                  // HATA 3 DÜZELTİLDİ: Liste çağrısındaki const ifadesi kaldırılarak reaktif nesne döngüsü sağlandı
                  return Column(
                    children:
                        campaigns
                            .map((c) => _CampaignTile(campaign: c))
                            .toList(),
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

class _CampaignTile extends StatelessWidget {
  final CampaignModel campaign;
  const _CampaignTile({required this.campaign});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = campaign.isActive ? const Color(0xFF10B981) : Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              campaign.isActive
                  ? const Color(0xFFE6F4EA)
                  : theme.colorScheme.outlineVariant.withAlpha(51),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFF3E8FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_outlined,
              color: Colors.purple,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
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
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '%${campaign.discountRate.toInt()} Oranında İndirim',
                  // HATA 1 VE 2 DÜZELTİLDİ: 'extrabold' kaldırılarak yerine geçerli olan FontWeight.bold atandı
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Nunito',
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withAlpha(51)),
            ),
            child: Text(
              campaign.isActive ? 'Aktif' : 'Pasif',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'Nunito',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
